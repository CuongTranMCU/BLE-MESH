
#include <sdkconfig.h>
#include "nvs_flash.h"

#include "esp_log.h"

#include "mesh_device_app.h"

#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

#include "DHT22.h"
#include "MQ7.h"
#include "board.h"

static const char *TAG = "MESH-SERVER-EXAMPLE";

esp_adc_cal_characteristics_t *adc_chars; // MQ7

QueueHandle_t ble_mesh_received_data_queue = NULL;
QueueHandle_t received_data_from_sensor_queue = NULL;

static void read_received_items(void *arg)
{
    ESP_LOGI(TAG, "Task initializing..");

    model_sensor_data_t _received_data;

    while (1)
    {
        vTaskDelay(500 / portTICK_PERIOD_MS);

        if (xQueueReceive(ble_mesh_received_data_queue, &_received_data, 1000 / portTICK_PERIOD_MS) == pdPASS)
        {
            ESP_LOGI(TAG, "    Device Name: %s", _received_data.device_name);
            ESP_LOGI(TAG, "    Temperature: %f", _received_data.temperature);
            ESP_LOGI(TAG, "    CO         : %f", _received_data.CO);
            ESP_LOGI(TAG, "    Humidity   : %f", _received_data.humidity);
        }
    }
}

static void read_data_from_sensors(void *arg)
{
    model_sensor_data_t _received_data;
    while (1)
    {
        ESP_LOGI(TAG, "Task initializing..");

        // int ret = readDHT();
        // errorHandler(ret);
        // float CO = MQ7_GetPPM();
        // float hum = getHumidity();
        // float temp = getTemperature();

        _received_data.temperature = 5.6;
        _received_data.humidity = 4.2;
        _received_data.CO = 30.7;

        xQueueSendToBack(received_data_from_sensor_queue, &_received_data, portMAX_DELAY);
        vTaskDelay(5000 / portTICK_PERIOD_MS);
    }
}

void app_main(void)
{
    esp_err_t err;

    ESP_LOGI(TAG, "Initializing...");

    ble_mesh_received_data_queue = xQueueCreate(5, sizeof(model_sensor_data_t));
    received_data_from_sensor_queue = xQueueCreate(1, sizeof(model_sensor_data_t));

    err = nvs_flash_init();
    if (err == ESP_ERR_NVS_NO_FREE_PAGES)
    {
        ESP_ERROR_CHECK(nvs_flash_erase());
        err = nvs_flash_init();
    }
    ESP_ERROR_CHECK(err);

    // HUMIDITY, TEMPERATURE
    setDHTgpio(GPIO_NUM_5);
    ESP_LOGI(TAG, "Starting DHT Task\n\n");

    Init_MQ7();
    board_init();

    err = ble_mesh_device_init();
    if (err)
    {
        ESP_LOGE(TAG, "Bluetooth mesh init failed (err 0x%06x)", err);
    }

    xTaskCreate(read_received_items, "Read queue task", 2048 * 2, (void *)0, 20, NULL);
    xTaskCreate(read_data_from_sensors, "Read queue dht11 task", 2048 * 2, (void *)0, 20, NULL);
}