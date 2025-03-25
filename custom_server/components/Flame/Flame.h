// flame.h
#ifndef _FLAME_SENSOR_H_
#define _FLAME_SENSOR_H_

#include "driver/gpio.h"
#include "esp_err.h"

typedef struct {
    gpio_num_t gpio_pin;  // GPIO pin number where flame sensor is connected
} flame_sensor_config_t;

typedef struct {
    gpio_num_t gpio_pin;
} flame_sensor_handle_t;

/**
 * @brief Initialize flame sensor
 * @param config Pointer to flame sensor configuration
 * @param handle Pointer to flame sensor handle
 * @return ESP_OK on success
 */
esp_err_t flame_sensor_init(const flame_sensor_config_t *config, flame_sensor_handle_t *handle);

/**
 * @brief Deinitialize flame sensor
 * @param handle Pointer to flame sensor handle
 * @return ESP_OK on success
 */
esp_err_t flame_sensor_deinit(flame_sensor_handle_t *handle);

/**
 * @brief Read flame sensor state
 * @param handle Pointer to flame sensor handle
 * @param flame_detected Pointer to store result (true if flame detected, false otherwise)
 * @return ESP_OK on success
 */
esp_err_t flame_sensor_read(flame_sensor_handle_t *handle, bool *flame_detected);

#endif // _FLAME_SENSOR_H_