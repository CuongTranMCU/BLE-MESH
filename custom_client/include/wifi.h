#ifndef __WIFI_H__
#define __WIFI_H__

#include <string.h>
#include <stdlib.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/event_groups.h"
#include "esp_wifi.h"
#include "esp_wpa2.h"
#include "esp_event.h"
#include "esp_log.h"
#include "esp_system.h"
#include "nvs_flash.h"
#include "esp_netif.h"
#include "esp_smartconfig.h"

#include "mqtt.h"
#include "mesh_device_app.h"
/* Signal Wi-Fi events on this event-group */

#define MAX_RETRY 3
static void event_handler(void *arg, esp_event_base_t event_base,
                          int32_t event_id, void *event_data);

static void initialise_wifi(void);
static void smartconfig_example_task(void *parm);
esp_err_t get_wifi_configuration();
void check_wifi_connection();
void wifi_init();
void deinitialise_wifi();
void wifi_clear_config();
void mqtt_app_stop(void);

#endif // __WIFI_H__