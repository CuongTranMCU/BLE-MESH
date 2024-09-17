#ifndef __MQTT_H
#define __MQTT_H

#include "esp_log.h"
#include "mqtt_client.h"
#include "custom_sensor_model_defs.h"

#include <stdio.h>
#include <cJSON.h>

typedef void (*mqtt_data_pt_t)(char *data, uint16_t length);

void mqtt_app_start(void);
void mqtt_data_pt_set_callback(void *cb);
void mqtt_data_publish_callback(char *data,char * topic);
char *convert_model_sensor_to_json(model_sensor_data_t *received_data);
#endif