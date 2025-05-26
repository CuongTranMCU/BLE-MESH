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

static model_sensor_data_t _client_model_state;

static cJSON *aggregate_json = NULL;
static esp_timer_handle_t aggregate_timer;

static set_entry_t *sensor_buffer = NULL; // Con trỏ đến Set
static bool timer_running = false;        // Flag to track if aggregation timer is running

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

static message_type_t parse_received_data(esp_ble_mesh_model_cb_param_t *recv_param,
                                          model_sensor_data_t *out_sensor,
                                          model_control_data_t *out_control);
static void configure_heartbeat_subscription(uint16_t src_addr, uint16_t dst_addr, uint8_t period_log);

static void mqtt_data_callback(char *data, uint16_t length);
static void timer_callback(void *arg);
static void start_aggregation_timer();

static void set_mac_address();
static void set_ble_mesh_addr();
static void set_provision_name();

static bool add_to_buffer(model_sensor_data_t *data);
static void clear_buffer();
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

            model_sensor_data_t sensor_data;
            model_control_data_t control_data;

            message_type_t type = parse_received_data(param, &sensor_data, &control_data);

            if (type == MSG_TYPE_SENSOR)
            {
                sensor_data.rssi = param->client_recv_publish_msg.ctx->recv_rssi;

                if (add_to_buffer(&sensor_data))
                {
                    start_aggregation_timer();
                }
            }
            else if (type == MSG_TYPE_CONTROL)
            {
                // TODO: Handle control message if needed
                char *json_str = cJSON_Print(convert_model_control_to_json(&control_data));
                printf("JSON data: %s\n", json_str);
                mqtt_data_publish_callback("SendControlData", json_str, strlen(json_str));
                free(json_str);
                ESP_LOGI(TAG, "CONTROL message received but not processed further.");
            }
            else
            {
                ESP_LOGW(TAG, "Unknown or invalid message type received.");
            }
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

static message_type_t parse_received_data(esp_ble_mesh_model_cb_param_t *recv_param,
                                          model_sensor_data_t *out_sensor,
                                          model_control_data_t *out_control)
{
    uint8_t *msg = recv_param->client_recv_publish_msg.msg;
    uint16_t len = recv_param->client_recv_publish_msg.length;

    if (len < 1)
    {
        ESP_LOGE(TAG, "Received message too short!");
        return -1;
    }

    uint8_t type = msg[0];

    switch (type)
    {
    case MSG_TYPE_SENSOR:
        if (len > 1 + sizeof(model_sensor_data_t))
        {
            ESP_LOGE(TAG, "Sensor model data length + 1: %d", 1 + sizeof(model_sensor_data_t));
            ESP_LOGE(TAG, "Invalid SENSOR data length: %d", len);
            return -1;
        }

        memcpy(out_sensor, &msg[1], sizeof(model_sensor_data_t));

        ESP_LOGI("PARSED_SENSOR", "Device Name = %s", out_sensor->device_name);
        ESP_LOGI("PARSED_SENSOR", "Mac address = %s", out_sensor->mac_addr);
        ESP_LOGI("PARSED_SENSOR", "Mesh address = %02x", out_sensor->mesh_addr);
        ESP_LOGI("PARSED_SENSOR", "Temperature = %f", out_sensor->temperature);
        ESP_LOGI("PARSED_SENSOR", "Humidity    = %f", out_sensor->humidity);
        ESP_LOGI("PARSED_SENSOR", "Smoke       = %f", out_sensor->smoke);
        ESP_LOGI("PARSED_SENSOR", "Is Flame    = %d", out_sensor->isFlame);
        ESP_LOGI("PARSED_SENSOR", "Feedback    = %s", out_sensor->feedback);

        return MSG_TYPE_SENSOR;

    case MSG_TYPE_CONTROL:
        if (len > 1 + sizeof(model_control_data_t))
        {
            ESP_LOGE(TAG, "Sensor model data length + 1: %d", 1 + sizeof(model_sensor_data_t));
            ESP_LOGE(TAG, "Invalid CONTROL data length: %d", len);
            return -1;
        }

        memcpy(out_control, &msg[1], sizeof(model_control_data_t));

        ESP_LOGI("PARSED_CONTROL", "Device Name  = %s", out_control->device_name);
        ESP_LOGI("PARSED_CONTROL", "Mesh address = %02x", out_control->mesh_addr);
        ESP_LOGI("PARSED_CONTROL", "Buzzer       = %d", out_control->buzzerStatus);
        ESP_LOGI("PARSED_CONTROL", "LedRed       = %d", out_control->ledStatus[0]);
        ESP_LOGI("PARSED_CONTROL", "LedGreen     = %d", out_control->ledStatus[1]);
        ESP_LOGI("PARSED_CONTROL", "LedBlue      = %d", out_control->ledStatus[2]);
        ESP_LOGI("PARSED_CONTROL", "BuzzerError  = %d", out_control->buzzerError);
        ESP_LOGI("PARSED_CONTROL", "LedError     = %d", out_control->ledError);

        return MSG_TYPE_CONTROL;

    default:
        ESP_LOGW(TAG, "Unknown message type: 0x%02x", type);
        return -1;
    }
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

    //* Set device name with MAC address
    set_mac_address();
    set_provision_name();

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
    esp_ble_mesh_set_unprovisioned_device_name(_client_model_state.device_name);

    // Bật provisioning cho thiết bị Mesh (advertising và GATT)
    esp_ble_mesh_node_prov_enable(ESP_BLE_MESH_PROV_ADV | ESP_BLE_MESH_PROV_GATT);

    set_ble_mesh_addr();

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

static void set_mac_address()
{
    esp_err_t ret = ESP_OK;
    uint8_t base_mac_addr[6];
    ret = esp_efuse_mac_get_default(base_mac_addr);
    if (ret != ESP_OK)
    {
        ESP_LOGE(TAG, "Failed to get base MAC address from EFUSE BLK0. (%s)", esp_err_to_name(ret));
        ESP_LOGE(TAG, "Aborting");
        abort();
    }

    uint8_t index = 0;
    for (uint8_t i = 0; i < 6; i++)
    {
        int written = snprintf(&_client_model_state.mac_addr[index],
                               sizeof(_client_model_state.mac_addr) - index,
                               "%02x",
                               base_mac_addr[i]);
        if (written < 0 || index + written >= sizeof(_client_model_state.mac_addr))
        {
            ESP_LOGE(TAG, "MAC address buffer overflow");
            abort();
        }
        index += written;
    }
    ESP_LOGI(TAG, "macId = %s", _client_model_state.mac_addr);
}
static void set_ble_mesh_addr()
{
    // Add the mesh address to the data structure
    _client_model_state.mesh_addr = esp_ble_mesh_get_primary_element_address();
    ESP_LOGI(TAG, "Mesh Address: 0x%04x", _client_model_state.mesh_addr);
}
static void set_provision_name()
{
    char device_name_with_mac[20];
    snprintf(device_name_with_mac, sizeof(device_name_with_mac), "CLIENT_%s",
             _client_model_state.mac_addr);
    strcpy(_client_model_state.device_name, device_name_with_mac);
    ESP_LOGI(TAG, "Device Name: %s", _client_model_state.device_name);
}

esp_err_t ble_mesh_custom_sensor_client_model_message_set(void *data, size_t len, uint16_t addr)
{
    esp_ble_mesh_msg_ctx_t ctx = {0};
    uint32_t opcode;
    esp_err_t err;

    opcode = ESP_BLE_MESH_CUSTOM_SENSOR_MODEL_OP_SET;

    ctx.net_idx = 0;
    ctx.app_idx = 0;

    ctx.send_ttl = 3;
    ctx.send_rel = false;

    if (addr == 0)
    {

        uint16_t publish_addr = custom_sensor_client.model->pub->publish_addr;
        ctx.addr = publish_addr;
    }
    else
    {
        ctx.addr = addr;
    }

    // ctx.addr = 0x0038;

    err = esp_ble_mesh_client_model_send_msg(custom_sensor_client.model, &ctx, opcode,
                                             len, data, 0, false, ROLE_NODE);

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

static void mqtt_data_callback(char *data, uint16_t length)
{

    int count = 0;
    model_control_data_t *devices = convert_json_to_control_model_list(data, &count);

    for (int i = 0; i < count; i++)
    {
        printf("Device: %s, MeshAddr: 0x%04X, Buzzer: %d, LedRed: %d, LedGreen: %d, LedBlue: %d, LedError: %d, BuzzerError: %d\n",
               devices[i].device_name,
               devices[i].mesh_addr,
               devices[i].buzzerStatus,
               devices[i].ledStatus[0],
               devices[i].ledStatus[1],
               devices[i].ledStatus[2],
               devices[i].ledError,
               devices[i].buzzerError);
        ble_mesh_custom_sensor_client_model_message_set(&devices[i], sizeof(model_control_data_t), devices[i].mesh_addr);
        vTaskDelay(1000 * 2 / portTICK_PERIOD_MS);
    }
    free(devices);
}

// Function to add data to the buffer
static bool add_to_buffer(model_sensor_data_t *data)
{
    set_entry_t *entry;

    // Tìm xem key đã tồn tại chưa
    HASH_FIND_STR(sensor_buffer, data->mac_addr, entry);
    if (entry)
    {
        // Cập nhật dữ liệu nếu key đã tồn tại
        memcpy(&entry->data, data, sizeof(model_sensor_data_t));
        ESP_LOGI(TAG, "Updated data for %s", data->device_name);
        return true;
    }

    // Thêm mới nếu key chưa tồn tại
    entry = (set_entry_t *)malloc(sizeof(set_entry_t));
    if (entry == NULL)
    {
        ESP_LOGE(TAG, "Failed to allocate memory for new entry");
        return false;
    }
    strcpy(entry->mac_addr, data->mac_addr);
    memcpy(&entry->data, data, sizeof(model_sensor_data_t));
    HASH_ADD_STR(sensor_buffer, mac_addr, entry);
    ESP_LOGI(TAG, "Added to set: %s", data->device_name);
    return true;
}

// Function to clear the buffer
static void clear_buffer()
{
    set_entry_t *entry, *tmp;
    HASH_ITER(hh, sensor_buffer, entry, tmp)
    {
        HASH_DEL(sensor_buffer, entry);
        free(entry);
    }
    ESP_LOGI(TAG, "Buffer cleared");
}

// Timer callback function for processing the buffer
static void timer_callback(void *arg)
{
    ESP_LOGI(TAG, "Timer callback fired, processing buffer");

    // Kiểm tra xem Buffer có phần tử nào không
    if (HASH_COUNT(sensor_buffer) == 0)
    {
        ESP_LOGI(TAG, "No data to aggregate");
        if (aggregate_json)
        {
            cJSON_Delete(aggregate_json);
            aggregate_json = NULL;
        }
        timer_running = false;
        return;
    }

    // Tạo đối tượng JSON mới nếu chưa tồn tại
    if (!aggregate_json)
    {
        aggregate_json = cJSON_CreateObject();
        if (!aggregate_json)
        {
            ESP_LOGE(TAG, "Failed to create JSON object");
            timer_running = false;
            return;
        }
    }

    // Thêm dữ liệu của client
    cJSON *client_data = cJSON_CreateObject();
    if (client_data)
    {
        cJSON_AddItemToObject(aggregate_json, _client_model_state.device_name, client_data);
    }

    // Duyệt qua từng entry trong Set
    set_entry_t *entry, *tmp;
    HASH_ITER(hh, sensor_buffer, entry, tmp)
    {
        ESP_LOGI(TAG, "Processing buffer: %s (MAC: %s)", entry->data.device_name, entry->mac_addr);

        // Chuyển dữ liệu cảm biến thành JSON
        cJSON *json_data = convert_model_sensor_to_json(&entry->data);
        if (json_data == NULL)
        {
            ESP_LOGE(TAG, "Failed to convert sensor data to JSON for %s", entry->data.device_name);
            continue;
        }

        // Thêm vào đối tượng JSON tổng hợp với device_name làm key
        cJSON_AddItemToObject(client_data, entry->data.device_name, json_data);
    }

    // Chuyển JSON thành chuỗi và gửi qua MQTT
    char *json_str = cJSON_Print(aggregate_json);
    printf("JSON data: %s\n", json_str);

    if (json_str)
    {
        ESP_LOGI(TAG, "Publishing JSON data to MQTT");
        mqtt_data_publish_callback("Send Data", json_str, strlen(json_str));
        free(json_str);
    }
    else
    {
        ESP_LOGE(TAG, "Failed to print JSON string");
    }

    // Dọn dẹp
    cJSON_Delete(aggregate_json);
    aggregate_json = NULL;
    clear_buffer();
    timer_running = false;
}

// Function to start the aggregation timer
static void start_aggregation_timer()
{
    if (timer_running)
    {
        // Timer is already running, no need to start it again
        ESP_LOGI(TAG, "Aggregation timer already running");
        return;
    }

    // Create the timer if it doesn't exist
    if (aggregate_timer == NULL)
    {
        const esp_timer_create_args_t timer_args = {
            .callback = &timer_callback,
            .name = "aggregate_timer"};

        esp_err_t err = esp_timer_create(&timer_args, &aggregate_timer);
        if (err != ESP_OK)
        {
            ESP_LOGE(TAG, "Failed to create timer: %s", esp_err_to_name(err));
            return;
        }
    }

    // Start the timers
    esp_err_t err = esp_timer_start_once(aggregate_timer, GATEWAY_UPDATE_PERIOD); // 5 minutes in microseconds
    if (err != ESP_OK)
    {
        ESP_LOGE(TAG, "Failed to start timer: %s", esp_err_to_name(err));
        return;
    }

    timer_running = true;
    ESP_LOGI(TAG, "Started aggregation timer for 5 seconds");
}