import json
import os
import time
from datetime import datetime
import threading

import firebase_admin
from firebase_admin import credentials, db, messaging
from flask import Flask, render_template
from flask_mqtt import Mqtt
from flask_socketio import SocketIO

# ============================== Configuration ==============================
STORAGE_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "storage")
if not os.path.exists(STORAGE_DIR):
    os.makedirs(STORAGE_DIR)

# ============================== Firebase Setup ==============================
current_dir = os.path.dirname(os.path.abspath(__file__))
parent_dir = os.path.dirname(current_dir)
service_account_path = os.path.join(parent_dir, "config", "serviceAccountKey.json")

cred = credentials.Certificate(service_account_path)
firebase_admin.initialize_app(
    cred, {"databaseURL": "https://noderedfirebase-769cf-default-rtdb.firebaseio.com/"}
)
firebase_ref = db.reference("/Data")

# ============================== Flask App Setup ==============================
app = Flask(__name__)
app.config["MQTT_BROKER_URL"] = "localhost"
app.config["MQTT_BROKER_PORT"] = 1883
app.config["MQTT_USERNAME"] = ""
app.config["MQTT_PASSWORD"] = ""
app.config["MQTT_REFRESH_TIME"] = 1.0

mqtt = Mqtt(app)
mqtt.init_app(app)
socketio = SocketIO(app)


# ============================== Managers ==============================
class MessageBatchManager:
    def __init__(self):
        self.current_batch = []
        self.last_message_time = None
        self.BATCH_TIMEOUT = 5.0
        self.batch_counter = 0
        self.processed_batches = set()

    def add_message(self, data):
        current_time = datetime.now()

        if (
            self.last_message_time is None
            or (current_time - self.last_message_time).total_seconds()
            > self.BATCH_TIMEOUT
        ):
            self.batch_counter += 1
            self.current_batch = []
            print(f"\nStarting new batch #{self.batch_counter}")

        batch_data = data.copy()
        batch_data["batch_id"] = self.batch_counter
        self.current_batch.append(batch_data)
        self.last_message_time = current_time

        print(
            f"Added message to batch #{self.batch_counter}. Batch size: {len(self.current_batch)}"
        )
        return self.batch_counter

    def get_earliest_from_batch(self, batch_id):
        if batch_id in self.processed_batches:
            print(f"Batch #{batch_id} already processed, skipping")
            return None

        batch_messages = [
            msg for msg in self.current_batch if msg["batch_id"] == batch_id
        ]
        if not batch_messages:
            return None

        message = batch_messages[0]
        message.pop("batch_id", None)
        self.processed_batches.add(batch_id)
        self.current_batch = []

        return message


class StorageManager:
    def __init__(self, storage_dir, firebase_ref):
        self.storage_dir = storage_dir
        self.cache_file = os.path.join(self.storage_dir, "cache_failed.txt")
        self.ref = firebase_ref

    def save_data(self, data):
        print(f"save_data called! Will write to: {self.cache_file}")
        try:
            with open(self.cache_file, "a") as f:
                json_data = json.dumps(data) + "\n"
                f.write(json_data)
            print(f"Data saved to storage: {self.cache_file}")
        except Exception as e:
            print(f"Error saving to storage: {e}")

    def send_to_firebase(self, data):
        try:
            current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S.%f")
            print(f"Processing data for Firebase: {data}")

            if not isinstance(data, dict):
                print("Invalid data format - expected dictionary")
                return False

            for server_id, server_info in data.items():
                if not server_id.startswith("SERVER_"):
                    continue

                server_info["timeline"] = current_time
                try:
                    server_ref = self.ref.child(server_id)
                    now_data = dict(server_info)
                    monitor_data = dict(server_info)

                    server_ref.child("Now").update(now_data)
                    print(f"Updated Now for {server_id}")
                    server_ref.child("Monitor").push(monitor_data)
                    print(f"Pushed to Monitor for {server_id}")

                except Exception as e:
                    print(f"Error updating server {server_id}: {str(e)}")

            try:
                latest_list = {
                    str(i): server_id for i, server_id in enumerate(data.keys())
                }
                self.ref.parent.child("LatestList").set(latest_list)
                print(f"Updated LatestList: {latest_list}")
            except Exception as e:
                print(f"Error updating LatestList: {str(e)}")

            return True

        except Exception as e:
            print(f"Error in send_to_firebase: {str(e)}")
            self.save_data(data)
            return False

    def try_send_stored_data(self):
        if not os.path.exists(self.cache_file):
            return
        try:
            with open(self.cache_file, "r") as f:
                lines = f.readlines()
            if not lines:
                return
            all_sent = True
            for line in lines:
                data = json.loads(line.strip())
                if not self.send_to_firebase(data):
                    all_sent = False
                    print(f"Failed to send some data from {self.cache_file}, keeping file")
                    break
            if all_sent:
                self.clear_cache_file()
                print(f"Successfully sent all data from {self.cache_file}")
        except Exception as e:
            print(f"Error processing file {self.cache_file}: {e}")

    def clear_cache_file(self):
        try:
            open(self.cache_file, 'w').close()
            print(f"Cleared file: {self.cache_file}")
        except Exception as e:
            print(f"Error clearing file {self.cache_file}: {e}")


# ============================== Global Instances ==============================
storage_manager = StorageManager(STORAGE_DIR, firebase_ref)
batch_manager = MessageBatchManager()


# ============================== MQTT Event Handlers ==============================
@mqtt.on_connect()
def handle_connect(client, userdata, flags, rc):
    if rc == 0:
        print("Connected successfully")
        mqtt.subscribe("Send Data")
    else:
        print("Bad connection. Code:", rc)


@mqtt.on_message()
def handle_mqtt_message(client, userdata, message):
    try:
        payload = json.loads(message.payload.decode())
        print(f"Received payload: {json.dumps(payload, indent=2)}")

        formatted_data = {}
        if isinstance(payload, dict):
            for client_key, client_value in payload.items():
                if client_key.startswith("CLIENT_") and isinstance(client_value, dict):
                    for server_key, server_data in client_value.items():
                        if server_key.startswith("SERVER_") and isinstance(
                            server_data, dict
                        ):
                            formatted_data[server_key] = server_data

        if formatted_data:
            batch_id = batch_manager.add_message(formatted_data)
            socketio.sleep(0.1)
            earliest_data = batch_manager.get_earliest_from_batch(batch_id)

            if earliest_data:
                print(f"Processing earliest message from batch #{batch_id}")
                if not storage_manager.send_to_firebase(earliest_data):
                    storage_manager.save_data(earliest_data)
                    storage_manager.try_send_stored_data()
                socketio.emit("mqtt_message", data=earliest_data)
        else:
            print("No valid server data found in payload")

    except json.JSONDecodeError as e:
        print(f"Error decoding JSON payload: {e}")
    except Exception as e:
        print(f"Error processing message: {e}")


# ============================== Routes ==============================
@app.route("/")
def index():
    return render_template("index.html")


@app.route("/batches")
def view_batches():
    return {
        "current_batch_id": batch_manager.batch_counter,
        "current_batch_size": len(batch_manager.current_batch),
        "last_message_time": (
            batch_manager.last_message_time.strftime("%Y-%m-%d %H:%M:%S.%f")
            if batch_manager.last_message_time
            else None
        ),
    }


# ============================== Firebase Push Notification ==============================
def sendNotificationWithToken(title, msg, registration_token, dataObject=None):
    message = messaging.MulticastMessage(
        notification=messaging.Notification(title=title, body=msg),
        data=dataObject,
        tokens=registration_token,
    )
    response = messaging.send_each_for_multicast(message)
    print("Successfully sent message:", response)


def sendNotificationWithTopic(title, msg, dataObject=None):
    message = messaging.Message(
        notification=messaging.Notification(title=title, body=msg),
        data=dataObject,
        topic="all",
    )

    response = messaging.send(message)
    print("Successfully sent message:", response)


def poll_client_control():
    last_value = None
    while True:
        try:
            # Get the current value of /ClientControl
            ref = db.reference("/ClientControl")
            value = ref.get()
            if value != last_value:
                print("Detected change in /ClientControl, publishing to MQTT...")
                mqtt.publish("Receive-Data", json.dumps(value))
                last_value = value
        except Exception as e:
            print(f"Error polling /ClientControl: {e}")
        time.sleep(2)  # Poll every 2 seconds


# ============================== Main ==============================
if __name__ == "__main__":
    # Start the polling thread before running the app
    polling_thread = threading.Thread(target=poll_client_control, daemon=True)
    polling_thread.start()

    tokens = [
        "c-4Ps3BXSs2Hc2OKUZX5hN:APA91bH1LfYXLTrPsaXyybxaqOjwSpLw1iNmxX9WCJt-vBa6gLuoXRH0xahu1nCEVbG-wCJCRe81V8Giuedpra0Lh-NlkzO6tdrn8Rc9IIFI5H9glNaBHwc"
    ]
    # sendNotificationWithToken("Hi", "This is my next msg", tokens)
    # sendNotificationWithTopic("Hi", "This is my next topic msg")
    socketio.run(app, host="0.0.0.0", port=5000, use_reloader=False, debug=False)