
#include <sdkconfig.h>
#include "nvs_flash.h"

#include "esp_log.h"

#include "mesh_device_app.h"

#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

#include "DHT22.h"
#include "board.h"
#include "MP2.h"
#include "Flame.h"
static const char *TAG = "MESH-SERVER-EXAMPLE";
static const char *MP2 = "MP2";
static const char *FLAME = "FLAME-SENSOR";
#define BUZZER_PIN 21
QueueHandle_t ble_mesh_received_data_queue = NULL;
QueueHandle_t received_data_from_sensor_queue = NULL;

static void read_received_items(void *arg)
{
    ESP_LOGI(TAG, "Task initializing...");

    model_sensor_data_t _received_data;

    while (1)
    {
        vTaskDelay(500 / portTICK_PERIOD_MS);

        if (xQueueReceive(ble_mesh_received_data_queue, &_received_data, 1000 / portTICK_PERIOD_MS) == pdPASS)
        {
            ESP_LOGI(TAG, "    Device Name: %s", _received_data.device_name);
            ESP_LOGI(TAG, "    Temperature: %f", _received_data.temperature);
            ESP_LOGI(TAG, "    Humidity   : %f", _received_data.humidity);
            ESP_LOGI(TAG, "    Smoke      : %f", _received_data.smoke);

        }
    }
}
static void flame_detected_callback(void)
{
    static bool last_state = false;
    bool current_state = flame_sensor_read();
    
    if (current_state != last_state) {
        if (current_state) {
            ESP_LOGW(TAG, "🔥 FLAME DETECTED! 🔥");
        } else {
            ESP_LOGI(TAG, "No flame detected");
        }
        last_state = current_state;
    }
}
static void read_data_from_sensors(void *arg)
{
    model_sensor_data_t _received_data;
    while (1)
    {
        ESP_LOGI(TAG, "Task initializing...");

        int ret = readDHT();
        errorHandler(ret);
        float hum = getHumidity();
        float temp = getTemperature();
        float smokePpm = MP2_GetSmokePPM();
        bool flame_detected = flame_sensor_read();
  
        _received_data.temperature = temp;
        _received_data.humidity = hum;
        _received_data.smoke = smokePpm;
        _received_data.isFlame = flame_detected;
        ESP_LOGI(TAG, "    Temperature: %f", _received_data.temperature);
        ESP_LOGI(TAG, "    Humidity   : %f", _received_data.humidity);
        ESP_LOGI(TAG, "    Smoke      : %f ppm", smokePpm);
        if (flame_detected) {
            ESP_LOGW(FLAME, "Flame detected (polling)");
        }
        else {
            ESP_LOGI(FLAME, "No Flame");
        }
        xQueueSendToBack(received_data_from_sensor_queue, &_received_data, portMAX_DELAY);
        vTaskDelay(5000 / portTICK_PERIOD_MS);
    }
}
void app_main(void)
{
    esp_err_t err;

    ESP_LOGI(TAG, "Initializing...");
    gpio_config_t io_conf;

    // Configure BUZZER  pin as output
    io_conf.intr_type = GPIO_INTR_DISABLE;
    io_conf.mode = GPIO_MODE_OUTPUT;
    io_conf.pin_bit_mask = (1ULL << BUZZER_PIN);
    io_conf.pull_down_en = GPIO_PULLDOWN_ENABLE;
    io_conf.pull_up_en = GPIO_PULLUP_DISABLE;
    gpio_config(&io_conf);
    gpio_set_direction(BUZZER_PIN, GPIO_MODE_OUTPUT);
    gpio_set_level(BUZZER_PIN, 0);

    ble_mesh_received_data_queue = xQueueCreate(5, sizeof(model_sensor_data_t));
    received_data_from_sensor_queue = xQueueCreate(1, sizeof(model_sensor_data_t));

    err = nvs_flash_init();
    if (err == ESP_ERR_NVS_NO_FREE_PAGES)
    {
        ESP_ERROR_CHECK(nvs_flash_erase());
        err = nvs_flash_init();
    }
    ESP_ERROR_CHECK(err);
    flame_sensor_init();
    ESP_ERROR_CHECK(flame_sensor_register_callback(flame_detected_callback));
    ESP_ERROR_CHECK(flame_sensor_enable_interrupt(true));
    // HUMIDITY, TEMPERATURE
    setDHTgpio(GPIO_NUM_2);
    ESP_LOGI(TAG, "Starting DHT Task\n\n");
    // SMOKE
    Init_MP2();
    ESP_LOGI(TAG, "Starting MP2 Task\n\n");

    board_init();

    err = ble_mesh_device_init();
    if (err)
    {
        ESP_LOGE(TAG, "Bluetooth mesh init failed (err 0x%06x)", err);
    }

    xTaskCreate(read_received_items, "Read queue task", 2048 * 2, (void *)0, 20, NULL); 
    xTaskCreate(read_data_from_sensors, "Read queue dht22 task", 2048 * 2, (void *)0, 20, NULL);
}