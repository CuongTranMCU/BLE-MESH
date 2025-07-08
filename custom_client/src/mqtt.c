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
        msg_id = esp_mqtt_client_subscribe(client, "Gateway-Send-Control", 0);
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

void mqtt_app_start(const mqtt_config_t *config)
{
    esp_mqtt_client_config_t mqtt_cfg = {
        .broker.address.uri = config->uri,
        .broker.address.port = config->port,
        .credentials.username = config->username,
        .credentials.authentication.password = config->password,
        //  .broker.verification.skip_cert_common_name_check = true,
    };

    // esp_mqtt_client_config_t mqtt_cfg = {
    //     .broker.address.uri = "mqtt://192.168.124.73",
    //     .broker.address.port = 1883,
    // };

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

esp_err_t save_mqtt_config(const mqtt_config_t *config)
{
    nvs_handle_t nvs_handle;
    esp_err_t err = nvs_open("mqtt_ns", NVS_READWRITE, &nvs_handle);
    if (err != ESP_OK)
    {
        ESP_LOGE(TAG, "Failed to open NVS: %s", esp_err_to_name(err));
        return err;
    }

    // Ghi uri
    err = nvs_set_str(nvs_handle, "uri", config->uri);
    if (err != ESP_OK)
        goto cleanup;

    // Ghi username
    err = nvs_set_str(nvs_handle, "username", config->username);
    if (err != ESP_OK)
        goto cleanup;

    // Ghi password
    err = nvs_set_str(nvs_handle, "password", config->password);
    if (err != ESP_OK)
        goto cleanup;

    // Ghi port
    err = nvs_set_u32(nvs_handle, "port", config->port);
    if (err != ESP_OK)
        goto cleanup;

    // Commit thay đổi
    err = nvs_commit(nvs_handle);
    if (err != ESP_OK)
    {
        ESP_LOGE(TAG, "Failed to commit NVS: %s", esp_err_to_name(err));
    }

cleanup:
    if (err != ESP_OK)
    {
        ESP_LOGE(TAG, "Failed to save MQTT config: %s", esp_err_to_name(err));
    }
    nvs_close(nvs_handle);
    return err;
}

esp_err_t load_mqtt_config(mqtt_config_t *config)
{
    nvs_handle_t nvs_handle;
    esp_err_t err = nvs_open("mqtt_ns", NVS_READONLY, &nvs_handle);
    if (err != ESP_OK)
    {
        ESP_LOGE(TAG, "Failed to open NVS: %s", esp_err_to_name(err));
        return err;
    }

    size_t size;

    // Đọc uri
    size = sizeof(config->uri);
    err = nvs_get_str(nvs_handle, "uri", config->uri, &size);
    if (err != ESP_OK)
        goto cleanup;

    // Đọc username
    size = sizeof(config->username);
    err = nvs_get_str(nvs_handle, "username", config->username, &size);
    if (err != ESP_OK)
        goto cleanup;

    // Đọc password
    size = sizeof(config->password);
    err = nvs_get_str(nvs_handle, "password", config->password, &size);
    if (err != ESP_OK)
        goto cleanup;

    // Đọc port
    err = nvs_get_u32(nvs_handle, "port", &config->port);
    if (err != ESP_OK)
        goto cleanup;

cleanup:
    if (err != ESP_OK)
    {
        ESP_LOGE(TAG, "Failed to load MQTT config: %s", esp_err_to_name(err));
    }
    nvs_close(nvs_handle);
    return err;
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
    cJSON_AddBoolToObject(device_data, "isFlame", received_data->isFlame);
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

    // Tạo root object
    cJSON *root = cJSON_CreateObject();
    if (!root)
    {
        printf("Error: Failed to create root object.\n");
        return NULL;
    }

    // Chuyển mesh address sang string "0xXXXX"
    char mesh_addr_str[7];
    snprintf(mesh_addr_str, sizeof(mesh_addr_str), "0x%04X", received_data->mesh_addr);

    // ---- ControlBuzzer ----
    cJSON *control_buzzer = cJSON_CreateObject();
    cJSON *buzzer_obj = cJSON_CreateObject();

    if (!control_buzzer || !buzzer_obj)
    {
        cJSON_Delete(root);
        printf("Error: Failed to create ControlBuzzer object.\n");
        return NULL;
    }

    cJSON_AddStringToObject(buzzer_obj, "MeshAddress", mesh_addr_str);
    cJSON_AddBoolToObject(buzzer_obj, "TurnOn", received_data->buzzerStatus);
    cJSON_AddBoolToObject(buzzer_obj, "Error", received_data->buzzerError);
    cJSON_AddItemToObject(control_buzzer, received_data->device_name, buzzer_obj);
    cJSON_AddItemToObject(root, "ControlBuzzer", control_buzzer);

    // ---- ControlLed ----
    cJSON *control_led = cJSON_CreateObject();
    cJSON *led_obj = cJSON_CreateObject();

    if (!control_led || !led_obj)
    {
        cJSON_Delete(root);
        printf("Error: Failed to create ControlLed object.\n");
        return NULL;
    }

    cJSON_AddStringToObject(led_obj, "MeshAddress", mesh_addr_str);
    cJSON_AddBoolToObject(led_obj, "LedRed", received_data->ledStatus[0]);
    cJSON_AddBoolToObject(led_obj, "LedGreen", received_data->ledStatus[1]);
    cJSON_AddBoolToObject(led_obj, "LedBlue", received_data->ledStatus[2]);
    cJSON_AddBoolToObject(led_obj, "Error", received_data->ledError);
    cJSON_AddItemToObject(control_led, received_data->device_name, led_obj);
    cJSON_AddItemToObject(root, "ControlLed", control_led);

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
        if (!device_name)
            continue;

        cJSON *mesh_addr_str = cJSON_GetObjectItem(entry, "MeshAddress");
        cJSON *turn_on = cJSON_GetObjectItem(entry, "TurnOn");
        cJSON *error = cJSON_GetObjectItem(entry, "Error");

        model_control_data_t new_device = {0};
        strncpy(new_device.device_name, device_name, sizeof(new_device.device_name) - 1);
        new_device.buzzerStatus = cJSON_IsTrue(turn_on);
        new_device.buzzerError = cJSON_IsTrue(error);
        new_device.ledError = false; // sẽ cập nhật sau nếu có trong ControlLed
        new_device.ledStatus[0] = 0;
        new_device.ledStatus[1] = 0;
        new_device.ledStatus[2] = 0;

        if (mesh_addr_str && cJSON_IsString(mesh_addr_str) && strlen(mesh_addr_str->valuestring) > 2)
        {
            sscanf(mesh_addr_str->valuestring, "0x%hx", &new_device.mesh_addr);
        }

        model_control_data_t *temp = realloc(device_list, sizeof(model_control_data_t) * (device_count + 1));
        if (!temp)
        {
            printf("Memory allocation failed\n");
            free(device_list);
            cJSON_Delete(root);
            *count = 0;
            return NULL;
        }

        device_list = temp;
        device_list[device_count++] = new_device;
    }

    // Cập nhật trạng thái LED từ ControlLed
    cJSON_ArrayForEach(entry, led_obj)
    {
        const char *device_name = entry->string;
        if (!device_name)
            continue;

        cJSON *mesh_addr_str = cJSON_GetObjectItem(entry, "MeshAddress");
        cJSON *led_red = cJSON_GetObjectItem(entry, "LedRed");
        cJSON *led_green = cJSON_GetObjectItem(entry, "LedGreen");
        cJSON *led_blue = cJSON_GetObjectItem(entry, "LedBlue");
        cJSON *error = cJSON_GetObjectItem(entry, "Error");

        for (int i = 0; i < device_count; i++)
        {
            if (strcmp(device_list[i].device_name, device_name) == 0)
            {
                device_list[i].ledStatus[0] = cJSON_IsTrue(led_red);
                device_list[i].ledStatus[1] = cJSON_IsTrue(led_green);
                device_list[i].ledStatus[2] = cJSON_IsTrue(led_blue);
                device_list[i].ledError = cJSON_IsTrue(error);

                if (device_list[i].mesh_addr == 0 && mesh_addr_str && cJSON_IsString(mesh_addr_str))
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