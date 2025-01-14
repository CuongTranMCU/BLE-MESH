/* board.c - Board-specific hooks */

/*
 * SPDX-FileCopyrightText: 2017 Intel Corporation
 * SPDX-FileContributor: 2018-2021 Espressif Systems (Shanghai) CO LTD
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#include <stdio.h>

#include "driver/gpio.h"
#include "esp_log.h"
#include "board.h"
#include "iot_button.h"
#include "esp_flash.h"
#include "esp_err.h"
#include "esp_system.h"
#include "mesh_device_app.h"
#include "nvs_flash.h"

#define TAG "BOARD"
#define BUTTON_IO_NUM 9
#define BUTTON_ACTIVE_LEVEL 0
struct _led_state led_state[3] = {
    {LED_OFF, LED_OFF, LED_R, "red"},
    {LED_OFF, LED_OFF, LED_G, "green"},
    {LED_OFF, LED_OFF, LED_B, "blue"},
};

void board_led_operation(uint8_t pin, uint8_t onoff)
{
    for (int i = 0; i < 3; i++)
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
    for (int i = 0; i < 3; i++)
    {
        gpio_reset_pin(led_state[i].pin);
        gpio_set_direction(led_state[i].pin, GPIO_MODE_OUTPUT);
        gpio_set_level(led_state[i].pin, LED_OFF);
        led_state[i].previous = LED_OFF;
    }
}
static void button_tap_cb(void *arg)
{
    ESP_LOGI(TAG, "Button tapped, performing flash erase.");

    // Lấy thông tin phân vùng
    const esp_partition_t *partition = esp_partition_find_first(ESP_PARTITION_TYPE_DATA, ESP_PARTITION_SUBTYPE_ANY, NULL);
    if (partition == NULL)
    {
        ESP_LOGE(TAG, "Failed to find partition");
        return;
    }

    // Kiểm tra kích thước phân vùng và địa chỉ hợp lệ
    ESP_LOGI(TAG, "Partition address: 0x%08x, size: 0x%08x", partition->address, partition->size);

    // Xóa phân vùng được tìm thấy
    esp_err_t ret = esp_flash_erase_region(esp_flash_default_chip, partition->address, partition->size);
    if (ret != ESP_OK)
    {
        ESP_LOGE(TAG, "Failed to erase flash region: %s", esp_err_to_name(ret));
        return;
    }
    ESP_LOGI(TAG, "Flash region erased successfully");
    // Tiếp tục khởi tạo BLE Mesh hoặc các phần khác của hệ thống
    ble_mesh_device_init();
    ESP_LOGI(TAG, "BLE Mesh Device has been initialized successfully");
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
    // board_led_init();
    //  server gửi => thêm nút nhấn:
    board_button_init();
}
