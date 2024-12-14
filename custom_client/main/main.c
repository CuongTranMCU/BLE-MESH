
#include <sdkconfig.h>
#include "nvs_flash.h"

#include "esp_log.h"

#include "mesh_device_app.h"
#include "board.h"

#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#define TAG "MAIN"

static uint8_t ticks = 0;
model_sensor_data_t device_sensor_data;

static void air_sensor_task(void *arg)
{
    ESP_LOGI(TAG, "SGP30 main task initializing...");

    // if (xSemaphoreTake(xSemaphore, portMAX_DELAY ) == pdTRUE ) {
    // sgp30_init(&main_sensor);
    // xSemaphoreGive(xSemaphore);
    // }

    // SGP30 needs to be read every 1s and sends TVOC = 400 14 times when initializing
    // for (int i = 0; i < 14; i++) {
    //     vTaskDelay(1000 / portTICK_RATE_MS);

    // if (xSemaphoreTake(xSemaphore, portMAX_DELAY ) == pdTRUE ) {
    // sgp30_IAQ_measure(&main_sensor);
    // xSemaphoreGive(xSemaphore);
    // }

    // ESP_LOGI(TAG, "SGP30 Calibrating... TVOC: %d,  eCO2: %d",  main_sensor.TVOC, main_sensor.eCO2);
    // }

    // Read initial baselines
    uint16_t eco2_baseline = 36, tvoc_baseline = 18;

    // if (xSemaphoreTake(xSemaphore, portMAX_DELAY ) == pdTRUE ) {
    // sgp30_get_IAQ_baseline(&main_sensor, &eco2_baseline, &tvoc_baseline);
    // xSemaphoreGive(xSemaphore);
    // }

    ESP_LOGI(TAG, "BASELINES - TVOC: %d,  eCO2: %d", tvoc_baseline, eco2_baseline);

    ESP_LOGI(TAG, "SGP30 main task is running...");
    while (1)
    {
        vTaskDelay(1000 / portTICK_PERIOD_MS);

        // if (xSemaphoreTake(xSemaphore, portMAX_DELAY ) == pdTRUE ) {
        // sgp30_IAQ_measure(&main_sensor);
        // xSemaphoreGive(xSemaphore);
        // }

        if ((ticks++ >= 5) && (is_client_provisioned()))
        {
            // if (ticks++ >= 5) {
            // ESP_LOGI(TAG, "TVOC: %d,  eCO2: %d", tvoc_baseline, eco2_baseline); // for set message
            // device_sensor_data.CO2 = eco2_baseline;
            // device_sensor_data.VOC = tvoc_baseline;
            // strcpy(device_sensor_data.device_name, "GW");

            // ble_mesh_custom_sensor_client_model_message_set(device_sensor_data);
            ble_mesh_custom_sensor_client_model_message_get(0);

            ticks = 0;
        }
    }
}

void app_main(void)
{
    esp_err_t err;

    ESP_LOGI(TAG, "Initializing...");
    err = nvs_flash_init();
    if (err == ESP_ERR_NVS_NO_FREE_PAGES)
    {
        ESP_ERROR_CHECK(nvs_flash_erase());
        err = nvs_flash_init();
    }
    ESP_ERROR_CHECK(err);
    board_init();
    wifi_init();

    err = ble_mesh_device_init();
    if (err)
    {
        ESP_LOGE(TAG, "Bluetooth mesh init failed (err %d)", err);
    }
    xTaskCreate(air_sensor_task, "air_sensor_main_task", 2048 * 2, (void *)0, 20, NULL);
}
