/* board.h - Board-specific hooks */

/*
 * SPDX-FileCopyrightText: 2017 Intel Corporation
 * SPDX-FileContributor: 2018-2021 Espressif Systems (Shanghai) CO LTD
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#ifndef _BOARD_H_
#define _BOARD_H_

#include "driver/gpio.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/timers.h"
#include "esp_log.h"
#include "esp_flash.h"
#include "esp_timer.h"
#include "esp_err.h"
#include "esp_system.h"
#include "nvs_flash.h"
#include "iot_button.h"
#include "esp_ble_mesh_defs.h"
#include "wifi.h"

#include <stdio.h>

// Define LED pins based on ESP32 board configuration
#if defined(CONFIG_BLE_MESH_ESP_WROOM_32)
#define LED_R GPIO_NUM_25
#define LED_G GPIO_NUM_26
#define LED_B GPIO_NUM_27
#elif defined(CONFIG_BLE_MESH_ESP_WROVER)
#define LED_R GPIO_NUM_0
#define LED_G GPIO_NUM_2
#define LED_B GPIO_NUM_4
#elif defined(CONFIG_BLE_MESH_ESP32C3_DEV) || \
    defined(CONFIG_BLE_MESH_ESP32C6_DEV) ||   \
    defined(CONFIG_BLE_MESH_ESP32H2_DEV)
#define LED_R GPIO_NUM_8
#define LED_G GPIO_NUM_8
#define LED_B GPIO_NUM_8
#elif defined(CONFIG_BLE_MESH_ESP32S3_DEV)
#define LED_R GPIO_NUM_47
#define LED_G GPIO_NUM_47
#define LED_B GPIO_NUM_47
#endif

// LED status macros
#define LED_ON 1
#define LED_OFF 0

// GPIO pins
#define LED_PIN GPIO_NUM_7
#define PUSH_BUTTON_PIN GPIO_NUM_13
#define BUTTON_IO_NUM GPIO_NUM_9
#define BUTTON_ACTIVE_LEVEL 0

// Tags for logging
#define TAG "BOARD"
#define RESET_TAG "BLE_MESH_RESET"

// Button configuration
#define DOUBLE_CLICK_TIME 500 // milliseconds

// LED state structure
typedef struct __attribute__((packed))
{
    uint8_t current;
    uint8_t previous;
    uint8_t pin;
    char *name;
} led_state_t;

typedef enum states
{
    INIT_STATE,
    BEFORE_800ms,
    AFTER_800ms,
    LONG_PRESSED
} button_state_t;

// Function declarations
void board_led_operation(uint8_t pin, uint8_t onoff);
void board_init(void);
void wifi_reprovisioning(void);
#endif /* _BOARD_H_ */
