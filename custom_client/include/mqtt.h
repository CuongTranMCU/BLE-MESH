#ifndef __MQTT_H
#define __MQTT_H

#include "esp_log.h"
#include "mqtt_client.h"

typedef void (*mqtt_data_pt_t)(uint8_t *data, uint16_t length);

void mqtt_app_start(void);
void mqtt_data_pt_set_callback(void *cb);
void mqtt_data_publish_callback(esp_mqtt_client_handle_t client, char *data)

#endif