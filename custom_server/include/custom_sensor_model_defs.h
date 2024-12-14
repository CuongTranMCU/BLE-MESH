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

#define BLE_MESH_DEVICE_NAME    "ESP-SERVER MESH 01" /*!< Device Advertising Name */ 
#define CID_ESP                 0x02E5                  /*!< Espressif Component ID */

//* Definicao dos IDs dos Models (Server e Client)
#define ESP_BLE_MESH_CUSTOM_SENSOR_MODEL_ID_SERVER      0x1414  /*!< Custom Server Model ID */
#define ESP_BLE_MESH_CUSTOM_SENSOR_MODEL_ID_CLIENT      0x1415  /*!< Custom Client Model ID */

//* Definimos os OPCODES das mensagens (igual no server)
#define ESP_BLE_MESH_CUSTOM_SENSOR_MODEL_OP_GET         ESP_BLE_MESH_MODEL_OP_3(0x00, CID_ESP)
#define ESP_BLE_MESH_CUSTOM_SENSOR_MODEL_OP_SET         ESP_BLE_MESH_MODEL_OP_3(0x01, CID_ESP)
#define ESP_BLE_MESH_CUSTOM_SENSOR_MODEL_OP_STATUS      ESP_BLE_MESH_MODEL_OP_3(0x02, CID_ESP)

/** 
 * @brief Device Main Data Structure
 */
typedef struct __attribute__((packed)) {
    char device_name[20];
    
    float temperature;   
    float CO;               
    float humidity;    
    uint8_t feedback; 
} model_sensor_data_t;


#endif  // __CUSTOM_SENSOR_MODEL_DEFS_H__