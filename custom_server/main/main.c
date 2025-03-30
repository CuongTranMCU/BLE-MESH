
#include <sdkconfig.h>
#include "nvs_flash.h"

#include "esp_log.h"

#include "mesh_device_app.h"

#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

#include "DHT22.h"
#include "board.h"
#include "Flame.h"
#include "MP2.h"

static const char *TAG = "MESH-SERVER-EXAMPLE";
static const char *MP2 = "MP2";
static const char *FLAME = "FLAME-SENSOR";

QueueHandle_t ble_mesh_received_data_queue = NULL;
QueueHandle_t received_data_from_sensor_queue = NULL;

#define BUZZER_PIN 21
#define FLAME_SENSOR_GPIO GPIO_NUM_10 // Change this to your GPIO pin

static flame_sensor_handle_t handle;

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
            ESP_LOGI(TAG, "    Smoke         : %f", _received_data.smoke);
        }
        else
        {
            ESP_LOGW(TAG, "No data received from ble_mesh_received_data_queue");
        }
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
        bool flame_detected;

        _received_data.temperature = temp;
        _received_data.humidity = hum;
        _received_data.smoke = smokePpm;
        _received_data.isFlame = _received_data.isFlame;

        ESP_LOGI(TAG, "    Temperature: %f", _received_data.temperature);
        ESP_LOGI(TAG, "    Humidity   : %f", _received_data.humidity);
        ESP_LOGI(TAG, "    Smoke      : %f", _received_data.smoke);

        if (flame_sensor_read(&handle, &flame_detected) == ESP_OK)
        {
            ESP_LOGI(TAG, "Flame %s", flame_detected ? "DETECTED!" : "not detected");
        }
        else
        {
            ESP_LOGI(TAG, "Flame %s", "Error reading flame sensor");
        }

        xQueueSendToBack(received_data_from_sensor_queue, &_received_data, portMAX_DELAY);
        get_data_from_sensors();
        vTaskDelay(1000 * 120 / portTICK_PERIOD_MS);
    }
}

void app_main(void)
{

    // Xem lại phần này
    ble_mesh_received_data_queue = xQueueCreate(5, sizeof(model_sensor_data_t));
    received_data_from_sensor_queue = xQueueCreate(5, sizeof(model_sensor_data_t));

    if (ble_mesh_received_data_queue == NULL || received_data_from_sensor_queue == NULL)
    {
        ESP_LOGE(TAG, "Failed to create queues");
        return;
    }

    esp_err_t err;

    gpio_config_t io_conf;
    gpio_config_t bio_conf;

    // Configure Buzzer pin as output
    io_conf.intr_type = GPIO_INTR_DISABLE;
    io_conf.mode = GPIO_MODE_OUTPUT;
    io_conf.pin_bit_mask = (1ULL << BUZZER_PIN);
    io_conf.pull_down_en = GPIO_PULLDOWN_ENABLE;
    io_conf.pull_up_en = GPIO_PULLUP_DISABLE;
    gpio_config(&io_conf);
    gpio_set_direction(BUZZER_PIN, GPIO_MODE_OUTPUT);
    gpio_set_level(BUZZER_PIN, 0);

    // Configure DHT22 pin as input
    setDHTgpio(GPIO_NUM_2);
    ESP_LOGI(TAG, "Starting DHT Task\n\n");

    // Configure Flame pin Analog as input
    bio_conf.intr_type = GPIO_INTR_DISABLE;
    bio_conf.mode = GPIO_MODE_INPUT;
    bio_conf.pin_bit_mask = (1ULL << 11);
    bio_conf.pull_down_en = GPIO_PULLDOWN_DISABLE;
    bio_conf.pull_up_en = GPIO_PULLUP_DISABLE;
    gpio_config(&bio_conf);

    // Configure Flame pin Digital as output
    flame_sensor_config_t config = {
        .gpio_pin = FLAME_SENSOR_GPIO,
    };

    ESP_LOGI(TAG, "Initializing...");

    err = nvs_flash_init();
    if (err == ESP_ERR_NVS_NO_FREE_PAGES)
    {
        ESP_ERROR_CHECK(nvs_flash_erase());
        err = nvs_flash_init();
    }
    ESP_ERROR_CHECK(err);

    ESP_ERROR_CHECK(flame_sensor_init(&config, &handle));

    // SMOKE
    Init_MP2();
    ESP_LOGI(TAG, "Starting MP2 Task\n\n");

    board_init();

    err = ble_mesh_device_init();
    if (err)
    {
        ESP_LOGE(TAG, "Bluetooth mesh init failed (err 0x%06x)", err);
    }

    //   xTaskCreate(read_received_items, "read_received_items", 4096, NULL, 5, NULL);
    xTaskCreate(read_data_from_sensors, "read_data_from_sensors", 4096, NULL, 5, NULL);
}