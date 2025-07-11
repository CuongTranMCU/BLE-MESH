
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
#include "mesh_server.h"
// #include "esp_sleep.h"
extern model_sensor_data_t _server_model_state;
static const char *TAG = "MESH-SERVER-EXAMPLE";
static const char *MP2 = "MP2";
static const char *FLAME = "FLAME-SENSOR";
#define BUZZER_PIN 21
#define FLAME_SENSOR_GPIO GPIO_NUM_10  // Change this to your GPIO pin

QueueHandle_t receive_data_control_queue = NULL;
QueueHandle_t received_data_from_sensor_queue = NULL;
static flame_sensor_handle_t handle;
static bool alarmEnable = true;
static void read_received_items(void *arg)
{
    ESP_LOGI(TAG, "Task initializing...");

    model_control_data_t _received_data;
    int count = 0;
    while (1)
    {
        vTaskDelay(1000 / portTICK_PERIOD_MS);
        if (xQueueReceive(receive_data_control_queue, &_received_data, 1000 / portTICK_PERIOD_MS) == pdPASS)
        {
            ESP_LOGI(TAG, "Device Name: %s", _received_data.device_name);
            ESP_LOGI(TAG, "Mesh address = %02x", _received_data.mesh_addr);
            ESP_LOGI(TAG, "Buzzer       = %d", _received_data.buzzerStatus);
            ESP_LOGI(TAG, "LED RED      = %d", _received_data.ledStatus[0]);
            ESP_LOGI(TAG, "LED GREEN    = %d", _received_data.ledStatus[1]);
            ESP_LOGI(TAG, "LED BLUE     = %d", _received_data.ledStatus[2]);
            // Disable Alarm
            alarmEnable = false;
            // Set BUZZER and LEDs
            led_off();
            gpio_set_level(BUZZER_PIN, _received_data.buzzerStatus);
            gpio_set_level(LED_RED_GPIO, !_received_data.ledStatus[0]);
            gpio_set_level(LED_GREEN_GPIO, !_received_data.ledStatus[1]);
            gpio_set_level(LED_BLUE_GPIO, !_received_data.ledStatus[2]);
            // Check actual GPIO levels against received data
            bool buzzer_actual = gpio_get_level(BUZZER_PIN);
            bool led_actual[3] = {
                gpio_get_level(LED_RED_GPIO),
                gpio_get_level(LED_GREEN_GPIO),
                gpio_get_level(LED_BLUE_GPIO)
            };
            // Set error flags if there's a mismatch
            _received_data.buzzerError = (buzzer_actual != _received_data.buzzerStatus);
            _received_data.ledError = (led_actual[0] != _received_data.ledStatus[0] ||
                                      led_actual[1] != _received_data.ledStatus[1] ||
                                      led_actual[2] != _received_data.ledStatus[2]);
            if (_received_data.buzzerError || _received_data.ledError) {
                ESP_LOGW(TAG, "Error in received control data: Buzzer Error: %d, LED Error: %d",
                         _received_data.buzzerError, _received_data.ledError);
                send_control_signal_from_sensors(buzzer_actual,led_actual,_received_data.buzzerError, _received_data.ledError);
            } else {
                ESP_LOGI(TAG, "Control data received successfully with no errors.");
            }
        }
        else
        {
            if (count == 300)
            {
                ESP_LOGI(TAG, "No data received from receive_data_control_queue for 5 minutes, resetting alarmEnable to true.");
                alarmEnable = true; // Reset alarmEnable after 5 minutes
                count = 0; // Reset count
            }
            else
            {
                ESP_LOGW(TAG, "No data received from receive_data_control_queue");
            }
        }
        count++;
    }
}

char* check_fire_conditions(model_sensor_data_t *state) {
    if (state->temperature > 45.0f) {
        return "Big Fire";
    }
    else if (state->isFlame || state->temperature > 37.0f) {
        return "Fire";
    }
    else if (state->smoke >= 400.0f) {
        return "Potential Fire";
    }
    else {
        return "No Fire";
    }
}
// Fixed alarm task for continuous alarming
static void alarm_task(model_sensor_data_t _server_model_state) {
        // Using string comparisons instead of switch statement
        if (strcmp(_server_model_state.feedback, "Big Fire") == 0 && alarmEnable == true) {
            gpio_set_level(BUZZER_PIN, 1);
            led_off();
            gpio_set_level(LED_BLUE_GPIO, 0);
            ESP_LOGW("ALARM:", "Big Fire detected! Activating alarm.");
        }
        else if (strcmp(_server_model_state.feedback, "Fire") == 0 && alarmEnable == true) {
            gpio_set_level(BUZZER_PIN, 1);
            led_off();
            gpio_set_level(LED_RED_GPIO, 0);
            ESP_LOGW("ALARM:", "Fire detected! Activating alarm.");

        }
        else if (strcmp(_server_model_state.feedback, "Potential Fire") == 0 && alarmEnable == true) {
            led_off();
            gpio_set_level(LED_GREEN_GPIO, 0);
            ESP_LOGW("ALARM:", "Potential Fire detected! Activating alarm.");
        }
        else if (strcmp(_server_model_state.feedback, "No Fire") == 0 && alarmEnable == true) {
            led_off();
            gpio_set_level(BUZZER_PIN, 0);
            ESP_LOGI("ALARM:", "No Fire detected! Alarm is off.");
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
        if (smokePpm > 2000 )
        {
            smokePpm = 98.0f;
        }
        _received_data.temperature = temp;
        _received_data.humidity = hum;
        _received_data.smoke = smokePpm;
        ESP_LOGI(TAG, "    Temperature: %.2f", _received_data.temperature);
        ESP_LOGI(TAG, "    Humidity   : %.2f", _received_data.humidity);
        ESP_LOGI(TAG, "    Smoke      : %.2f ppm", smokePpm);

        if (flame_sensor_read(&handle, &flame_detected) == ESP_OK) {
            printf("Flame %s\n", flame_detected ? "DETECTED!" : "not detected");
            _received_data.isFlame = flame_detected;
        } else {
            printf("Error reading flame sensor\n");
        }
        strcpy(_received_data.feedback,check_fire_conditions(&_received_data));
        alarm_task(_received_data);
        xQueueSendToBack(received_data_from_sensor_queue, &_received_data, portMAX_DELAY);
        send_data_from_sensors();
        if (is_server_sent_init_control() == false)
        {
            bool ledStatus[3];
            ledStatus[0] = gpio_get_level(LED_RED_GPIO); 
            ledStatus[1] = gpio_get_level(LED_GREEN_GPIO);
            ledStatus[2] = gpio_get_level(LED_BLUE_GPIO);
            bool buzzerStatus = gpio_get_level(BUZZER_PIN);
            send_control_signal_from_sensors(buzzerStatus, ledStatus,false,false);
        }
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
    receive_data_control_queue = xQueueCreate(1, sizeof(model_control_data_t));
    received_data_from_sensor_queue = xQueueCreate(1, sizeof(model_sensor_data_t));

    err = nvs_flash_init();
    if (err == ESP_ERR_NVS_NO_FREE_PAGES)
    {
        ESP_ERROR_CHECK(nvs_flash_erase());
        err = nvs_flash_init();
    }
    ESP_ERROR_CHECK(err);
    board_init();
    err = ble_mesh_device_init();
    if (err)
    {
        ESP_LOGE(TAG, "Bluetooth mesh init failed (err 0x%06x)", err);
    }
    // HUMIDITY, TEMPERATURE
    setDHTgpio(GPIO_NUM_2);
    ESP_LOGI(TAG, "Starting DHT Task\n\n");
    // FLAME
    // Configure flame sensor
    flame_sensor_config_t config = {
        .gpio_pin = FLAME_SENSOR_GPIO
    };
    // Initialize flame sensor
    ESP_ERROR_CHECK(flame_sensor_init(&config, &handle));
    // SMOKE
    Init_MP2();
    ESP_LOGI(TAG, "Starting MP2 Task\n\n");
    xTaskCreate(read_received_items, "ead control queue task", 2048 * 2, (void *)0, 20, NULL); 
    xTaskCreate(read_data_from_sensors, "Read sensor task", 2048 * 2, (void *)0, 20, NULL);

}