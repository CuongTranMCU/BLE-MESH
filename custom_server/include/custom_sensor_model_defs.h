/**
 * @file custom_sensor_model_defs.h
 *
 * @brief
 *
 * @author
 *
 * @date  11/2020
 */

#ifndef __CUSTOM_SENSOR_MODEL_DEFS_H__
#define __CUSTOM_SENSOR_MODEL_DEFS_H__

#include <stdio.h>

#include "sdkconfig.h"

#include "esp_ble_mesh_common_api.h"

#define BLE_MESH_DEVICE_NAME "ESP-SERVER MESH 01" /*!< Device Advertising Name */
#define CID_ESP 0x02E5                            /*!< Espressif Component ID */

//* Definicao dos IDs dos Models (Server e Client)
#define ESP_BLE_MESH_CUSTOM_SENSOR_MODEL_ID_SERVER 0x1414 /*!< Custom Server Model ID */
#define ESP_BLE_MESH_CUSTOM_SENSOR_MODEL_ID_CLIENT 0x1415 /*!< Custom Client Model ID */

//* Definimos os OPCODES das mensagens (igual no server)
#define ESP_BLE_MESH_CUSTOM_SENSOR_MODEL_OP_GET ESP_BLE_MESH_MODEL_OP_3(0x00, CID_ESP)
#define ESP_BLE_MESH_CUSTOM_SENSOR_MODEL_OP_SET ESP_BLE_MESH_MODEL_OP_3(0x01, CID_ESP)
#define ESP_BLE_MESH_CUSTOM_SENSOR_MODEL_OP_STATUS ESP_BLE_MESH_MODEL_OP_3(0x02, CID_ESP)

#define ESP_BLE_MESH_GROUP_PUB_ADDR 0xC000
#define ESP_BLE_MESH_GROUP_GW_SUB_ADDR 0xC001
#define ESP_BLE_MESH_ADDR_ALL_NODES 0xFFFF

/**
 * @brief Device Main Data Structure
 */

typedef enum
{
    MSG_TYPE_SENSOR = 0x01,
    MSG_TYPE_CONTROL = 0x02,
} message_type_t;

typedef struct __attribute__((packed))
{
    char device_name[30];
    char mac_addr[13];
    uint16_t mesh_addr;
    float temperature;
    float humidity;
    float smoke;
    bool isFlame;
    char feedback[20];
} model_sensor_data_t;

typedef struct __attribute__((packed))
{
    char device_name[30];
    uint16_t mesh_addr;
    bool buzzer;
    int led;
} model_control_data_t;

#endif // __CUSTOM_SENSOR_MODEL_DEFS_H__