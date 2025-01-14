/* board.c - Board-specific hooks */

/*
 * SPDX-FileCopyrightText: 2017 Intel Corporation
 * SPDX-FileContributor: 2018-2021 Espressif Systems (Shanghai) CO LTD
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#include "board.h"
#define WIFI_SSID_KEY "wifi_ssid"
#define WIFI_PASSWORD_KEY "wifi_password"
#define APP_KEY_KEY "app_key"
#define TAG "WiFiProvision"

extern void example_ble_mesh_send_gen_onoff_set(void);
extern void example_ble_mesh_send_gen_onoff_get(void);

// static void erase_entire_flash(void);
// static void erase_ble_mesh_data(void);

void retrieve_all_entries_in_nvs();
void erase_all_data_in_namespace(const char *namespace);

void retrieve_entry_data(const char *namespace);

void clear_wifi_credentials();
void check_wifi_connection();
void get_wifi_configuration();

static void board_led_init(void);
static void board_button_init(void);
static void button_tap_cb(void *arg);

bool buttonPressed = false;
TickType_t lastClickTime = 0;
bool ledStatus = false;

led_state_t led_state[3] = {
    {LED_OFF, LED_OFF, LED_R, "red"},
    {LED_OFF, LED_OFF, LED_G, "green"},
    {LED_OFF, LED_OFF, LED_B, "blue"},
};

void board_led_operation(uint8_t pin, uint8_t onoff)
{
    for (int i = 0; i < ARRAY_SIZE(led_state); i++)
    {
        if (led_state[i].pin != pin)
        {
            continue;
        }
        if (onoff == led_state[i].previous)
        {
            ESP_LOGW(TAG, "led %s is already %s",
                     led_state[i].name, (onoff ? "on" : "off"));
            return;
        }
        gpio_set_level(pin, onoff);
        led_state[i].previous = onoff;
        return;
    }
    ESP_LOGE(TAG, "LED is not found!");
}

static void board_led_init(void)
{
    gpio_config_t io_conf;

    // Configure LED pin as output
    io_conf.intr_type = GPIO_INTR_DISABLE;
    io_conf.mode = GPIO_MODE_OUTPUT;
    io_conf.pin_bit_mask = (1ULL << LED_PIN);
    io_conf.pull_down_en = GPIO_PULLDOWN_DISABLE;
    io_conf.pull_up_en = GPIO_PULLUP_DISABLE;
    gpio_config(&io_conf);

    for (int i = 0; i < ARRAY_SIZE(led_state); i++)
    {
        gpio_reset_pin(led_state[i].pin);
        gpio_set_direction(led_state[i].pin, GPIO_MODE_OUTPUT);
        gpio_set_level(led_state[i].pin, LED_OFF);
        led_state[i].previous = LED_OFF;
    }
}

void wifi_reprovisioning(void)
{
    wifi_prov_mgr_reset_sm_state_for_reprovision();
    xEventGroupWaitBits(wifi_event_group, WIFI_CONNECTED_EVENT, true, true, portMAX_DELAY);
}

static void button_tap_cb(void *arg)
{

    if (buttonPressed)
    {

        buttonPressed = false;
        TickType_t now = xTaskGetTickCount();
        if ((now - lastClickTime) > pdMS_TO_TICKS(2000))
        {
            buttonPressed = true;
        }
        else if ((now - lastClickTime) < pdMS_TO_TICKS(DOUBLE_CLICK_TIME))
        {
            ledStatus = !ledStatus;
            gpio_set_level(LED_PIN, ledStatus);
            // Stop Wifi
            clear_wifi_credentials();
            // get_wifi_configuration();

            // Stop BLE Mesh
            // esp_err_t err;
            // err = stop_ble_mesh();
            // if (err == ESP_OK)
            // {
            //     ESP_LOGI("BLE MESH", "Stopped!");
            // }
            // else
            // {
            //     ESP_LOGE("BLE MESH", "Failed to stop BLE Mesh.");
            // }

            // esp_restart();
        }
        lastClickTime = now;
    }
    else
    {
        buttonPressed = true;
        lastClickTime = xTaskGetTickCount();
    }

    return;
}

void retrieve_entry_data(const char *namespace)
{
    esp_err_t err = nvs_flash_init();
    if (err != ESP_OK)
    {
        ESP_LOGE(TAG, "Failed to initialize NVS: %s", esp_err_to_name(err));
        return;
    }

    // Khởi tạo iterator để duyệt qua các key trong không gian tên mesh_core
    nvs_iterator_t it = NULL;
    err = nvs_entry_find("nvs", namespace, NVS_TYPE_ANY, &it);
    while (err == ESP_OK)
    {
        nvs_entry_info_t info;
        nvs_entry_info(it, &info);
        ESP_LOGI(TAG, "Key '%s', Type '%d', Namespace '%s'", info.key, info.type, info.namespace_name);

        // Mở không gian tên mesh_core để đọc dữ liệu
        nvs_handle_t my_handle;
        err = nvs_open(namespace, NVS_READONLY, &my_handle);
        if (err == ESP_OK)
        {
            if (info.type == NVS_TYPE_BLOB)
            {
                size_t blob_size;
                err = nvs_get_blob(my_handle, info.key, NULL, &blob_size);
                if (err == ESP_OK && blob_size > 0)
                {
                    uint8_t *blob = malloc(blob_size);
                    if (blob != NULL)
                    {
                        err = nvs_get_blob(my_handle, info.key, blob, &blob_size);
                        if (err == ESP_OK)
                        {
                            ESP_LOGI(TAG, "Data for key '%s':", info.key);
                            for (int i = 0; i < blob_size; i++)
                            {
                                printf("%02X ", blob[i]);
                            }
                            printf("\n");
                        }
                        else
                        {
                            ESP_LOGE(TAG, "Failed to read blob for key '%s': %s", info.key, esp_err_to_name(err));
                        }
                        free(blob);
                    }
                }
                else
                {
                    ESP_LOGE(TAG, "Failed to get blob size for key '%s': %s", info.key, esp_err_to_name(err));
                }
            }
            nvs_close(my_handle);
        }
        else
        {
            ESP_LOGE(TAG, "Error opening namespace mesh_core: %s", esp_err_to_name(err));
        }

        // Lấy key tiếp theo
        err = nvs_entry_next(&it);
    }
    nvs_release_iterator(it);
}

void retrieve_all_entries_in_nvs()
{
    esp_err_t err = nvs_flash_init();
    if (err != ESP_OK)
    {
        ESP_LOGE(TAG, "Failed to initialize NVS: %s", esp_err_to_name(err));
        return;
    }

    // List all entries in the NVS for debugging
    nvs_iterator_t it = NULL;
    err = nvs_entry_find("nvs", NULL, NVS_TYPE_ANY, &it);
    while (err == ESP_OK)
    {
        nvs_entry_info_t info;
        nvs_entry_info(it, &info);
        ESP_LOGI(TAG, "Key '%s', Type '%d', Namespace '%s'", info.key, info.type, info.namespace_name);
        err = nvs_entry_next(&it);
    }
    nvs_release_iterator(it);
}

void erase_all_data_in_namespace(const char *namespace)
{
    esp_err_t err = nvs_flash_init();
    if (err != ESP_OK)
    {
        ESP_LOGE(TAG, "Failed to initialize NVS: %s", esp_err_to_name(err));
        return;
    }

    // Mở không gian tên mesh_core để xóa dữ liệu
    nvs_handle_t my_handle;
    err = nvs_open(namespace, NVS_READWRITE, &my_handle);
    if (err == ESP_OK)
    {
        // Xóa tất cả các entry trong namespace
        err = nvs_erase_all(my_handle);
        if (err == ESP_OK)
        {
            ESP_LOGI(TAG, "Successfully erased all data in namespace '%s'", namespace);
        }
        else
        {
            ESP_LOGE(TAG, "Failed to erase all data in namespace '%s': %s", namespace, esp_err_to_name(err));
        }

        // Đóng handle sau khi xóa
        nvs_close(my_handle);
    }
    else
    {
        ESP_LOGE(TAG, "Failed to open NVS namespace '%s': %s", namespace, esp_err_to_name(err));
    }
}

void clear_ble_mesh_data()
{
    erase_all_data_in_namespace("mesh_core");

    // Restart esp32c6
    printf("Restarting now.\n");
    fflush(stdout);
    esp_restart();
}

void clear_wifi_credentials()
{
    erase_all_data_in_namespace("nvs.net80211");

    esp_wifi_stop();
    check_wifi_connection();
    esp_restart();
}

void get_wifi_configuration()
{

    // Get Wi-Fi configuration
    wifi_config_t wifi_cfg;
    esp_wifi_get_config(ESP_IF_WIFI_STA, &wifi_cfg);
    ESP_LOGI(TAG, "WIFI SSID: %s", (char *)wifi_cfg.sta.ssid);
    ESP_LOGI(TAG, "WIFI Password: %s", (char *)wifi_cfg.sta.password);

}

void check_wifi_connection()
{
    wifi_ap_record_t ap_info;
    esp_err_t err = esp_wifi_sta_get_ap_info(&ap_info);

    if (err == ESP_OK)
    {
        ESP_LOGI("WiFiStatus", "Connected to Wi-Fi SSID: %s, Signal Strength: %d", ap_info.ssid, ap_info.rssi);
    }
    else
    {
        ESP_LOGI("WiFiStatus", "Not connected to any Wi-Fi network.");
    }
}

static void board_button_init(void)
{
    button_handle_t btn_handle = iot_button_create(BUTTON_IO_NUM, BUTTON_ACTIVE_LEVEL);
    if (btn_handle)
    {

        iot_button_set_evt_cb(btn_handle, BUTTON_CB_RELEASE, button_tap_cb, "RELEASE");
    }
}

void board_init(void)
{
    board_led_init();
    board_button_init();
}
