#include "mqtt.h"

static const char *TAG = "MQTTS_EXAMPLE";

static esp_mqtt_client_handle_t global_client;
static mqtt_data_pt_t mqtt_data_pt = NULL;

static void log_error_if_nonzero(const char *message, int error_code)
{
    if (error_code != 0)
    {
        ESP_LOGE(TAG, "Last error %s: 0x%x", message, error_code);
    }
}

static void mqtt_event_handler(void *handler_args, esp_event_base_t base, int32_t event_id, void *event_data)
{
    ESP_LOGD(TAG, "Event dispatched from event loop base=%s, event_id=%ld", base, event_id);
    esp_mqtt_event_handle_t event = event_data;
    esp_mqtt_client_handle_t client = event->client;
    int msg_id;
    switch ((esp_mqtt_event_id_t)event_id)
    {
    case MQTT_EVENT_CONNECTED:
        ESP_LOGI(TAG, "MQTT_EVENT_CONNECTED");
        msg_id = esp_mqtt_client_subscribe(client, "ReceiveControl", 0);
        ESP_LOGI(TAG, "sent subscribe successful, msg_id=%d", msg_id);
        break;

    case MQTT_EVENT_DISCONNECTED:
        ESP_LOGI(TAG, "MQTT_EVENT_DISCONNECTED");
        break;

    case MQTT_EVENT_SUBSCRIBED:
        ESP_LOGI(TAG, "MQTT_EVENT_SUBSCRIBED, msg_id=%d", event->msg_id);
        break;

    case MQTT_EVENT_UNSUBSCRIBED:
        ESP_LOGI(TAG, "MQTT_EVENT_UNSUBSCRIBED, msg_id=%d", event->msg_id);
        break;

    case MQTT_EVENT_PUBLISHED:
        ESP_LOGI(TAG, "MQTT_EVENT_PUBLISHED, msg_id=%d", event->msg_id);
        break;

    case MQTT_EVENT_DATA:
        ESP_LOGI(TAG, "MQTT_EVENT_DATA");
        printf("TOPIC=%.*s\r\n", event->topic_len, event->topic);
        printf("DATA=%.*s\r\n", event->data_len, event->data);
        event->data[event->data_len] = '\0';
        mqtt_data_pt(event->data, event->data_len);
        break;

    case MQTT_EVENT_ERROR:
        ESP_LOGI(TAG, "MQTT_EVENT_ERROR");
        if (event->error_handle->error_type == MQTT_ERROR_TYPE_TCP_TRANSPORT)
        {
            log_error_if_nonzero("reported from esp-tls", event->error_handle->esp_tls_last_esp_err);
            log_error_if_nonzero("reported from tls stack", event->error_handle->esp_tls_stack_err);
            log_error_if_nonzero("captured as transport's socket errno", event->error_handle->esp_transport_sock_errno);
            ESP_LOGI(TAG, "Last errno string (%s)", strerror(event->error_handle->esp_transport_sock_errno));
        }
        break;
    default:
        ESP_LOGI(TAG, "Other event id:%d", event->event_id);
        break;
    }
}

void mqtt_app_start(const char *uri, uint32_t port, const char *username, const char *password)
{
    // esp_mqtt_client_config_t mqtt_cfg = {
    //     .broker.address.uri = uri,
    //     .broker.address.port = port,
    //     .credentials.username = username,
    //     .credentials.authentication.password = password,
    //     //  .broker.verification.skip_cert_common_name_check = true,
    // };

    esp_mqtt_client_config_t mqtt_cfg = {
        .broker.address.uri = "mqtt://192.168.1.11",
        .broker.address.port = 1883,
    };

    ESP_LOGI(TAG, "[APP] Free memory: %ld bytes", esp_get_free_heap_size());
    global_client = esp_mqtt_client_init(&mqtt_cfg);
    if (global_client == NULL)
    {
        ESP_LOGE(TAG, "Failed to initialize MQTT client");
        return;
    }
    /* The last argument may be used to pass data to the event handler, in this example mqtt_event_handler */
    esp_mqtt_client_register_event(global_client, ESP_EVENT_ANY_ID, mqtt_event_handler, NULL);
    esp_mqtt_client_start(global_client);
}

void mqtt_app_stop(void)
{
    if (global_client != NULL)
    {
        esp_err_t err = esp_mqtt_client_stop(global_client);
        if (err != ESP_OK)
        {
            ESP_LOGE(TAG, "Failed to stop MQTT client: %s", esp_err_to_name(err));
        }
    }
}

esp_mqtt_client_handle_t mqtt_get_global_client(void)
{
    return global_client;
}

void mqtt_data_pt_set_callback(void *cb)
{
    if (cb)
    {
        mqtt_data_pt = cb;
    }
}

void mqtt_data_publish_callback(char *topic, char *data, int length)
{
    esp_mqtt_client_handle_t client = mqtt_get_global_client();

    int msg_id = esp_mqtt_client_publish(client, topic, data, length, 0, 0);
    if (msg_id >= 0)
    {
        ESP_LOGI(TAG, "Sent publish successful, msg_id=%d", msg_id);
    }
    else
    {
        ESP_LOGE(TAG, "Failed to publish message");
    }
}

cJSON *convert_model_sensor_to_json(model_sensor_data_t *received_data)
{

    // create a nested JSON object for the device
    cJSON *device_data = cJSON_CreateObject();
    if (device_data == NULL)
    {
        printf("Error: Failed to create nested JSON object.\n");
        return NULL;
    }

    char mesh_addr_str[7];
    snprintf(mesh_addr_str, sizeof(mesh_addr_str), "0x%04X", received_data->mesh_addr);

    char mac_addr[15] = "0x";
    strcat(mac_addr, received_data->mac_addr);

    // add sensor data to the nested object
    cJSON_AddStringToObject(device_data, "macAddress", mac_addr);
    cJSON_AddStringToObject(device_data, "meshAddress", mesh_addr_str);
    cJSON_AddNumberToObject(device_data, "rssi", received_data->rssi);
    cJSON_AddNumberToObject(device_data, "humidity", received_data->humidity);
    cJSON_AddNumberToObject(device_data, "temperature", received_data->temperature);
    cJSON_AddNumberToObject(device_data, "smoke", received_data->smoke);
    cJSON_AddStringToObject(device_data, "feedback", received_data->feedback);

    return device_data;
}

cJSON *convert_model_control_to_json(model_control_data_t *received_data)
{
    if (received_data == NULL)
    {
        printf("Error: received_data is NULL.\n");
        return NULL;
    }

    // Tạo object chính để chứa key là mesh_addr_str
    cJSON *root = cJSON_CreateObject();
    if (root == NULL)
    {
        printf("Error: Failed to create JSON root object.\n");
        return NULL;
    }

    // Chuyển mesh address sang chuỗi dạng "0x1234"
    char mesh_addr_str[7];
    snprintf(mesh_addr_str, sizeof(mesh_addr_str), "0x%04X", received_data->mesh_addr);

    // Tạo object chứa led và buzzer
    cJSON *json = cJSON_CreateObject();
    if (json == NULL)
    {
        printf("Error: Failed to create device_data object.\n");
        cJSON_Delete(root);
        return NULL;
    }
    cJSON_AddStringToObject(json, "MeshAddress", mesh_addr_str);
    cJSON_AddNumberToObject(json, "led", received_data->led);
    cJSON_AddNumberToObject(json, "buzzer", received_data->buzzer);

    // Thêm device_data vào root với key là mesh_addr_str
    cJSON_AddItemToObject(root, received_data->device_name, json);

    return root;
}

model_control_data_t *convert_json_to_control_model_list(const char *data, int *count)
{
    cJSON *root = cJSON_Parse(data);
    if (!root)
    {
        printf("JSON parse error\n");
        return NULL;
    }

    cJSON *buzzer_obj = cJSON_GetObjectItem(root, "ControlBuzzer");
    cJSON *led_obj = cJSON_GetObjectItem(root, "ControlLed");

    if (!buzzer_obj || !led_obj)
    {
        printf("Missing 'ControlBuzzer' or 'ControlLed' field\n");
        cJSON_Delete(root);
        return NULL;
    }

    model_control_data_t *device_list = NULL;
    int device_count = 0;

    cJSON *entry = NULL;
    cJSON_ArrayForEach(entry, buzzer_obj)
    {
        const char *device_name = entry->string;
        cJSON *mesh_addr_str = cJSON_GetObjectItem(entry, "MeshAddress");
        cJSON *turn_on = cJSON_GetObjectItem(entry, "TurnOn");

        model_control_data_t new_device = {0};
        strncpy(new_device.device_name, device_name, sizeof(new_device.device_name) - 1);
        new_device.buzzer = cJSON_IsTrue(turn_on);

        if (mesh_addr_str && mesh_addr_str->valuestring && strlen(mesh_addr_str->valuestring) > 2)
        {
            sscanf(mesh_addr_str->valuestring, "0x%hx", &new_device.mesh_addr);
        }

        new_device.led = 0; // mặc định

        device_list = realloc(device_list, sizeof(model_control_data_t) * (device_count + 1));
        if (!device_list)
        {
            printf("Memory allocation failed\n");
            cJSON_Delete(root);
            *count = 0;
            return NULL;
        }

        device_list[device_count++] = new_device;
    }

    // Cập nhật LED cho các device có trong ControlLed
    cJSON_ArrayForEach(entry, led_obj)
    {
        const char *device_name = entry->string;
        cJSON *mesh_addr_str = cJSON_GetObjectItem(entry, "MeshAddress");
        cJSON *turn_on = cJSON_GetObjectItem(entry, "TurnOn");

        for (int i = 0; i < device_count; i++)
        {
            if (strcmp(device_list[i].device_name, device_name) == 0)
            {
                device_list[i].led = cJSON_IsTrue(turn_on) ? 1 : 0;

                if (device_list[i].mesh_addr == 0 && mesh_addr_str && mesh_addr_str->valuestring && strlen(mesh_addr_str->valuestring) > 2)
                {
                    sscanf(mesh_addr_str->valuestring, "0x%hx", &device_list[i].mesh_addr);
                }
                break;
            }
        }
    }

    *count = device_count;
    cJSON_Delete(root);
    return device_list;
}