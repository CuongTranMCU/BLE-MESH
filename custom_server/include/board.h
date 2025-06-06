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

#if defined(CONFIG_BLE_MESH_ESP_WROOM_32)
#define LED_R GPIO_NUM_17
#define LED_G GPIO_NUM_26
#define LED_B GPIO_NUM_27
#elif defined(CONFIG_BLE_MESH_ESP_WROVER)
#define LED_R GPIO_NUM_0
#define LED_G GPIO_NUM_2
#define LED_B GPIO_NUM_4
#elif defined(CONFIG_BLE_MESH_ESP32C3_DEV)
#define LED_R GPIO_NUM_8
#define LED_G GPIO_NUM_8
#define LED_B GPIO_NUM_8
#elif defined(CONFIG_BLE_MESH_ESP32S3_DEV)
#define LED_R GPIO_NUM_47
#define LED_G GPIO_NUM_47
#define LED_B GPIO_NUM_47
#elif defined(CONFIG_BLE_MESH_ESP32C6_DEV)
#define LED_R GPIO_NUM_8
#define LED_G GPIO_NUM_8
#define LED_B GPIO_NUM_8
#elif defined(CONFIG_BLE_MESH_ESP32H2_DEV)
#define LED_R GPIO_NUM_8
#define LED_G GPIO_NUM_8
#define LED_B GPIO_NUM_8
#endif

// Define RGB LED pins
#define LED_RED_GPIO    GPIO_NUM_20
#define LED_GREEN_GPIO  GPIO_NUM_19
#define LED_BLUE_GPIO   GPIO_NUM_18
// 
#define LED_ON 1
#define LED_OFF 0

struct _led_state
{
    uint8_t current;
    uint8_t previous;
    uint8_t pin;
    char *name;
};

void board_led_operation(uint8_t pin, uint8_t onoff);

void board_init(void);
void led_indicate_not_provisioned(void);
void led_indicate_provisioned(void);
void led_off(void);

#endif
