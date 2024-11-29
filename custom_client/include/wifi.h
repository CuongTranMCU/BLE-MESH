#ifndef __WIFI_H__
#define __WIFI_H__

#include <stdio.h>
#include <string.h>

#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include <freertos/event_groups.h>

#include <esp_log.h>
#include <esp_wifi.h>
#include <esp_event.h>
#include <nvs_flash.h>
#include "esp_timer.h"

#include <wifi_provisioning/manager.h>

#ifdef CONFIG_EXAMPLE_PROV_TRANSPORT_SOFTAP
#include <wifi_provisioning/scheme_softap.h>
#endif /* CONFIG_EXAMPLE_PROV_TRANSPORT_SOFTAP */

#include "mqtt.h"
#include "mesh_device_app.h"
/* Signal Wi-Fi events on this event-group */

#define PROV_TRANSPORT_SOFTAP "softap"

extern EventGroupHandle_t wifi_event_group;

extern const int WIFI_CONNECTED_EVENT;

void event_handler(void *arg, esp_event_base_t event_base,
                   int32_t event_id, void *event_data);
void wifi_init_sta(void);
void get_device_service_name(char *service_name, size_t max);

esp_err_t custom_prov_data_handler(uint32_t session_id, const uint8_t *inbuf, ssize_t inlen,
                                   uint8_t **outbuf, ssize_t *outlen, void *priv_data);
void wifi_prov_print_qr(const char *name, const char *username, const char *pop, const char *transport);

void wifi_init(void);

#endif // __WIFI_H__