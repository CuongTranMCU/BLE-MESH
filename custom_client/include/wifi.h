#ifndef __WIFI_H__
#define __WIFI_H__

#include <stdint.h>
#include <stdio.h>
#include <stddef.h>
#include <string.h>
#include "esp_wifi.h"
#include "esp_system.h"
#include "nvs_flash.h"
#include "esp_event.h"
#include "esp_netif.h"

#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/semphr.h"
#include "freertos/queue.h"

#include "lwip/sockets.h"
#include "lwip/dns.h"
#include "lwip/netdb.h"
#include "mqtt.h"


#define EXAMPLE_ESP_WIFI_SSID "KTMT - SinhVien"
#define EXAMPLE_ESP_WIFI_PASS "sinhvien"
#define EXAMPLE_ESP_MAXIMUM_RETRY 5

void wifi_event_handler(void *arg, esp_event_base_t event_base,
                        int32_t event_id, void *event_data);
void wifi_init_sta(void);

#endif // __WIFI_H__