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

#include "esp_ble_mesh_common_api.h"
#include "esp_ble_mesh_provisioning_api.h"
#include "esp_ble_mesh_networking_api.h"
#include "esp_ble_mesh_config_model_api.h"
#include "esp_ble_mesh_generic_model_api.h"

#include "custom_sensor_model_defs.h"

//! Ver onde colocar essa fila
#include "freertos/queue.h"

extern QueueHandle_t ble_mesh_received_data_queue;
extern QueueHandle_t received_data_from_sensor_queue;

/**
 * @brief Initializes BLE Mesh stack, initializing Models and it's callback functions
 *
 */
esp_err_t ble_mesh_device_init_server(void);

bool is_server_provisioned(void);
void server_send_to_client(model_sensor_data_t server_model_state);
static void parse_received_data(esp_ble_mesh_model_cb_param_t *recv_param, model_sensor_data_t *parsed_data);
static void get_data_from_sensors();
void send_heartbeat_from_server(uint8_t count_log, uint8_t period_log);
#endif // __MESH_SERVER_H__