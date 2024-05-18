/**
 * @file mesh_client.h
 *
 * @brief
 *
 * @author
 *
 * @date  11/2020
 */

#ifndef __MESH_CLIENT_H__
#define __MESH_CLIENT_H__

#include <stdio.h>
#include <string.h>
#include <sdkconfig.h>

#include "esp_ble_mesh_common_api.h"
#include "esp_ble_mesh_provisioning_api.h"
#include "esp_ble_mesh_networking_api.h"
#include "esp_ble_mesh_config_model_api.h"
#include "esp_ble_mesh_generic_model_api.h"

#include "custom_sensor_model_defs.h"

#include "esp_log.h"

#include "esp_bt.h"
#include "esp_bt_main.h"
#include "esp_bt_device.h"
#include "esp_ble_mesh_defs.h"

#include <cJSON.h>
#include "wifi.h"

/**
 * @brief Initializes BLE Mesh stack, initializing Models and it's callback functions
 *
 */
esp_err_t ble_mesh_device_init_client(void);

/**
 * @brief Custom Sensor Client Model SET message that
 *        publishes data to ESP_BLE_MESH_GROUP_PUB_ADDR
 */
esp_err_t ble_mesh_custom_sensor_client_model_message_set(model_sensor_data_t set_data);

/**
 * @brief Custom Sensor Client Model GET message that
 *        publishes data to ESP_BLE_MESH_GROUP_PUB_ADDR
 *
 * @note  Received data will be available on Model Callback function
 */
esp_err_t ble_mesh_custom_sensor_client_model_message_get(uint16_t addr);

bool is_client_provisioned(void);
void mqtt_data_callback(char *data, uint16_t length);
#endif // __MESH_CLIENT_H__
