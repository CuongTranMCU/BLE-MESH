from flask import Flask, render_template  
from flask_mqtt import Mqtt 
from flask_socketio import SocketIO
import firebase_admin
from firebase_admin import credentials, db
from datetime import datetime
import os
import json
import time

# Storage configuration
STORAGE_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'storage')
if not os.path.exists(STORAGE_DIR):
    os.makedirs(STORAGE_DIR)

class MessageBatchManager:
    def __init__(self):
        self.current_batch = []
        self.last_message_time = None
        self.BATCH_TIMEOUT = 5.0  # 5 second to consider as same batch
        self.batch_counter = 0  # To track different batches
        self.processed_batches = set()  # Keep track of processed batches

    def add_message(self, data):
        current_time = datetime.now()
        
        # If this is the first message or we've exceeded batch timeout
        if (self.last_message_time is None or 
            (current_time - self.last_message_time).total_seconds() > self.BATCH_TIMEOUT):
            # Start new batch
            self.batch_counter += 1
            self.current_batch = []
            print(f"\nStarting new batch #{self.batch_counter}")
        
        batch_data = data.copy()  # Create a copy to avoid modifying original data
        batch_data['batch_id'] = self.batch_counter
        self.current_batch.append(batch_data)
        self.last_message_time = current_time
        
        print(f"Added message to batch #{self.batch_counter}. Batch size: {len(self.current_batch)}")
        return self.batch_counter

    def get_earliest_from_batch(self, batch_id):
        # If we've already processed this batch, return None
        if batch_id in self.processed_batches:
            print(f"Batch #{batch_id} already processed, skipping")
            return None
            
        batch_messages = [msg for msg in self.current_batch if msg['batch_id'] == batch_id]
        if not batch_messages:
            return None
        
        # Just get the first message from the batch
        message = batch_messages[0]
        
        # Remove batch_id before returning
        if 'batch_id' in message:
            del message['batch_id']
            
        # Mark batch as processed
        self.processed_batches.add(batch_id)
        self.current_batch = []
        
        return message
    
class StorageManager:
    def __init__(self, storage_dir,firebase_ref):
        self.storage_dir = storage_dir
        self.current_file = None
        self.current_size = 0
        self.MAX_FILE_SIZE = 1 * 1024 * 1024  # 1MB per file
        self.ref = firebase_ref  # Store the Firebase reference

    def save_data(self, data):
        if self.current_file is None or self.current_size >= self.MAX_FILE_SIZE:
            self.create_new_file()

        try:
            with open(self.current_file, 'a') as f:
                json_data = json.dumps(data) + '\n'
                f.write(json_data)
                self.current_size += len(json_data.encode())
            print(f"Data saved to storage: {self.current_file}")
        except Exception as e:
            print(f"Error saving to storage: {e}")

    def create_new_file(self):
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        self.current_file = os.path.join(self.storage_dir, f'cache_{timestamp}.txt')
        self.current_size = 0
        print(f"Created new storage file: {self.current_file}")

    def send_to_firebase(self, data):
        """Send data to Firebase with Monitor and Now fields"""
        try:
            current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S.%f")
            print(f"Processing data for Firebase: {data}")  # Debug print
            
            if not isinstance(data, dict):
                print("Invalid data format - expected dictionary")
                return False

            # Process each server in the data
            for server_id, server_info in data.items():
                if not server_id.startswith('SERVER_'):
                    continue
                
                # Add Timeline to server info
                server_info['Timeline'] = current_time
                
                try:
                    # Get reference to server node
                    server_ref = self.ref.child(server_id)
                    
                    # Update Now field
                    now_data = dict(server_info)  # Create a copy of the data
                    server_ref.child('Now').update(now_data)
                    print(f"Updated Now for {server_id}")
                    
                    # Push to Monitor
                    monitor_data = dict(server_info)  # Create a copy of the data
                    server_ref.child('Monitor').push(monitor_data)
                    print(f"Pushed to Monitor for {server_id}")
                    
                except Exception as e:
                    print(f"Error updating server {server_id}: {str(e)}")
                    continue

            # Update LatestList
            try:
                latest_list = {
                    str(i): server_id 
                    for i, server_id in enumerate(data.keys())
                }
                self.ref.parent.child('LatestList').set(latest_list)
                print(f"Updated LatestList: {latest_list}")
            except Exception as e:
                print(f"Error updating LatestList: {str(e)}")

            return True

        except Exception as e:
            print(f"Error in send_to_firebase: {str(e)}")
            return False
        
    def try_send_stored_data(self):
        """Try to send stored data to Firebase"""
        for filename in os.listdir(self.storage_dir):
            if filename.startswith('cache_') and filename.endswith('.txt'):
                filepath = os.path.join(self.storage_dir, filename)
                try:
                    with open(filepath, 'r') as f:
                        lines = f.readlines()
                    
                    all_sent = True
                    for line in lines:
                        data = json.loads(line.strip())
                        if not self.send_to_firebase(data):
                            all_sent = False
                            print(f"Failed to send some data from {filename}, keeping file")
                            break
                    
                    # If all data was sent successfully, remove the file
                    if all_sent:
                        self.remove_file(filepath)
                        print(f"Successfully sent all data from {filename}")
                    
                except Exception as e:
                    print(f"Error processing file {filename}: {e}")

    def get_pending_data(self):
        """Get all pending data from storage files"""
        pending_data = []
        for filename in os.listdir(self.storage_dir):
            if filename.startswith('cache_') and filename.endswith('.txt'):
                file_path = os.path.join(self.storage_dir, filename)
                try:
                    with open(file_path, 'r') as f:
                        for line in f:
                            pending_data.append(json.loads(line.strip()))
                except Exception as e:
                    print(f"Error reading file {filename}: {e}")
        return pending_data

    def remove_file(self, filepath):
        """Remove a storage file"""
        try:
            os.remove(filepath)
            print(f"Removed file: {filepath}")
        except Exception as e:
            print(f"Error removing file {filepath}: {e}")


# Get the current directory path
current_dir = os.path.dirname(os.path.abspath(__file__))
parent_dir = os.path.dirname(current_dir)
# Construct path to service account file
service_account_path = os.path.join(parent_dir, 'config', 'serviceAccountKey.json')
# Initialize Firebase Admin SDK
cred = credentials.Certificate(service_account_path)
firebase_admin.initialize_app(cred, {
    'databaseURL': 'https://noderedfirebase-769cf-default-rtdb.firebaseio.com/'
})
# Create Firebase reference
firebase_ref = db.reference('/Data')
# Initialize storage manager with Firebase reference
storage_manager = StorageManager(STORAGE_DIR, firebase_ref)
batch_manager = MessageBatchManager()

app = Flask(__name__) 
app.config['MQTT_BROKER_URL'] = 'mqtt.flespi.io' 
app.config['MQTT_BROKER_PORT'] = 1883
app.config['MQTT_USERNAME'] = 'PF9jGotho8aZAzOTCfakydyzf3zU8xnlDBtgDPqOPPmmHIeWIIIn6xvFUh1Ax04i'
app.config['MQTT_PASSWORD'] = 'PF9jGotho8aZAzOTCfakydyzf3zU8xnlDBtgDPqOPPmmHIeWIIIn6xvFUh1Ax04i'
app.config['MQTT_REFRESH_TIME'] = 1.0  # refresh time in seconds 
mqtt = Mqtt(app) 
socketio = SocketIO(app)
@mqtt.on_connect() 
def handle_connect(client, userdata, flags, rc): 
    mqtt.subscribe('data-sub') 
@mqtt.on_message() 
def handle_mqtt_message(client, userdata, message):
    try:
        # Parse JSON payload
        payload = json.loads(message.payload.decode())
        print(f"Received payload: {json.dumps(payload, indent=2)}")  # Debugging

        formatted_data = {}

        # Check if payload is a dictionary
        if isinstance(payload, dict):
            for client_key, client_value in payload.items():
                if client_key.startswith('CLIENT_') and isinstance(client_value, dict):
                    for server_key, server_data in client_value.items():
                        if server_key.startswith('SERVER_') and isinstance(server_data, dict):
                            formatted_data[server_key] = server_data  # Extract Server Data

        # Check if we successfully extracted data
        if formatted_data:
            batch_id = batch_manager.add_message(formatted_data)
            socketio.sleep(0.1)
            earliest_data = batch_manager.get_earliest_from_batch(batch_id)

            if earliest_data:
                print(f"Processing earliest message from batch #{batch_id}")

                # Try to send to Firebase
                if not storage_manager.send_to_firebase(earliest_data):
                    storage_manager.save_data(earliest_data)
                    storage_manager.try_send_stored_data()

                # Emit via socket.io
                socketio.emit('mqtt_message', data=earliest_data)
        else:
            print("No valid server data found in payload")

    except json.JSONDecodeError as e:
        print(f"Error decoding JSON payload: {e}")
    except Exception as e:
        print(f"Error processing message: {e}")
# Add a route to view current batch status
@app.route('/batches')
def view_batches():
    return {
        'current_batch_id': batch_manager.batch_counter,
        'current_batch_size': len(batch_manager.current_batch),
        'last_message_time': batch_manager.last_message_time.strftime("%Y-%m-%d %H:%M:%S.%f") 
            if batch_manager.last_message_time else None
    }

@app.route('/') 
def index(): 
    return render_template('index.html') 
if __name__ == '__main__':

    socketio.run(app, host='0.0.0.0', port=5000, use_reloader=False, debug=False)