#include "Flame.h"
#include "driver/gpio.h"
#include "esp_log.h"

static const char *TAG = "FLAME_SENSOR";
static flame_callback_t flame_callback = NULL;

// GPIO interrupt handler
static void IRAM_ATTR gpio_isr_handler(void* arg)
{
    if (flame_callback) {
        flame_callback();
    }
}

esp_err_t flame_sensor_init(void)
{
    gpio_config_t io_conf = {
        .pin_bit_mask = (1ULL << FLAME_SENSOR_GPIO),
        .mode = GPIO_MODE_INPUT,
        .pull_up_en = GPIO_PULLUP_DISABLE,    // Enable pull-up
        .pull_down_en = GPIO_PULLDOWN_DISABLE,
        .intr_type = GPIO_INTR_ANYEDGE,      // Enable interrupt on both edges
    };
    
    esp_err_t ret = gpio_config(&io_conf);
    if (ret != ESP_OK) {
        ESP_LOGI(TAG, "Error configuring GPIO: %d", ret);
        return ret;
    }

    // Install GPIO ISR service
    ret = gpio_install_isr_service(0);
    if (ret != ESP_OK && ret != ESP_ERR_INVALID_STATE) {
        ESP_LOGI(TAG, "Error installing GPIO ISR service: %d", ret);
        return ret;
    }

    ESP_LOGI(TAG, "Flame sensor initialized on GPIO %d", FLAME_SENSOR_GPIO);
    return ESP_OK;
}

bool flame_sensor_read(void)
{
    // Returns true if flame is detected (logic low due to sensor characteristics)
    return gpio_get_level(FLAME_SENSOR_GPIO);
}

esp_err_t flame_sensor_register_callback(flame_callback_t callback)
{
    if (callback == NULL) {
        return ESP_ERR_INVALID_ARG;
    }
    flame_callback = callback;
    return ESP_OK;
}

esp_err_t flame_sensor_enable_interrupt(bool enable)
{
    if (enable) {
        return gpio_isr_handler_add(FLAME_SENSOR_GPIO, gpio_isr_handler, NULL);
    } else {
        return gpio_isr_handler_remove(FLAME_SENSOR_GPIO);
    }
}