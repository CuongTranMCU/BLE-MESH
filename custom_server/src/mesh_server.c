/**
 * @file mesh_server.c
 *
 * @brief
 *
 * @author
 *
 * @date  11/2020
 */

#include "mesh_server.h"

static const char *TAG = "MESH SERVER";

/*******************************************
 ****** Private Variables Definitions ******
 *******************************************/

static uint8_t dev_uuid[16] = {0xdd, 0xdd}; /**< Device UUID */
// static uint16_t node_net_idx = ESP_BLE_MESH_KEY_UNUSED;     /**< Stores Netkey Index after provisioning */
// static uint16_t node_app_idx = ESP_BLE_MESH_KEY_UNUSED;     /**< Stores Appkey Index bound to the Custom Model by the provisioner */

//* Definicao do Configuration Server Model
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

//* Colocamos o Config Server Model aqui como root model
static esp_ble_mesh_model_t root_models[] = {
    ESP_BLE_MESH_MODEL_CFG_SRV(&config_server),
};

//* Definicao dos opcodes presentes nesse model aqui
static esp_ble_mesh_model_op_t custom_sensor_op[] = {
    ESP_BLE_MESH_MODEL_OP(ESP_BLE_MESH_CUSTOM_SENSOR_MODEL_OP_GET, 0), // OP_GET no minimo 0 bytes
    ESP_BLE_MESH_MODEL_OP(ESP_BLE_MESH_CUSTOM_SENSOR_MODEL_OP_SET, 4), // OP_SET no minimo 4 bytes
    ESP_BLE_MESH_MODEL_OP_END,
};

static model_sensor_data_t _server_model_state;
static model_control_data_t _control_model_state;
//* E agora a definiçao do model
//! Verificar "Publication Context"

// Defind Addr
ESP_BLE_MESH_MODEL_PUB_DEFINE(custom_sensor_pub, 3, ROLE_NODE);

static esp_ble_mesh_model_t custom_models[] = {
    ESP_BLE_MESH_VENDOR_MODEL(CID_ESP, ESP_BLE_MESH_CUSTOM_SENSOR_MODEL_ID_SERVER,
                              custom_sensor_op, &custom_sensor_pub, &_server_model_state),
};

//* Apenas 1 element com os dois models definidos acima
static esp_ble_mesh_elem_t elements[] = {
    ESP_BLE_MESH_ELEMENT(0, root_models, custom_models),
};

static esp_ble_mesh_comp_t composition = {
    .cid = CID_ESP,
    .elements = elements,
    .element_count = ARRAY_SIZE(elements)};

static esp_ble_mesh_prov_t provision = {
    .uuid = dev_uuid,
    .output_size = 0,
    .output_actions = 0};

static bool is_server_provisioning = false;
static bool is_server_sending = false;

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
 * @param  param   Pointer to Sensor Server Model parameter
 */
static void ble_mesh_custom_sensor_server_model_cb(esp_ble_mesh_model_cb_event_t event,
                                                   esp_ble_mesh_model_cb_param_t *param);

/**
 * @brief Parses received Sensor Model raw data and stores it on appropriate structure
 *
 * @param  recv_param   Pointer to model callback received parameter
 * @param  parsed_data  Pointer to where the parsed data will be stored
 */

static void parse_received_data(esp_ble_mesh_model_cb_param_t *recv_param, model_control_data_t *parsed_data);
static void send_heartbeat_from_server(uint8_t count_log, uint8_t period_log);
static void set_mac_address();
static void set_ble_mesh_addr();
static void set_provision_name();
/******************************************
 ****** End Private Functions Prototypes ******
 ******************************************/

bool is_server_provisioned(void)
{
    return is_server_provisioning;
}

bool is_server_sent_init_control(void)
{
    return is_server_sending;
}

esp_err_t server_send_to_client(const void *raw_data, size_t raw_len, message_type_t type)
{
    if (custom_models[0].pub == NULL || custom_models[0].pub->publish_addr == ESP_BLE_MESH_ADDR_UNASSIGNED)
    {
        ESP_LOGE(TAG, "Publish address is not configured");
        return ESP_FAIL;
    }

    // Tạo payload mới có thêm 1 byte đầu là type
    size_t total_len = raw_len + 1;
    uint8_t *payload = malloc(total_len);
    if (!payload)
    {
        ESP_LOGE(TAG, "Failed to allocate memory for payload");
        return ESP_ERR_NO_MEM;
    }

    payload[0] = (uint8_t)type;             // Type field
    memcpy(&payload[1], raw_data, raw_len); // Actual data

    esp_ble_mesh_msg_ctx_t ctx = {
        .addr = custom_models[0].pub->publish_addr,
        .send_ttl = 5,
        .net_idx = ESP_BLE_MESH_KEY_PRIMARY,
        .app_idx = custom_models[0].pub->app_idx,
    };

    uint32_t opcode = ESP_BLE_MESH_CUSTOM_SENSOR_MODEL_OP_STATUS;

    esp_err_t err = esp_ble_mesh_server_model_send_msg(custom_models, &ctx, opcode, total_len, payload);
    free(payload); // luôn giải phóng sau khi gửi

    if (err != ESP_OK)
    {
        ESP_LOGE(TAG, "Failed to send message, error code: 0x%04x", err);
        return err;
    }

    ESP_LOGI(TAG, "Message sent successfully to 0x%04x", ctx.addr);
    return ESP_OK;
}

void send_heartbeat_from_server(uint8_t count_log, uint8_t period_log)
{
    esp_ble_mesh_msg_ctx_t ctx = {0};

    // Cấu hình thông điệp Heartbeat
    uint16_t publish_addr = custom_models[0].pub->publish_addr;

    // Kiểm tra nếu địa chỉ publish chưa được cấu hình
    if (publish_addr == ESP_BLE_MESH_ADDR_UNASSIGNED)
    {
        ESP_LOGE(TAG, "Publish address is not configured");
        return;
    }

    // Thiết lập ngữ cảnh tin nhắn
    ctx.addr = 0x0021;                           // Địa chỉ đích
    ctx.send_ttl = 3;                            // TTL cho Heartbeat
    ctx.net_idx = ESP_BLE_MESH_KEY_PRIMARY;      // NetKey Index
    ctx.app_idx = custom_models[0].pub->app_idx; // AppKey Index

    // Các thông tin khác (có thể thay đổi tùy theo ứng dụng)
    uint32_t opcode = ESP_BLE_MESH_MODEL_OP_HEARTBEAT_PUB_SET; // Opcode cho Heartbeat

    esp_ble_mesh_cfg_heartbeat_pub_set_t heartbeat_data = {
        .count = count_log,   // Số lượng heartbeat (0x00 dừng, 0xFF gửi vô hạn)
        .period = period_log, // Thời gian giữa các heartbeat
        .ttl = 3              // TTL
    };

    // Gửi Heartbeat tới client
    esp_err_t err = esp_ble_mesh_server_model_send_msg(custom_models, &ctx, opcode, sizeof(heartbeat_data), &heartbeat_data);

    if (err != ESP_OK)
    {
        ESP_LOGE(TAG, "Failed to send heartbeat: 0x%04x", err);
    }
    else
    {
        ESP_LOGI(TAG, "Heartbeat sent successfully to 0x%04x", publish_addr);
    }
}

/*******************************************
 ****** Private Functions Definitions ******
 *******************************************/

static void prov_complete(uint16_t net_idx, uint16_t addr, uint8_t flags, uint32_t iv_index)
{
    ESP_LOGI(TAG, "net_idx: 0x%04x, addr: 0x%04x", net_idx, addr);
    ESP_LOGI(TAG, "flags: 0x%02x, iv_index: 0x%08x", flags, iv_index);

    //! Precisa salvar o netkey idx????
    // node_net_idx = net_idx;  // Netkey index saved
    is_server_provisioning = true;

    ESP_LOGI(TAG, "Device provisioned");
}

static void ble_mesh_provisioning_cb(esp_ble_mesh_prov_cb_event_t event,
                                     esp_ble_mesh_prov_cb_param_t *param)
{
    switch (event)
    {
    case ESP_BLE_MESH_PROV_REGISTER_COMP_EVT:
        ESP_LOGI(TAG, "ESP_BLE_MESH_PROV_REGISTER_COMP_EVT, err_code %d", param->prov_register_comp.err_code);
        // When device starts up, not provisioned
        led_indicate_not_provisioned();
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
        // When device gets provisioned
        led_indicate_provisioned();
        break;

    case ESP_BLE_MESH_NODE_PROV_RESET_EVT:
        ESP_LOGI(TAG, "ESP_BLE_MESH_NODE_PROV_RESET_EVT");
        break;

    case ESP_BLE_MESH_NODE_SET_UNPROV_DEV_NAME_COMP_EVT:
        ESP_LOGI(TAG, "ESP_BLE_MESH_NODE_SET_UNPROV_DEV_NAME_COMP_EVT, Name: %s, err_code %d", BLE_MESH_DEVICE_NAME, param->node_set_unprov_dev_name_comp.err_code);
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
        //* Application key added to device (on provisioning routine)
        case ESP_BLE_MESH_MODEL_OP_APP_KEY_ADD:
            ESP_LOGI(TAG, "ESP_BLE_MESH_MODEL_OP_APP_KEY_ADD");
            ESP_LOGI(TAG, "net_idx 0x%04x, app_idx 0x%04x",
                     param->value.state_change.appkey_add.net_idx,
                     param->value.state_change.appkey_add.app_idx);
            ESP_LOG_BUFFER_HEX("AppKey", param->value.state_change.appkey_add.app_key, 16);
            break;

        //* Application key bound to Model
        case ESP_BLE_MESH_MODEL_OP_MODEL_APP_BIND:
            ESP_LOGI(TAG, "ESP_BLE_MESH_MODEL_OP_MODEL_APP_BIND");
            ESP_LOGI(TAG, "elem_addr 0x%04x, app_idx 0x%04x, cid 0x%04x, mod_id 0x%06x",
                     param->value.state_change.mod_app_bind.element_addr,
                     param->value.state_change.mod_app_bind.app_idx,
                     param->value.state_change.mod_app_bind.company_id,
                     param->value.state_change.mod_app_bind.model_id);
            ESP_LOGI(TAG, "Application key bound to model 0x%06x", param->value.state_change.mod_app_bind.model_id);
            break;

        //* Model Subscription group add
        case ESP_BLE_MESH_MODEL_OP_MODEL_SUB_ADD:
            ESP_LOGI(TAG, "ESP_BLE_MESH_MODEL_OP_MODEL_SUB_ADD");
            ESP_LOGI(TAG, "elem_addr 0x%04x, sub_addr 0x%04x, cid 0x%04x, mod_id 0x%04x",
                     param->value.state_change.mod_sub_add.element_addr,
                     param->value.state_change.mod_sub_add.sub_addr,
                     param->value.state_change.mod_sub_add.company_id,
                     param->value.state_change.mod_sub_add.model_id);
            ESP_LOGI(TAG, "Model 0x%06x subscribed to Group 0x%04x !",
                     param->value.state_change.mod_sub_add.model_id,
                     param->value.state_change.mod_sub_add.sub_addr);
            break;

            /** @TODO: Adicionar publication address tbm */

        default:
            break;
        }
    }
}
void get_data_from_sensors()
{
    model_sensor_data_t _received_data;
    if (xQueueReceive(received_data_from_sensor_queue, &_received_data, 1000 / portTICK_PERIOD_MS) == pdPASS)
    {
        ESP_LOGI(TAG, "    Temperature: %f", _received_data.temperature);
        ESP_LOGI(TAG, "    Humidity:    %f", _received_data.humidity);
        ESP_LOGI(TAG, "    Somke:       %f", _received_data.smoke);

        _server_model_state.temperature = _received_data.temperature;
        _server_model_state.humidity = _received_data.humidity;
        _server_model_state.smoke = _received_data.smoke;
        _server_model_state.isFlame = _received_data.isFlame;
        strcpy(_server_model_state.feedback, "Hello world");

        // Call event
        esp_err_t err = server_send_to_client(&_server_model_state, sizeof(_server_model_state), MSG_TYPE_SENSOR);
        if (err != ESP_OK)
        {
            ESP_LOGE("Sever send data to Client", "Failed to send message, error code: 0x%04x", err);
        }
        else
        {
            ESP_LOGI("Sever send data to Client", "Message sent successfully to 0x%04x", custom_models[0].pub->publish_addr);
        }
    }
}

void get_init_control_signal_from_sensors(int buzzer_state, int led_state)
{

    if (!is_server_sent_init_control())
    {
        strcpy(_control_model_state.device_name, _server_model_state.device_name);
        _control_model_state.mesh_addr = _server_model_state.mesh_addr;
        _control_model_state.buzzer = buzzer_state;
        _control_model_state.led = led_state;

        vTaskDelay(1000 * 5 / portTICK_PERIOD_MS);
        esp_err_t err = server_send_to_client(&_control_model_state, sizeof(_control_model_state), MSG_TYPE_CONTROL);

        if (err != ESP_OK)
        {
            ESP_LOGE("Sever send control signal to Client", "Failed to send message, error code: 0x%04x", err);
        }
        else
        {
            is_server_sending = true;
            ESP_LOGI("Sever send data to Client", "Message sent successfully to 0x%04x", custom_models[0].pub->publish_addr);
        }
    }
}

static void ble_mesh_custom_sensor_server_model_cb(esp_ble_mesh_model_cb_event_t event,
                                                   esp_ble_mesh_model_cb_param_t *param)
{

    switch (event)
    {
    //* Recebimento de msg direta pra esse node
    case ESP_BLE_MESH_MODEL_OPERATION_EVT:
        switch (param->model_operation.opcode)
        {

        case ESP_BLE_MESH_CUSTOM_SENSOR_MODEL_OP_GET:
            if (param->model_operation.length > 0)
            {
                ESP_LOGI(TAG, "OP_GET -- Opcode 0x%06x,  tid 0x%04x", param->model_operation.opcode, *param->model_operation.msg);
            }
            else
            {
                ESP_LOGW(TAG, "OP_GET -- Opcode 0x%06x  -- empty message", param->model_operation.opcode);
            }
            // Handle the response message to the client
            //* Responde com o estado atual do Model (OP_STATUS)
            // model_sensor_data_t response = *(model_sensor_data_t *)param->model_operation.model->user_data;

            // esp_err_t err = esp_ble_mesh_server_model_send_msg(param->model_operation.model, param->model_operation.ctx,
            //                 ESP_BLE_MESH_CUSTOM_SENSOR_MODEL_OP_STATUS, sizeof(response), (uint8_t *)&response);
            // if (err) {
            //     ESP_LOGE(TAG, "%s -- Failed to send response with OPCODE 0x%06x", __func__, ESP_BLE_MESH_CUSTOM_SENSOR_MODEL_OP_STATUS);
            // }
            // get_data_from_sensors();
            // send_heartbeat_from_server(0xFF, 3);
            break;

        case ESP_BLE_MESH_CUSTOM_SENSOR_MODEL_OP_SET:
            ESP_LOGI(TAG, "OP_SET -- Received HEX message: ");
            ESP_LOG_BUFFER_HEX(TAG, (uint8_t *)param->model_operation.msg, param->model_operation.length);
            parse_received_data(param, (model_sensor_data_t *)&param->model_operation.model->user_data);
            break;

        default:
            ESP_LOGW(TAG, "Unknown OPCODE message received: 0x%06x", param->model_operation.opcode);
            break;
        }
        break;

    //* Evento chamado apos tentar enviar uma msg pra outro lugar
    case ESP_BLE_MESH_MODEL_SEND_COMP_EVT:
        if (param->model_send_comp.err_code)
        {
            ESP_LOGE(TAG, "Failed to send message 0x%06x", param->model_send_comp.opcode);
        }
        else
        {
            ESP_LOGI(TAG, "%s -- SEND_COMPLETE -- Send message opcode 0x%08x success", __func__, param->model_send_comp.opcode);
        }
        break;

    default:
        ESP_LOGW(TAG, "%s - Unknown Custom Sensor Server event: 0x%04x", __func__, event);
        break;
    }
}

static void parse_received_data(esp_ble_mesh_model_cb_param_t *recv_param, model_control_data_t *parsed_data)
{
    if (recv_param->client_recv_publish_msg.length < sizeof(parsed_data))
    {
        ESP_LOGE(TAG, "Invalid received message lenght: %d", recv_param->client_recv_publish_msg.length);
        return;
    }

    parsed_data = (model_control_data_t *)recv_param->client_recv_publish_msg.msg;

    ESP_LOGI("PARSED_CONTROL", "Device Name  = %s", parsed_data->device_name);
    ESP_LOGI("PARSED_CONTROL", "Mesh address = %04x", parsed_data->mesh_addr);
    ESP_LOGI("PARSED_CONTROL", "Buzzer       = %d", parsed_data->buzzer);
    ESP_LOGI("PARSED_CONTROL", "LED          = %d", parsed_data->led);

    xQueueSendToBack(receive_data_control_queue, parsed_data, portMAX_DELAY);
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
        int written = snprintf(&_server_model_state.mac_addr[index],
                               sizeof(_server_model_state.mac_addr) - index,
                               "%02x",
                               base_mac_addr[i]);
        if (written < 0 || index + written >= sizeof(_server_model_state.mac_addr))
        {
            ESP_LOGE(TAG, "MAC address buffer overflow");
            abort();
        }
        index += written;
    }
    ESP_LOGI(TAG, "macId = %s", _server_model_state.mac_addr);
}
static void set_ble_mesh_addr()
{
    // Add the mesh address to the data structure
    _server_model_state.mesh_addr = esp_ble_mesh_get_primary_element_address();
    ESP_LOGI(TAG, "Mesh Address: 0x%04x", _server_model_state.mesh_addr);
}
static void set_provision_name()
{
    char device_name_with_mac[20];
    snprintf(device_name_with_mac, sizeof(device_name_with_mac), "SERVER_%s",
             _server_model_state.mac_addr);
    strcpy(_server_model_state.device_name, device_name_with_mac);
    ESP_LOGI(TAG, "Device Name: %s", _server_model_state.device_name);
}

esp_err_t ble_mesh_device_init_server(void)
{
    esp_err_t err = ESP_OK;

    //* Initializes esp32 bluetooth stack
    err = bluetooth_init();
    if (err)
    {
        ESP_LOGE(TAG, "esp32_bluetooth_init failed (err %d)", err);
        return err;
    }

    //* Get full device UUID
    ble_mesh_get_dev_uuid(dev_uuid);

    //* Register Model's callback functions
    esp_ble_mesh_register_prov_callback(ble_mesh_provisioning_cb);
    esp_ble_mesh_register_config_server_callback(ble_mesh_config_server_cb);

    esp_ble_mesh_register_custom_model_callback(ble_mesh_custom_sensor_server_model_cb);

    //* Set device name with MAC address
    set_mac_address();
    set_provision_name();

    //* Initializes BLE Mesh stack
    err = esp_ble_mesh_init(&provision, &composition);
    if (err)
    {
        ESP_LOGE(TAG, "Initializing mesh failed (err %d)", err);
        return err;
    }

    //* Set device name
    esp_ble_mesh_set_unprovisioned_device_name(_server_model_state.device_name);

    //* Enable provisioning
    esp_ble_mesh_node_prov_enable(ESP_BLE_MESH_PROV_ADV | ESP_BLE_MESH_PROV_GATT);

    set_ble_mesh_addr();

    ESP_LOGI(TAG, "BLE Mesh Node initialized!");

    return err;
}
