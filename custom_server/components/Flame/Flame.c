#include "Flame.h"
#include "esp_log.h"
static const char *TAG = "FLAME_SENSOR";

esp_err_t flame_sensor_init(const flame_sensor_config_t *config, flame_sensor_handle_t *handle) {
    esp_err_t ret = ESP_OK;

    if (config == NULL || handle == NULL) {
        return ESP_ERR_INVALID_ARG;
    }

    gpio_config_t io_conf = {
        .pin_bit_mask = (1ULL << config->gpio_pin),
        .mode = GPIO_MODE_INPUT,
        .pull_up_en = GPIO_PULLUP_DISABLE,  // Enable internal pull-up
        .pull_down_en = GPIO_PULLDOWN_DISABLE, // Disable pull-down
        .intr_type = GPIO_INTR_DISABLE
    };

    ret = gpio_config(&io_conf);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "Failed to configure GPIO");
        return ret;
    }

    // Store GPIO pin in handle
    handle->gpio_pin = config->gpio_pin;
    
    // Add initial reading for diagnostic purposes
    int initial_level = gpio_get_level(config->gpio_pin);
    ESP_LOGI(TAG, "Flame sensor initialized on GPIO%d with initial level: %d", 
             config->gpio_pin, initial_level);

    return ESP_OK;
}

esp_err_t flame_sensor_deinit(flame_sensor_handle_t *handle) {
    if (handle == NULL) {
        return ESP_ERR_INVALID_ARG;
    }

    // Reset GPIO configuration
    gpio_reset_pin(handle->gpio_pin);
    
    return ESP_OK;
}

esp_err_t flame_sensor_read(flame_sensor_handle_t *handle, bool *flame_detected) {
    if (handle == NULL || flame_detected == NULL) {
        return ESP_ERR_INVALID_ARG;
    }
    // Read GPIO level
    int level = gpio_get_level(handle->gpio_pin);
    *flame_detected = (level == 1);
    ESP_LOGD(TAG, "Flame sensor GPIO%d level: %d (Flame %s)", 
             handle->gpio_pin, level, *flame_detected ? "DETECTED" : "NOT DETECTED");
    return ESP_OK;
}
