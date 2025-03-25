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
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#define TAG "BOARD"
static TaskHandle_t blink_task_handle = NULL;
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
    gpio_config_t io_conf = {
        .intr_type = GPIO_INTR_DISABLE,
        .mode = GPIO_MODE_OUTPUT,
        .pin_bit_mask = (1ULL << LED_RED_GPIO) | 
                       (1ULL << LED_GREEN_GPIO) | 
                       (1ULL << LED_BLUE_GPIO),
        .pull_down_en = GPIO_PULLDOWN_DISABLE,
        .pull_up_en = GPIO_PULLUP_DISABLE
    };
    gpio_config(&io_conf);

    // Initially turn off all LEDs
    led_off();

    board_led_init();
    //  server gửi => thêm nút nhấn:
    board_button_init();
}
// Turn off all LEDs
void led_off(void)
{
    gpio_set_level(LED_RED_GPIO, 1);
    gpio_set_level(LED_GREEN_GPIO, 1);
    gpio_set_level(LED_BLUE_GPIO, 1);
}
// Blink task for unprovisioned state
static void led_blink_task(void *arg)
{
    while (1) {
        // Turn on blue LED
        gpio_set_level(LED_BLUE_GPIO, 1);
        vTaskDelay(pdMS_TO_TICKS(500));  // On for 0.5 second
        
        // Turn off blue LED
        gpio_set_level(LED_BLUE_GPIO, 0);
        vTaskDelay(pdMS_TO_TICKS(500));  // Off for 0.5 second
    }
}

// Function to indicate not provisioned state (blinking blue)
void led_indicate_not_provisioned(void)
{
    // Stop any existing blink task
    if (blink_task_handle != NULL) {
        vTaskDelete(blink_task_handle);
        blink_task_handle = NULL;
    }

    // Turn off all LEDs first
    led_off();

    // Create blinking task
    xTaskCreate(led_blink_task, "led_blink", 2048, NULL, 5, &blink_task_handle);
    ESP_LOGI(TAG, "Started LED blinking for unprovisioned state");
}

// Function to indicate provisioned state (solid green)
void led_indicate_provisioned(void)
{
    // Stop blinking task if it exists
    if (blink_task_handle != NULL) {
        vTaskDelete(blink_task_handle);
        blink_task_handle = NULL;
    }

    // Turn off all LEDs first
    led_off();

    // Turn on green LED
    gpio_set_level(LED_GREEN_GPIO, 0);
    ESP_LOGI(TAG, "LED set to solid green for provisioned state");
}
