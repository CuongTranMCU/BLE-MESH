#ifndef __MQTT_H
#define __MQTT_H

#include "mqtt_client.h"
#include "custom_sensor_model_defs.h"

#include <stdio.h>
#include <cJSON.h>
#include <esp_log.h>

typedef void (*mqtt_data_pt_t)(char *data, uint16_t length);

void mqtt_app_start(const char *uri, uint32_t port, const char *username, const char *password);
void mqtt_data_pt_set_callback(void *cb);
void mqtt_data_publish_callback(char *topic, char *data, int length);
esp_mqtt_client_handle_t mqtt_get_global_client(void);

cJSON *convert_model_sensor_to_json(model_sensor_data_t *received_data, int rssi);
control_sensor_model_t convert_json_to_control_model_sensor(char *data);

#endif