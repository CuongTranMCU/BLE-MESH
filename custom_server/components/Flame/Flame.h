#ifndef FLAME_SENSOR_H
#define FLAME_SENSOR_H

#include "esp_err.h"
#include <stdbool.h>
#include <stdio.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_log.h"
// Define GPIO pin for flame sensor
#define FLAME_SENSOR_GPIO 10  // Change this to your actual GPIO pin

// Initialize flame sensor
esp_err_t flame_sensor_init(void);

// Read flame sensor state
bool flame_sensor_read(void);

// Register callback for flame detection
typedef void (*flame_callback_t)(void);
esp_err_t flame_sensor_register_callback(flame_callback_t callback);

// Enable/disable flame detection interrupt
esp_err_t flame_sensor_enable_interrupt(bool enable);

#endif // FLAME_SENSOR_H