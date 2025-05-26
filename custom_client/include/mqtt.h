#ifndef __MQTT_H
#define __MQTT_H

#include "mqtt_client.h"
#include "custom_sensor_model_defs.h"

#include <stdio.h>
#include <cJSON.h>
#include <esp_log.h>
#include "nvs_flash.h"
#include "nvs.h"

typedef struct
{
    char uri[40];
    uint32_t port;
    char username[12];
    char password[12];
} mqtt_config_t;

typedef void (*mqtt_data_pt_t)(char *data, uint16_t length);

void mqtt_app_start(const mqtt_config_t *config);
void mqtt_data_pt_set_callback(void *cb);
void mqtt_data_publish_callback(char *topic, char *data, int length);
esp_mqtt_client_handle_t mqtt_get_global_client(void);

esp_err_t save_mqtt_config(const mqtt_config_t *config);
esp_err_t load_mqtt_config(mqtt_config_t *config);

cJSON *convert_model_sensor_to_json(model_sensor_data_t *received_data);
cJSON *convert_model_control_to_json(model_control_data_t *received_data);

model_control_data_t *convert_json_to_control_model_list(const char *data, int *count);

#endif