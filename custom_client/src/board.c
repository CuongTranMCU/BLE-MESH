/* board.c - Board-specific hooks */

/*
 * SPDX-FileCopyrightText: 2017 Intel Corporation
 * SPDX-FileContributor: 2018-2021 Espressif Systems (Shanghai) CO LTD
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#include "board.h"

#define TAG "BUTTON"

void retrieve_all_entries_in_nvs();
void erase_all_data_in_namespace(const char *namespace);

void retrieve_entry_data(const char *namespace);

void clear_wifi_credentials();
void reset_nvs_flash();

void button_press_cb(void *arg);
void button_release_cb(void *arg);
void vTimerCallback_800ms(TimerHandle_t xTimer);
void vTimerCallback_3s();

static void board_button_init(void);

bool buttonPressed = false;
TickType_t lastClickTime = 0;

int count = 0;
button_state_t state = INIT_STATE;

TimerHandle_t buttonTimer_800ms = NULL;
TimerHandle_t buttonTimer_3s = NULL;

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

    ESP_LOGI(TAG, "Clearing Wi-Fi credentials...");

    // Dừng MQTT để tránh lỗi disconnect đột ngột
    mqtt_app_stop();
    vTaskDelay(pdMS_TO_TICKS(200)); // Chờ một chút để MQTT đóng hoàn toàn

    // Kiểm tra trạng thái Wi-Fi trước khi ngắt kết nối
    wifi_ap_record_t ap_info;
    if (esp_wifi_sta_get_ap_info(&ap_info) == ESP_OK)
    {
        ESP_LOGI(TAG, "Wi-Fi is connected. Disconnecting...");
        ESP_ERROR_CHECK(esp_wifi_disconnect());
    }
    else
    {
        ESP_LOGW(TAG, "Wi-Fi is already disconnected.");
    }

    // Xóa dữ liệu Wi-Fi trong NVS
    erase_all_data_in_namespace("nvs.net80211");

    // Dừng Wi-Fi để đảm bảo không còn kết nối
    ESP_ERROR_CHECK(esp_wifi_stop());

    // Khởi động lại thiết bị để áp dụng thay đổi
    ESP_LOGI(TAG, "Restarting now...");
    vTaskDelay(pdMS_TO_TICKS(100)); // Chờ để log được in ra đầy đủ
    esp_restart();
}

void reset_nvs_flash()
{
    ESP_LOGI("Flash", "Erasing NVS flash...");

    // Deinit trước khi xóa
    nvs_flash_deinit();

    esp_err_t ret = nvs_flash_erase();
    if (ret == ESP_OK)
    {
        ESP_LOGI("Flash", "NVS flash erased successfully!");
    }
    else
    {
        ESP_LOGE("Flash", "Failed to erase NVS flash: %s", esp_err_to_name(ret));
    }

    printf("Restarting now.\n");
    fflush(stdout);
    esp_restart();
}

static void board_button_init(void)
{
    button_handle_t btn_handle = iot_button_create(BUTTON_IO_NUM, BUTTON_ACTIVE_LEVEL);
    if (btn_handle)
    {
        iot_button_set_evt_cb(btn_handle, BUTTON_CB_PUSH, button_press_cb, "PRESS");

        iot_button_set_evt_cb(btn_handle, BUTTON_CB_RELEASE, button_release_cb, "RELEASE");
    }
}

void board_init(void)
{
    board_button_init();
}

void button_release_cb(void *arg)
{

    ESP_LOGI(TAG, "Button released");

    if (state == LONG_PRESSED)
    {
        ESP_LOGI(TAG, "Long press detected");

        reset_nvs_flash();

        state = INIT_STATE;
    }
    else
    {
        if (xTimerStop(buttonTimer_3s, 0) == pdPASS)
        {
            if (state < AFTER_800ms)
            {
                count += 1;
            }
            state = INIT_STATE;
        }
    }
}

void button_press_cb(void *arg)
{
    ESP_LOGI(TAG, "Button pressed");
    buttonTimer_800ms = xTimerCreate("Timer", pdMS_TO_TICKS(800), pdFALSE, (void *)0, vTimerCallback_800ms);
    xTimerStart(buttonTimer_800ms, 0);

    buttonTimer_3s = xTimerCreate("Timer", pdMS_TO_TICKS(3000), pdFALSE, NULL, vTimerCallback_3s);
    state = BEFORE_800ms;
    xTimerStart(buttonTimer_3s, 0);
    return;
}

void vTimerCallback_800ms(TimerHandle_t xTimer)
{
    uint32_t ulCount;
    configASSERT(xTimer);
    ulCount = (uint32_t)pvTimerGetTimerID(xTimer);
    if (ulCount == 0)
    {
        if (count == 1)
        {
            ESP_LOGI("BUTTON", "Single click detected");
        }
        else if (count == 2)
        {
            ESP_LOGI("BUTTON", "Double click detected");
            clear_wifi_credentials();
        }
        else if (count == 3)
        {
            ESP_LOGI("BUTTON", "Triple click detected");
            clear_ble_mesh_data();
        }
    }
    count = 0;

    if (state == BEFORE_800ms)
    {
        state = AFTER_800ms;
    }

    return;
}

void vTimerCallback_3s()
{
    if (state == AFTER_800ms)
    {
        state = LONG_PRESSED;
    }
    return;
}
