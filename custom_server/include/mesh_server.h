/**
 * @file mesh_server.h
 *
 * @brief
 *
 * @author
 *
 * @date  11/2020
 */

#ifndef __MESH_SERVER_H__
#define __MESH_SERVER_H__

#include <stdio.h>
#include <string.h>
#include <sdkconfig.h>
#include <inttypes.h>

#include "esp_ble_mesh_common_api.h"
#include "esp_ble_mesh_provisioning_api.h"
#include "esp_ble_mesh_networking_api.h"
#include "esp_ble_mesh_config_model_api.h"
#include "esp_ble_mesh_generic_model_api.h"
#include "custom_sensor_model_defs.h"

#include "esp_bt.h"
#include "esp_bt_main.h"
#include "esp_bt_device.h"
#include "esp_ble_mesh_defs.h"
#include "esp_ble_mesh_networking_api.h"
#include "esp_ble_mesh_local_data_operation_api.h"

#include "esp_log.h"
#include "esp_mac.h"
#include "freertos/queue.h"
#include "board.h"

extern QueueHandle_t ble_mesh_received_data_queue;
extern QueueHandle_t received_data_from_sensor_queue;

/**
 * @brief Initializes BLE Mesh stack, initializing Models and it's callback functions
 *
 */
esp_err_t ble_mesh_device_init_server(void);
void server_send_to_client(model_sensor_data_t server_model_state);
void get_data_from_sensors();
#endif // __MESH_SERVER_H__