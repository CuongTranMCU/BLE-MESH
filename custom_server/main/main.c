
#include <sdkconfig.h>
#include "nvs_flash.h"

#include "esp_log.h"

#include "mesh_device_app.h"

#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "DHT22.h"
#include "MQ7.h"
#include "board.h"
static const char* TAG = "MESH-SERVER-EXAMPLE";
esp_adc_cal_characteristics_t *adc_chars; // MQ7
QueueHandle_t ble_mesh_received_data_queue = NULL;
// QueueHandle_t sensor_data_queue = NULL;
// static void read_sensor_data(void* arg)
// {
//     while (1)
//     {
//         int temp = DHT11_read().temperature;
//         int hum = DHT11_read().humidity;
//          model_sensor_data_t sensor_data = {
//             .temperature = temp,
//             .humidity = hum,
//         };
//          printf("\n Temp: %f , Hum%f",sensor_data.temperature,sensor_data.humidity );
//         xQueueSendToBack(sensor_data_queue, &sensor_data, portMAX_DELAY);
//         vTaskDelay(5000 / portTICK_PERIOD_MS);

//     }

// }

static void read_received_items(void *arg) {
    ESP_LOGI(TAG, "Task initializing..");

    model_sensor_data_t _received_data;

    while (1) {
        vTaskDelay(500 / portTICK_PERIOD_MS);
        // ble_mesh_received_data_queue : muốn nhận dữ liệu : truyền đi
        // received_data: lưu trữ dữ liệu nhận được.
        if (xQueueReceive(ble_mesh_received_data_queue, &_received_data, 1000 / portTICK_PERIOD_MS) == pdPASS) {
            ESP_LOGI(TAG, "    Device Name: %s", _received_data.device_name);
            ESP_LOGI(TAG, "    Temperature: %f", _received_data.temperature);
            ESP_LOGI(TAG, "    CO         : %f", _received_data.CO);
            ESP_LOGI(TAG, "    Humidity   : %f", _received_data.humidity);
          
        }

        
    }   
} 

void app_main(void) {
    esp_err_t err;

    ESP_LOGI(TAG, "Initializing...");

    ble_mesh_received_data_queue = xQueueCreate(5, sizeof(model_sensor_data_t));
    // sensor_data_queue = xQueueCreate(1, sizeof(model_sensor_data_t));
    err = nvs_flash_init();
    if (err == ESP_ERR_NVS_NO_FREE_PAGES) {
        ESP_ERROR_CHECK(nvs_flash_erase());
        err = nvs_flash_init();
    }
    ESP_ERROR_CHECK(err);
    // HUMIDITY, TEMPERATURE
    setDHTgpio(GPIO_NUM_5);
    ESP_LOGI(TAG, "Starting DHT Task\n\n");
    Init_MQ7();
    err = ble_mesh_device_init();
    board_init();
    if (err) {
        ESP_LOGE(TAG, "Bluetooth mesh init failed (err 0x%06x)", err);
    }

    xTaskCreate(read_received_items, "Read queue task", 2048 * 2, (void *)0, 20, NULL);
    // xTaskCreate(read_sensor_data, "read_sensor_data", 2048 * 2, (void *)0, 20, NULL);

}