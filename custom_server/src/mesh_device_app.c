#include "mesh_device_app.h"
#include "esp_log.h"
#include "sdkconfig.h"

#define TAG "MESH-DEVICE-APP"

esp_err_t ble_mesh_device_init(void)
{
    esp_err_t err = ESP_OK;

    err = ble_mesh_device_init_server();
    if (err)
    {
        ESP_LOGE(TAG, "Invalid Kconfig Device Type! Please reconfigure your project");
        return ESP_FAIL;
    }
    else
        return err;
}