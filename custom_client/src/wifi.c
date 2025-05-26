#include "wifi.h"

static EventGroupHandle_t s_wifi_event_group;

static const int CONNECTED_BIT = BIT0;
static const int ESPTOUCH_DONE_BIT = BIT1;
static TaskHandle_t smartconfig_task_handle = NULL;

static int retry_count = 0;

static const char *TAG = "smartconfig_example";
static uint8_t ssid[32] = {0};
static uint8_t password[64] = {0};
static uint8_t rvd_data[64] = {0};

static mqtt_config_t mqtt_config;

static void wifi_set_mqtt_config(uint8_t *rvd_data);

static void event_handler(void *arg, esp_event_base_t event_base,
                          int32_t event_id, void *event_data)
{
    if (event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_START)
    {
        ESP_LOGI(TAG, "WIFI_EVENT_STA_START");
        esp_err_t err = get_wifi_configuration();
        if (err == ESP_OK)
        {
            ESP_LOGI(TAG, "ESP already has Wi-Fi configuration, connecting...");
            esp_wifi_connect();
        }
        else
        {
            ESP_LOGW(TAG, "ESP does not have a valid Wi-Fi configuration, starting SmartConfig...");
            xTaskCreate(smartconfig_example_task, "smartconfig_example_task", 4096, NULL, 3, &smartconfig_task_handle);
        }
    }
    else if (event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_DISCONNECTED)
    {
        if (retry_count < MAX_RETRY)
        {
            ESP_LOGW(TAG, "WiFi connection failed, retrying... (%d/%d)", retry_count + 1, MAX_RETRY);
            esp_wifi_connect();
            retry_count++;
        }
        else
        {
            ESP_LOGE(TAG, "WiFi connection failed after %d attempts, restarting SmartConfig...", MAX_RETRY);
            retry_count = 0;                     // Reset bộ đếm
            esp_smartconfig_stop();              // Dừng SmartConfig nếu đang chạy
            if (smartconfig_task_handle != NULL) // Kiểm tra task cũ
            {
                vTaskDelete(smartconfig_task_handle); // Xóa task cũ
                smartconfig_task_handle = NULL;
            }
            xTaskCreate(smartconfig_example_task, "smartconfig_example_task", 4096, NULL, 3, &smartconfig_task_handle);
        }
        xEventGroupClearBits(s_wifi_event_group, CONNECTED_BIT);
    }
    else if (event_base == IP_EVENT && event_id == IP_EVENT_STA_GOT_IP)
    {
        ip_event_got_ip_t *event = (ip_event_got_ip_t *)event_data;
        ESP_LOGI(TAG, "got ip:" IPSTR, IP2STR(&event->ip_info.ip));

        check_wifi_connection();
        xEventGroupSetBits(s_wifi_event_group, CONNECTED_BIT);

        esp_err_t err;
        if (strlen(mqtt_config.uri) > 0)
        {
            err = save_mqtt_config(&mqtt_config);
            if (err != ESP_OK)
            {
                ESP_LOGE(TAG, "Failed to save MQTT configuration: %s", esp_err_to_name(err));
                return;
            }
            else
            {
                ESP_LOGI(TAG, "MQTT configuration saved successfully");
            }
        }

        err = load_mqtt_config(&mqtt_config);

        if (err != ESP_OK)
        {
            ESP_LOGE(TAG, "Failed to load MQTT configuration: %s", esp_err_to_name(err));
        }
        else
        {
            // In ra để kiểm tra
            ESP_LOGI("Load MQTT Config From NVS", "MQTT Config - URI: %s, Port: %lu, Username: %s, Password: %s",
                     mqtt_config.uri[0] ? mqtt_config.uri : "(empty)",
                     mqtt_config.port,
                     mqtt_config.username[0] ? mqtt_config.username : "(empty)",
                     mqtt_config.password[0] ? mqtt_config.password : "(empty)");

            ESP_LOGI(TAG, "MQTT configuration loaded successfully");
            mqtt_app_start(&mqtt_config);
        }
    }
    else if (event_base == SC_EVENT && event_id == SC_EVENT_SCAN_DONE)
    {

        ESP_LOGI(TAG, "Scan done");
    }
    else if (event_base == SC_EVENT && event_id == SC_EVENT_FOUND_CHANNEL)
    {
        ESP_LOGI(TAG, "Found channel");
    }
    else if (event_base == SC_EVENT && event_id == SC_EVENT_GOT_SSID_PSWD)
    {
        ESP_LOGI(TAG, "Got SSID and password");

        smartconfig_event_got_ssid_pswd_t *evt = (smartconfig_event_got_ssid_pswd_t *)event_data;
        wifi_config_t wifi_config;

        bzero(&wifi_config, sizeof(wifi_config_t));
        memcpy(wifi_config.sta.ssid, evt->ssid, sizeof(wifi_config.sta.ssid));
        memcpy(wifi_config.sta.password, evt->password, sizeof(wifi_config.sta.password));

        wifi_config.sta.bssid_set = evt->bssid_set;
        if (wifi_config.sta.bssid_set == true)
        {
            memcpy(wifi_config.sta.bssid, evt->bssid, sizeof(wifi_config.sta.bssid));
        }
        // Thiết lập chế độ xác thực tối thiểu là WPA2_PSK
        wifi_config.sta.threshold.authmode = WIFI_AUTH_WPA2_PSK;
        memcpy(ssid, evt->ssid, sizeof(evt->ssid));
        memcpy(password, evt->password, sizeof(evt->password));

        ESP_LOGI(TAG, "SSID:%s", ssid);
        ESP_LOGI(TAG, "PASSWORD:%s", password);
        if (evt->type == SC_TYPE_ESPTOUCH_V2)
        {
            ESP_ERROR_CHECK(esp_smartconfig_get_rvd_data(rvd_data, sizeof(rvd_data)));
            ESP_LOGI(TAG, "RVD_DATA:");
            for (int i = 0; i < sizeof(rvd_data); i++)
            {
                printf("%c", rvd_data[i]);
            }
            printf("\n");
            wifi_set_mqtt_config(rvd_data); // Gọi hàm để xử lý rvd_data
        }

        ESP_ERROR_CHECK(esp_wifi_disconnect());
        ESP_ERROR_CHECK(esp_wifi_set_config(WIFI_IF_STA, &wifi_config));
        esp_wifi_connect();
    }
    else if (event_base == SC_EVENT && event_id == SC_EVENT_SEND_ACK_DONE)
    {
        xEventGroupSetBits(s_wifi_event_group, ESPTOUCH_DONE_BIT);
    }
}

static void smartconfig_example_task(void *parm)
{
    EventBits_t uxBits;
    ESP_ERROR_CHECK(esp_smartconfig_set_type(SC_TYPE_ESPTOUCH_V2));
    smartconfig_start_config_t cfg = SMARTCONFIG_START_CONFIG_DEFAULT();
    ESP_ERROR_CHECK(esp_smartconfig_start(&cfg));
    while (1)
    {
        uxBits = xEventGroupWaitBits(s_wifi_event_group, CONNECTED_BIT | ESPTOUCH_DONE_BIT, true, false, portMAX_DELAY);
        if (uxBits & CONNECTED_BIT)
        {
            ESP_LOGI(TAG, "WiFi Connected to ap");
        }
        if (uxBits & ESPTOUCH_DONE_BIT)
        {
            ESP_LOGI(TAG, "smartconfig over");

            esp_smartconfig_stop();

            smartconfig_task_handle = NULL; // Reset handle
            vTaskDelete(NULL);
        }
    }
}

static void wifi_set_mqtt_config(uint8_t *rvd_data)
{
    // Tìm độ dài thực tế của dữ liệu, tối đa 64 byte
    size_t len = strnlen((char *)rvd_data, 64);
    if (len == 64 && rvd_data[63] != '\0')
    {
        ESP_LOGE(TAG, "rvd_data không được kết thúc bằng null trong 64 byte");
        return; // Thoát nếu dữ liệu không hợp lệ
    }

    char rvd_str[len + 1];          // Kích thước động dựa trên len
    memcpy(rvd_str, rvd_data, len); // Chỉ sao chép phần dữ liệu hợp lệ
    rvd_str[len] = '\0';            // Đảm bảo kết thúc bằng null

    char *token;

    // Tách uri
    token = strtok(rvd_str, ";");
    if (token != NULL)
    {
        strncpy(mqtt_config.uri, token, sizeof(mqtt_config.uri) - 1);
        mqtt_config.uri[sizeof(mqtt_config.uri) - 1] = '\0';
    }
    else
    {
        mqtt_config.uri[0] = '\0';
    }

    // Tách port
    token = strtok(NULL, ";");
    if (token != NULL)
    {
        mqtt_config.port = strtoul(token, NULL, 10);
    }
    else
    {
        mqtt_config.port = 0;
    }

    // Tách username
    token = strtok(NULL, ";");
    if (token != NULL)
    {
        strncpy(mqtt_config.username, token, sizeof(mqtt_config.username) - 1);
        mqtt_config.username[sizeof(mqtt_config.username) - 1] = '\0';
    }
    else
    {
        mqtt_config.username[0] = '\0';
    }

    // Tách password
    token = strtok(NULL, ";");
    if (token != NULL)
    {
        strncpy(mqtt_config.password, token, sizeof(mqtt_config.password) - 1);
        mqtt_config.password[sizeof(mqtt_config.password) - 1] = '\0';
    }
    else
    {
        mqtt_config.password[0] = '\0';
    }

    // // In ra để kiểm tra
    // ESP_LOGI(TAG, "MQTT Config - URI: %s, Port: %lu, Username: %s, Password: %s",
    //          mqtt_config.uri[0] ? mqtt_config.uri : "(empty)",
    //          mqtt_config.port,
    //          mqtt_config.username[0] ? mqtt_config.username : "(empty)",
    //          mqtt_config.password[0] ? mqtt_config.password : "(empty)");
}

esp_err_t get_wifi_configuration()
{

    // Get Wi-Fi configuration
    wifi_config_t wifi_cfg;
    esp_err_t err = esp_wifi_get_config(ESP_IF_WIFI_STA, &wifi_cfg);

    if (err == ESP_OK)
    {
        ESP_LOGI(TAG, "WIFI SSID: %s", (char *)wifi_cfg.sta.ssid);
        ESP_LOGI(TAG, "WIFI Password: %s", (char *)wifi_cfg.sta.password);
        if ((strlen((char *)wifi_cfg.sta.ssid) == 0)) // Kiểm tra SSID có rỗng không
        {
            ESP_LOGW(TAG, "No Wi-Fi credentials stored!");
            return ESP_FAIL; // Trả về lỗi để trigger SmartConfig
        }
    }
    return err;
}

esp_err_t check_wifi_connection()
{
    wifi_ap_record_t ap_info;
    esp_err_t err = esp_wifi_sta_get_ap_info(&ap_info);

    if (err == ESP_OK)
    {
        ESP_LOGI("WiFiStatus", "Connected to Wi-Fi SSID: %s, Signal Strength: %d", ap_info.ssid, ap_info.rssi);
    }
    return err;
}

void wifi_clear_config()
{

    ESP_LOGI(TAG, "Clearing Wi-Fi configuration...");

    // Dừng MQTT để tránh lỗi disconnect đột ngột
    mqtt_app_stop();

    // Chờ một chút để MQTT đóng hoàn toàn
    vTaskDelay(pdMS_TO_TICKS(200));

    // Kiểm tra trạng thái Wi-Fi trước khi ngắt kết nối
    ESP_ERROR_CHECK(esp_wifi_disconnect());

    // Đặt lại cấu hình rỗng
    wifi_config_t wifi_config = {0};
    ESP_ERROR_CHECK(esp_wifi_set_config(WIFI_IF_STA, &wifi_config));

    // Dừng Wi-Fi để đảm bảo không còn giữ kết nối
    ESP_ERROR_CHECK(esp_wifi_stop());
    vTaskDelay(pdMS_TO_TICKS(500)); // Chờ Wi-Fi dừng hoàn toàn

    // Bật lại Wi-Fi
    ESP_ERROR_CHECK(esp_wifi_start());

    ESP_LOGI(TAG, "Wi-Fi reset done. You need to set new credentials.");
}

static void initialise_wifi(void)
{
    ESP_ERROR_CHECK(esp_netif_init());
    s_wifi_event_group = xEventGroupCreate();
    ESP_ERROR_CHECK(esp_event_loop_create_default());
    esp_netif_t *sta_netif = esp_netif_create_default_wifi_sta();
    assert(sta_netif);

    wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();
    ESP_ERROR_CHECK(esp_wifi_init(&cfg));

    ESP_ERROR_CHECK(esp_event_handler_register(WIFI_EVENT, ESP_EVENT_ANY_ID, &event_handler, NULL));
    ESP_ERROR_CHECK(esp_event_handler_register(IP_EVENT, IP_EVENT_STA_GOT_IP, &event_handler, NULL));
    ESP_ERROR_CHECK(esp_event_handler_register(SC_EVENT, ESP_EVENT_ANY_ID, &event_handler, NULL));

    ESP_ERROR_CHECK(esp_wifi_set_mode(WIFI_MODE_STA));
    ESP_ERROR_CHECK(esp_wifi_start());
}

void deinitialise_wifi()
{
    ESP_LOGI(TAG, "Stopping Wi-Fi...");
    ESP_ERROR_CHECK(esp_wifi_stop());

    // Chờ MQTT/BLE Mesh dừng hoàn toàn
    vTaskDelay(pdMS_TO_TICKS(1000));

    ESP_LOGI(TAG, "Unregistering Wi-Fi event handlers...");
    ESP_ERROR_CHECK(esp_event_handler_unregister(WIFI_EVENT, ESP_EVENT_ANY_ID, &event_handler));
    ESP_ERROR_CHECK(esp_event_handler_unregister(IP_EVENT, IP_EVENT_STA_GOT_IP, &event_handler));
    ESP_ERROR_CHECK(esp_event_handler_unregister(SC_EVENT, ESP_EVENT_ANY_ID, &event_handler));

    ESP_LOGI(TAG, "Destroying Wi-Fi netif...");
    esp_netif_t *sta_netif = esp_netif_get_handle_from_ifkey("WIFI_STA_DEF");
    if (sta_netif)
    {
        esp_netif_destroy(sta_netif);
    }

    ESP_LOGI(TAG, "Deleting event loop...");
    ESP_ERROR_CHECK(esp_event_loop_delete_default());

    ESP_LOGI(TAG, "Deleting Wi-Fi event group...");
    vEventGroupDelete(s_wifi_event_group);

    ESP_LOGI(TAG, "Deinitializing Wi-Fi...");
    ESP_ERROR_CHECK(esp_wifi_deinit());

    ESP_LOGI(TAG, "Wi-Fi deinitialized successfully.");
}

void wifi_init()
{
    ESP_ERROR_CHECK(nvs_flash_init());
    initialise_wifi();
}