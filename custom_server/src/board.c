/* board.c - Board-specific hooks */

/*
 * SPDX-FileCopyrightText: 2017 Intel Corporation
 * SPDX-FileContributor: 2018-2021 Espressif Systems (Shanghai) CO LTD
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#include "board.h"

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

    ESP_LOGI(BOARD_TAG, "Button released");

    if (state == LONG_PRESSED)
    {
        ESP_LOGI(BOARD_TAG, "Long press detected");

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
    ESP_LOGI(BOARD_TAG, "Button pressed");
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
        }
        else if (count == 3)
        {
            ESP_LOGI("BUTTON", "Triple click detected");
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
