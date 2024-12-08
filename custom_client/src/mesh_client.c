/**
 * @file mesh_client.c
 *
 * @brief
 *
 * @author
 *
 * @date  11/2020
 */

#include "mesh_client.h"

#define TAG "MESH_CLIENT"

/*******************************************
 ****** Private Variables Definitions ******
 *******************************************/

static uint8_t dev_uuid[16] = {0xdd, 0xdd}; /**< Device UUID */

static bool is_provisioning = false; /**<Provision flags> */

// Definicao do Configuration Server Model
static esp_ble_mesh_cfg_srv_t config_server = {
    .relay = ESP_BLE_MESH_RELAY_DISABLED,
    .beacon = ESP_BLE_MESH_BEACON_ENABLED,
#if defined(CONFIG_BLE_MESH_FRIEND)
    .friend_state = ESP_BLE_MESH_FRIEND_ENABLED,
#else
    .friend_state = ESP_BLE_MESH_FRIEND_NOT_SUPPORTED,
#endif
#if defined(CONFIG_BLE_MESH_GATT_PROXY_SERVER)
    .gatt_proxy = ESP_BLE_MESH_GATT_PROXY_ENABLED,
#else
    .gatt_proxy = ESP_BLE_MESH_GATT_PROXY_NOT_SUPPORTED,
#endif
    .default_ttl = 7,
    /* 3 transmissions with 20ms interval */
    .net_transmit = ESP_BLE_MESH_TRANSMIT(2, 20),
    .relay_retransmit = ESP_BLE_MESH_TRANSMIT(2, 20),
};

//* Definicao dos pares GET/STATUS e SET/STATUS(?)
static const esp_ble_mesh_client_op_pair_t custom_model_op_pair[] = {
    {ESP_BLE_MESH_CUSTOM_SENSOR_MODEL_OP_GET, ESP_BLE_MESH_CUSTOM_SENSOR_MODEL_OP_STATUS},
    // {ESP_BLE_MESH_CUSTOM_SENSOR_MODEL_OP_SET , ESP_BLE_MESH_CUSTOM_SENSOR_MODEL_OP_STATUS },
};

//* Definicao de fato dos opcodes aqui
static esp_ble_mesh_model_op_t custom_sensor_op[] = {
    ESP_BLE_MESH_MODEL_OP(ESP_BLE_MESH_CUSTOM_SENSOR_MODEL_OP_STATUS, 2),
    ESP_BLE_MESH_MODEL_OP_END,
};

//* Criacao do Client Model (com os opcode pair)
static esp_ble_mesh_client_t custom_sensor_client = {
    .op_pair_size = ARRAY_SIZE(custom_model_op_pair),
    .op_pair = custom_model_op_pair,
};

//! Verificar "Publication Context"
// Defind Addr
ESP_BLE_MESH_MODEL_PUB_DEFINE(custom_client_pub, 3, ROLE_NODE);
static esp_ble_mesh_model_t custom_models[] = {
    ESP_BLE_MESH_VENDOR_MODEL(CID_ESP, ESP_BLE_MESH_CUSTOM_SENSOR_MODEL_ID_CLIENT,
                              custom_sensor_op, &custom_client_pub, &custom_sensor_client),
};

//* Colocamos o Config Server Model aqui como root model
static esp_ble_mesh_model_t root_models[] = {
    ESP_BLE_MESH_MODEL_CFG_SRV(&config_server),
};

//* E na definicao do Element, juntamos os root models com os custom
static esp_ble_mesh_elem_t elements[] = {
    ESP_BLE_MESH_ELEMENT(0, root_models, custom_models),
};

//* Definicao da composicao geral do dispositivo
static esp_ble_mesh_comp_t composition = {
    .cid = CID_ESP,
    .elements = elements,
    .element_count = ARRAY_SIZE(elements),
};

//* Dados para o provisionamento
static esp_ble_mesh_prov_t provision = {
    .uuid = dev_uuid,
    .output_size = 0,
    .output_actions = 0,
};

/******************************************
 ****** Start Private Functions Prototypes ******
 ******************************************/

/**
 * @brief Called on provision complete success and stores Netkey Index
 *
 * @param  net_idx  Netkey index provisioned
 * @param  addr     Address given by the provisioner
 * @param  flags
 * @param  iv_index
 */
static void prov_complete(uint16_t net_idx, uint16_t addr, uint8_t flags, uint32_t iv_index);

/**
 * @brief Provisioning routine callback function
 *
 * @param  event  Provision event
 * @param  param   Pointer to Provision parameter
 */
static void ble_mesh_provisioning_cb(esp_ble_mesh_prov_cb_event_t event,
                                     esp_ble_mesh_prov_cb_param_t *param);

/**
 * @brief Configuration Server Model callback function
 *
 * @param  event  Config Server Model event
 * @param  param   Pointer to Config Server Model parameter
 */
static void ble_mesh_config_server_cb(esp_ble_mesh_cfg_server_cb_event_t event,
                                      esp_ble_mesh_cfg_server_cb_param_t *param);

/**
 * @brief Custom Sensor Client Model callback function
 *
 * @param  event  Sensor Client Model event
 * @param  param   Pointer to Sensor Client Model parameter
 */
static void ble_mesh_custom_sensor_client_model_cb(esp_ble_mesh_model_cb_event_t event,
                                                   esp_ble_mesh_model_cb_param_t *param);

/**
 * @brief Parses received Sensor Model raw data and stores it on appropriate structure
 *
 * @param  recv_param   Pointer to model callback received parameter
 * @param  parsed_data  Pointer to where the parsed data will be stored
 */

bool is_client_provisioned(void);

static void parse_received_data(esp_ble_mesh_model_cb_param_t *recv_param, model_sensor_data_t *parsed_data);

esp_err_t ble_mesh_custom_sensor_client_model_message_set(model_sensor_data_t set_data);

esp_err_t ble_mesh_custom_sensor_client_model_message_get(uint16_t addr);

static void configure_heartbeat_subscription(uint16_t src_addr, uint16_t dst_addr, uint8_t period_log);

void mqtt_data_callback(char *data, uint16_t length);

/******************************************
 ****** End Private Functions Prototypes ******
 ******************************************/

/*******************************************
 ****** Private Functions Definitions ******
 *******************************************/

bool is_client_provisioned(void)
{
    return is_provisioning;
}

static void configure_heartbeat_subscription(uint16_t src_addr, uint16_t dst_addr, uint8_t period_log)
{
    esp_ble_mesh_cfg_client_set_state_t set_state = {
        .heartbeat_sub_set = {
            .src = src_addr,      // Địa chỉ nguồn (Server gửi Heartbeat)
            .dst = dst_addr,      // Địa chỉ đích (Client nhận Heartbeat)
            .period = period_log, // Thời gian nhận (log base 2)
        },
    };

    esp_err_t err = esp_ble_mesh_config_client_set_state(NULL, &set_state);

    if (err == ESP_OK)
    {
        ESP_LOGI(TAG, "Heartbeat subscription configured: src=0x%04x, dst=0x%04x, period=0x%02x",
                 src_addr, dst_addr, period_log);
    }
    else
    {
        ESP_LOGE(TAG, "Failed to configure heartbeat subscription: %d", err);
    }
}

static void prov_complete(uint16_t net_idx, uint16_t addr, uint8_t flags, uint32_t iv_index)
{
    ESP_LOGI(TAG, "net_idx: 0x%04x, addr: 0x%04x", net_idx, addr);
    ESP_LOGI(TAG, "flags: 0x%02x, iv_index: 0x%08x", flags, iv_index);
    is_provisioning = true; //  Provisioned
    ESP_LOGI(TAG, "Device provisioned");
}

static void ble_mesh_provisioning_cb(esp_ble_mesh_prov_cb_event_t event,
                                     esp_ble_mesh_prov_cb_param_t *param)
{
    switch (event)
    {
    case ESP_BLE_MESH_PROV_REGISTER_COMP_EVT:
        ESP_LOGI(TAG, "ESP_BLE_MESH_PROV_REGISTER_COMP_EVT, err_code %d", param->prov_register_comp.err_code);
        break;

    case ESP_BLE_MESH_NODE_PROV_ENABLE_COMP_EVT:
        ESP_LOGI(TAG, "ESP_BLE_MESH_NODE_PROV_ENABLE_COMP_EVT, err_code %d", param->node_prov_enable_comp.err_code);

        break;

    case ESP_BLE_MESH_NODE_PROV_LINK_OPEN_EVT:
        ESP_LOGI(TAG, "ESP_BLE_MESH_NODE_PROV_LINK_OPEN_EVT, bearer %s",
                 param->node_prov_link_open.bearer == ESP_BLE_MESH_PROV_ADV ? "PB-ADV" : "PB-GATT");
        break;

    case ESP_BLE_MESH_NODE_PROV_LINK_CLOSE_EVT:
        ESP_LOGI(TAG, "ESP_BLE_MESH_NODE_PROV_LINK_CLOSE_EVT, bearer %s",
                 param->node_prov_link_close.bearer == ESP_BLE_MESH_PROV_ADV ? "PB-ADV" : "PB-GATT");
        break;

    case ESP_BLE_MESH_NODE_PROV_COMPLETE_EVT:
        ESP_LOGI(TAG, "ESP_BLE_MESH_NODE_PROV_COMPLETE_EVT");
        prov_complete(param->node_prov_complete.net_idx, param->node_prov_complete.addr,
                      param->node_prov_complete.flags, param->node_prov_complete.iv_index);

        break;

    case ESP_BLE_MESH_NODE_PROV_RESET_EVT:
        ESP_LOGI(TAG, "ESP_BLE_MESH_NODE_PROV_RESET_EVT");
        esp_timer_handle_t reset_timer;
        esp_timer_create_args_t timer_args = {
            .callback = &esp_restart};
        esp_timer_create(&timer_args, &reset_timer);
        esp_timer_start_once(reset_timer, 1000000); // Delay 1s
        break;

    case ESP_BLE_MESH_NODE_SET_UNPROV_DEV_NAME_COMP_EVT:
        ESP_LOGI(TAG, "ESP_BLE_MESH_NODE_SET_UNPROV_DEV_NAME_COMP_EVT, Name: %s, err_code %d", BLE_MESH_DEVICE_NAME, param->node_set_unprov_dev_name_comp.err_code);
        break;

    case ESP_BLE_MESH_PROVISIONER_ENABLE_HEARTBEAT_RECV_COMP_EVT:
        ESP_LOGI(TAG, "ESP_BLE_MESH_PROVISIONER_ENABLE_HEARTBEAT_RECV_COMP_EVT, Name: %s, err_code: %d",
                 BLE_MESH_DEVICE_NAME, param->provisioner_enable_heartbeat_recv_comp.err_code);
        break;

    case ESP_BLE_MESH_PROVISIONER_SET_HEARTBEAT_FILTER_TYPE_COMP_EVT:
        ESP_LOGI(TAG, "ESP_BLE_MESH_PROVISIONER_SET_HEARTBEAT_FILTER_TYPE_COMP_EVT, Name: %s, err_code: %d",
                 BLE_MESH_DEVICE_NAME, param->provisioner_set_heartbeat_filter_type_comp.err_code);
        break;

    case ESP_BLE_MESH_PROVISIONER_SET_HEARTBEAT_FILTER_INFO_COMP_EVT:
        ESP_LOGI(TAG, "ESP_BLE_MESH_PROVISIONER_SET_HEARTBEAT_FILTER_INFO_COMP_EVT, Name: %s, err_code: %d",
                 BLE_MESH_DEVICE_NAME, param->provisioner_set_heartbeat_filter_info_comp.err_code);
        break;

    case ESP_BLE_MESH_PROVISIONER_RECV_HEARTBEAT_MESSAGE_EVT:
        ESP_LOGI(TAG, "ESP_BLE_MESH_PROVISIONER_RECV_HEARTBEAT_MESSAGE_EVT, Name: %s", BLE_MESH_DEVICE_NAME);

        uint16_t hb_src = param->provisioner_recv_heartbeat.hb_src;
        uint8_t hops = param->provisioner_recv_heartbeat.hops;
        int8_t rssi = param->provisioner_recv_heartbeat.rssi;

        ESP_LOGI(TAG, "Heartbeat PROViSONER from 0x%04x, hops %d, rssi %d", hb_src, hops, rssi);

        break;

    default:
        break;
    }
}

static void ble_mesh_config_server_cb(esp_ble_mesh_cfg_server_cb_event_t event,
                                      esp_ble_mesh_cfg_server_cb_param_t *param)
{
    if (event == ESP_BLE_MESH_CFG_SERVER_STATE_CHANGE_EVT)
    {
        switch (param->ctx.recv_op)
        {
        case ESP_BLE_MESH_MODEL_OP_APP_KEY_ADD:
            ESP_LOGI(TAG, "ESP_BLE_MESH_MODEL_OP_APP_KEY_ADD");
            ESP_LOGI(TAG, "net_idx 0x%04x, app_idx 0x%04x",
                     param->value.state_change.appkey_add.net_idx,
                     param->value.state_change.appkey_add.app_idx);
            ESP_LOG_BUFFER_HEX("AppKey", param->value.state_change.appkey_add.app_key, 16);
            break;

        case ESP_BLE_MESH_MODEL_OP_MODEL_APP_BIND:
            ESP_LOGI(TAG, "ESP_BLE_MESH_MODEL_OP_MODEL_APP_BIND");
            ESP_LOGI(TAG, "elem_addr 0x%04x, app_idx 0x%04x, cid 0x%04x, mod_id 0x%04x",
                     param->value.state_change.mod_app_bind.element_addr,
                     param->value.state_change.mod_app_bind.app_idx,
                     param->value.state_change.mod_app_bind.company_id,
                     param->value.state_change.mod_app_bind.model_id);
            break;

        default:
            break;
        }
    }
}

static void ble_mesh_custom_sensor_client_model_cb(esp_ble_mesh_model_cb_event_t event,
                                                   esp_ble_mesh_model_cb_param_t *param)
{
    switch (event)
    {
    case ESP_BLE_MESH_MODEL_OPERATION_EVT: // (GET) P2P Received message from server
        switch (param->model_operation.opcode)
        {
        case ESP_BLE_MESH_CUSTOM_SENSOR_MODEL_OP_STATUS:

            ESP_LOGI(TAG, "OP_STATUS -- Mensagem recebida: 0x%06x", param->model_operation.opcode);
            ESP_LOG_BUFFER_HEX(TAG, param->model_operation.msg, param->model_operation.length);
            // ESP_LOGI(TAG, "\t Mensagem recebida: 0x%06x", param->model_operation.msg);
            break;

        default:
            ESP_LOGW(TAG, "Received unrecognized OPCODE message");
            break;
        }
        break;

    case ESP_BLE_MESH_MODEL_SEND_COMP_EVT: // (Set)  Send message completion
        if (param->model_send_comp.err_code)
        {
            ESP_LOGE(TAG, "Failed to send message 0x%06x", param->model_send_comp.opcode);
            break;
        }
        ESP_LOGI(TAG, "Send message opcode 0x%06x success!", param->model_send_comp.opcode);

        break;

    case ESP_BLE_MESH_CLIENT_MODEL_RECV_PUBLISH_MSG_EVT: // GET STATUS SENSOR FROM GROUP
        switch (param->client_recv_publish_msg.opcode)
        {
        case ESP_BLE_MESH_CUSTOM_SENSOR_MODEL_OP_STATUS:

            ESP_LOGI(TAG, "OP_STATUS -- Message received: 0x%06x", param->client_recv_publish_msg.opcode);
            ESP_LOGI(TAG, "rsc: 0x%04x, dst: 0x%04x, ", param->client_recv_publish_msg.ctx->addr, param->client_recv_publish_msg.ctx->recv_dst);
            ESP_LOGI(TAG, "RSSI: %d, TTL: %d, ", param->client_recv_publish_msg.ctx->recv_rssi, param->client_recv_publish_msg.ctx->recv_ttl);

            ESP_LOG_BUFFER_HEX(TAG, param->client_recv_publish_msg.msg, param->client_recv_publish_msg.length);

            model_sensor_data_t received_data;
            parse_received_data(param, &received_data);

            char *json_data = convert_model_sensor_to_json(&received_data);
            if (strcmp(received_data.device_name, "esp_server 01") == 0)
            {
                mqtt_data_publish_callback("node-01", json_data, 0);
            }
            else if (strcmp(received_data.device_name, "esp_server 02") == 0)
            {
                mqtt_data_publish_callback("node-02", json_data, 0);
            }
            free(json_data);

            break;

        default:
            ESP_LOGW(TAG, "Received unrecognized OPCODE message: 0x%04x", param->client_recv_publish_msg.opcode);
            break;
        }

        break;

    case ESP_BLE_MESH_CLIENT_MODEL_SEND_TIMEOUT_EVT:
        ESP_LOGW(TAG, "Message opcode 0x%06x timeout", param->client_send_timeout.opcode);
        //! fazer a funcao que reenvia a msg
        break;

    default:
        ESP_LOGW(TAG, "%s - Unrecognized event: 0x%04x", __func__, event);
        break;
    }
}

static void parse_received_data(esp_ble_mesh_model_cb_param_t *recv_param, model_sensor_data_t *parsed_data)
{
    if (recv_param->client_recv_publish_msg.length < sizeof(parsed_data))
    {
        ESP_LOGE(TAG, "Invalid received message lenght: %d", recv_param->client_recv_publish_msg.length);
        return;
    }

    memcpy(parsed_data, (model_sensor_data_t *)recv_param->client_recv_publish_msg.msg, recv_param->client_recv_publish_msg.length);

    ESP_LOGW("PARSED_DATA", "Device Name = %s", parsed_data->device_name);
    ESP_LOGW("PARSED_DATA", "Temperature = %f", parsed_data->temperature);
    ESP_LOGW("PARSED_DATA", "CO          = %f", parsed_data->CO);
    ESP_LOGW("PARSED_DATA", "Humidity    = %f", parsed_data->humidity);
}

static void ble_mesh_get_dev_uuid(uint8_t *dev_uuid)
{
    if (dev_uuid == NULL)
    {
        ESP_LOGE(TAG, "%s, Invalid device uuid", __func__);
        return;
    }

    /* Copy device address to the device uuid with offset equals to 2 here.
     * The first two bytes is used for matching device uuid by Provisioner.
     * And using device address here is to avoid using the same device uuid
     * by different unprovisioned devices.
     */
    memcpy(dev_uuid + 2, esp_bt_dev_get_address(), BD_ADDR_LEN);
}

static esp_err_t bluetooth_init(void)
{
    esp_err_t ret;

    ESP_ERROR_CHECK(esp_bt_controller_mem_release(ESP_BT_MODE_CLASSIC_BT));

    esp_bt_controller_config_t bt_cfg = BT_CONTROLLER_INIT_CONFIG_DEFAULT();
    ret = esp_bt_controller_init(&bt_cfg);
    if (ret)
    {
        ESP_LOGE(TAG, "%s initialize controller failed", __func__);
        return ret;
    }

    ret = esp_bt_controller_enable(ESP_BT_MODE_BLE);
    if (ret)
    {
        ESP_LOGE(TAG, "%s enable controller failed", __func__);
        return ret;
    }
    ret = esp_bluedroid_init();
    if (ret)
    {
        ESP_LOGE(TAG, "%s init bluetooth failed", __func__);
        return ret;
    }
    ret = esp_bluedroid_enable();
    if (ret)
    {
        ESP_LOGE(TAG, "%s enable bluetooth failed", __func__);
        return ret;
    }

    return ret;
}

/*******************************************
 ****** Public Functions Definitions ******
 *******************************************/

esp_err_t ble_mesh_device_init_client(void)
{
    esp_err_t err = ESP_OK;

    // Khởi tạo Bluetooth
    err = bluetooth_init();
    if (err)
    {
        ESP_LOGE(TAG, "esp32_bluetooth_init failed (err %d)", err);
        return err;
    }

    // Lấy UUID của thiết bị
    ble_mesh_get_dev_uuid(dev_uuid);

    // Đăng ký các callback cho BLE Mesh
    esp_ble_mesh_register_prov_callback(ble_mesh_provisioning_cb);                       //
    esp_ble_mesh_register_config_server_callback(ble_mesh_config_server_cb);             // PUB/SUB/ APPKEY/NET_KEY
    esp_ble_mesh_register_custom_model_callback(ble_mesh_custom_sensor_client_model_cb); // GET/SET

    // Khởi tạo BLE Mesh
    err = esp_ble_mesh_init(&provision, &composition);
    if (err)
    {
        ESP_LOGE(TAG, "Initializing mesh failed (err %d)", err);
        return err;
    }

    // Khởi tạo client model
    err = esp_ble_mesh_client_model_init(&custom_models[0]);
    if (err)
    {
        ESP_LOGE(TAG, "Failed to initialize vendor client");
        return err;
    }

    // Thiết lập tên thiết bị cho các thiết bị chưa được provision
    esp_ble_mesh_set_unprovisioned_device_name(BLE_MESH_DEVICE_NAME);

    // Bật provisioning cho thiết bị Mesh (advertising và GATT)
    esp_ble_mesh_node_prov_enable(ESP_BLE_MESH_PROV_ADV | ESP_BLE_MESH_PROV_GATT);

    ESP_LOGI(TAG, "BLE Mesh Node initialized");

    if (err)
    {
        ESP_LOGE(TAG, "Failed to enable heartbeat, error: %s", esp_err_to_name(err));
        return err;
    }

    // Cấu hình callback MQTT
    mqtt_data_pt_set_callback(mqtt_data_callback);

    return err;
}

esp_err_t ble_mesh_custom_sensor_client_model_message_set(model_sensor_data_t set_data)
{
    // set lại dự liệu như set_data đã gửi ở phía server cập nhật lại.
    esp_ble_mesh_msg_ctx_t ctx = {0};
    uint32_t opcode;
    esp_err_t err;

    opcode = ESP_BLE_MESH_CUSTOM_SENSOR_MODEL_OP_SET;

    ctx.net_idx = 0;
    ctx.app_idx = 0;

    uint16_t publish_addr = custom_sensor_client.model->pub->publish_addr;
    ctx.addr = publish_addr;

    // ctx.addr = ESP_BLE_MESH_ADDR_ALL_NODES;
    //  ctx.addr = ESP_BLE_MESH_GROUP_PUB_ADDR;

    ctx.send_ttl = 3;
    ctx.send_rel = false;

    err = esp_ble_mesh_client_model_send_msg(custom_sensor_client.model, &ctx, opcode,
                                             sizeof(set_data), (uint8_t *)&set_data, 0, false, ROLE_NODE);

    // err = esp_ble_mesh_model_publish(custom_sensor_client.model, opcode, sizeof(set_data), (uint8_t *)&set_data, ROLE_NODE);

    if (err != ESP_OK)
    {
        ESP_LOGE(TAG, "Failed to send the custom msg 0x%06x, err = 0x%06x", opcode, err);
    }

    return err;
}

esp_err_t ble_mesh_custom_sensor_client_model_message_get(uint16_t addr)
{
    esp_ble_mesh_msg_ctx_t ctx = {0};
    uint32_t opcode;
    esp_err_t err;

    opcode = ESP_BLE_MESH_CUSTOM_SENSOR_MODEL_OP_GET;

    ctx.net_idx = 0;
    ctx.app_idx = 0;

    // ctx.addr = ESP_BLE_MESH_ADDR_ALL_NODES;
    if (addr == 0)
    {
        uint16_t publish_addr = custom_sensor_client.model->pub->publish_addr;
        ctx.addr = publish_addr;
        // ctx.addr = ESP_BLE_MESH_GROUP_PUB_ADDR; //! FIXME: passar o endereco do device pra GET?
    }
    else
    {
        ctx.addr = addr;
    }

    ctx.send_ttl = 3;
    ctx.send_rel = false;

    ESP_LOGI(TAG, "*** %s ***", __func__);

    err = esp_ble_mesh_client_model_send_msg(custom_sensor_client.model, &ctx, opcode,
                                             0, NULL, 0, true, ROLE_NODE);

    if (err != ESP_OK)
    {
        ESP_LOGE(TAG, "Failed to send the custom msg 0x%06x, err = 0x%06x", opcode, err);
    }

    return err;
}

void mqtt_data_callback(char *data, uint16_t length)
{

    control_sensor_model_t control_sensor = convert_json_to_control_model_sensor(data);
    if (control_sensor.status == 1)
    {
        ble_mesh_custom_sensor_client_model_message_get(control_sensor.addr);
    }
}

// Hàm dừng BLE Mesh
esp_err_t stop_ble_mesh(void)
{
    esp_err_t err;

    // Kiểm tra xem BLE Mesh có đang được sử dụng hay không
    if (is_client_provisioned())
    {
        ESP_LOGI("BLE_MESH", "Stopping BLE Mesh...");

        // Dừng provisioning (ADV + GATT)
        err = esp_ble_mesh_node_prov_disable(ESP_BLE_MESH_PROV_ADV | ESP_BLE_MESH_PROV_GATT);
        if (err != ESP_OK)
        {
            ESP_LOGE("BLE_MESH", "Failed to disable BLE Mesh provisioning: %s", esp_err_to_name(err));
            return err; // Trả về lỗi nếu không thể dừng provisioning
        }
        ESP_LOGI("BLE_MESH", "Provisioning disabled successfully.");

        // Deinitialize custom client model
        err = esp_ble_mesh_client_model_deinit(&custom_models[0]);
        if (err != ESP_OK)
        {
            ESP_LOGE("BLE_MESH", "Failed to deinitialize client model: %s", esp_err_to_name(err));
            return err; // Trả về lỗi nếu không thể deinitialize client model
        }
        ESP_LOGI("BLE_MESH", "Client model deinitialized successfully.");

        // Deinitialize BLE Mesh stack
        esp_ble_mesh_deinit_param_t deinit_param = {true}; // true để giải phóng bộ nhớ của cấu hình BLE Mesh
        err = esp_ble_mesh_deinit(&deinit_param);
        if (err != ESP_OK)
        {
            ESP_LOGE("BLE_MESH", "Failed to deinitialize BLE Mesh: %s", esp_err_to_name(err));
            return err; // Trả về lỗi nếu không thể deinitialize BLE Mesh stack
        }
        ESP_LOGI("BLE_MESH", "BLE Mesh deinitialized successfully.");

        // Chờ ngắn để đảm bảo stack được giải phóng hoàn toàn
        vTaskDelay(100 / portTICK_PERIOD_MS);
    }
    else
    {
        ESP_LOGW("BLE_MESH", "BLE Mesh is not provisioned or initialized.");
    }

    return ESP_OK; // Trả về kết quả thành công nếu không có lỗi
}

// Hàm dừng Bluetooth (Bluedroid stack)
esp_err_t stop_bluetooth(void)
{
    esp_err_t err;

    // Kiểm tra trạng thái Bluedroid
    esp_bluedroid_status_t bt_status = esp_bluedroid_get_status();

    // Nếu Bluedroid đang được bật
    if (bt_status == ESP_BLUEDROID_STATUS_ENABLED)
    {
        ESP_LOGI("BLUETOOTH", "Disabling Bluedroid...");

        // Disable Bluedroid stack
        err = esp_bluedroid_disable();
        if (err != ESP_OK)
        {
            ESP_LOGE("BLUETOOTH", "Failed to disable Bluedroid: %s", esp_err_to_name(err));
            return err; // Trả về lỗi nếu không thể disable
        }
        ESP_LOGI("BLUETOOTH", "Bluedroid disabled successfully.");
        vTaskDelay(100 / portTICK_PERIOD_MS); // Thời gian chờ sau khi disable
    }
    else
    {
        ESP_LOGW("BLUETOOTH", "Bluedroid is already disabled, skipping disable.");
    }

    // Kiểm tra trạng thái Bluedroid trước khi deinitialize
    if (bt_status != ESP_BLUEDROID_STATUS_UNINITIALIZED)
    {
        ESP_LOGI("BLUETOOTH", "Deinitializing Bluedroid...");

        // Deinitialize Bluedroid stack
        err = esp_bluedroid_deinit();
        if (err != ESP_OK)
        {
            ESP_LOGE("BLUETOOTH", "Failed to deinitialize Bluedroid: %s", esp_err_to_name(err));
            return err; // Trả về lỗi nếu không thể deinit
        }
        ESP_LOGI("BLUETOOTH", "Bluedroid deinitialized successfully.");
    }
    else
    {
        ESP_LOGW("BLUETOOTH", "Bluedroid is already uninitialized, skipping deinit.");
    }

    // Tắt bộ điều khiển Bluetooth (controller)
    err = esp_bt_controller_disable();
    if (err != ESP_OK)
    {
        ESP_LOGE("BLUETOOTH", "Failed to disable Bluetooth controller: %s", esp_err_to_name(err));
        return err; // Trả về lỗi nếu không thể disable controller
    }
    ESP_LOGI("BLUETOOTH", "Bluetooth controller disabled successfully.");

    // Giải phóng bộ nhớ của bộ điều khiển Bluetooth
    err = esp_bt_controller_mem_release(ESP_BT_MODE_BLE);
    if (err != ESP_OK)
    {
        ESP_LOGE("BLUETOOTH", "Failed to release Bluetooth controller memory: %s", esp_err_to_name(err));
        return err; // Trả về lỗi nếu không thể giải phóng bộ nhớ
    }
    ESP_LOGI("BLUETOOTH", "Bluetooth controller memory released successfully.");

    vTaskDelay(100 / portTICK_PERIOD_MS); // Thời gian chờ sau khi giải phóng bộ nhớ

    return ESP_OK; // Trả về kết quả thành công
}
