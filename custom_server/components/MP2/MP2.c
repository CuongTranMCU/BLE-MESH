#include "MP2.h"

static const char *TAG = "ADC_CAL";
static float R0 = 8.00f;
static adc_cali_handle_t adc_cali_handle = NULL;

#define VOLTAGE_DIVIDER_RATIO (3.3f / 5.0f) // Scaling factor for 5V to 3.3V

// Initialize ADC calibration for ESP32-C6
static bool Init_ADC_Calibration(void)
{
    adc_cali_curve_fitting_config_t cali_config = {
        .unit_id = ADC_UNIT_1,
        .atten = ADC_ATTEN,
        .bitwidth = ADC_WIDTH,
    };

    esp_err_t ret = adc_cali_create_scheme_curve_fitting(&cali_config, &adc_cali_handle);
    if (ret == ESP_OK)
    {
        ESP_LOGI(TAG, "ADC calibration initialized successfully");
        return true;
    }
    else
    {
        ESP_LOGE(TAG, "Failed to initialize ADC calibration: %s", esp_err_to_name(ret));
        return false;
    }
}

// Read ADC value and convert to voltage
int Get_ADCValue_MP2(void)
{
    uint32_t adc_reading = 0;
    for (int i = 0; i < 10; i++)
    {
        adc_reading += adc1_get_raw((adc1_channel_t)ADC_CHANNEL);
    }
    adc_reading /= 10;

    uint32_t voltage = 0;
    if (adc_cali_handle)
    {
        esp_err_t ret = adc_cali_raw_to_voltage(adc_cali_handle, adc_reading, &voltage);
        if (ret != ESP_OK)
        {
            ESP_LOGE(TAG, "Failed to convert ADC reading to voltage: %s", esp_err_to_name(ret));
            voltage = 0;
        }
    }
    return voltage;
}

// Initialize MQ7 sensor
void Init_MP2(void)
{
    // Configure ADC
    adc1_config_width(ADC_WIDTH);
    adc1_config_channel_atten((adc1_channel_t)ADC_CHANNEL, ADC_ATTEN);

    // Initialize calibration
    if (!Init_ADC_Calibration())
    {
        ESP_LOGE(TAG, "ADC calibration failed. Continuing without calibration.");
    }

    // Get initial ADC value and calculate R0
    int adcValue = Get_ADCValue_MP2();
    float Vrl = (3.3f * adcValue / 4096.0f) / VOLTAGE_DIVIDER_RATIO;
    float RS = (5.0f - Vrl) / Vrl * RL; // Use 5V for sensor voltage
    R0 = RS / pow(CAL_PPM / 943.0f, 1.0f / -2.45f);
}

// Get smoke PPM
float MP2_GetSmokePPM(void)
{
    float Vrl = (3.3f * Get_ADCValue_MP2() / 4096.0f) / VOLTAGE_DIVIDER_RATIO;
    float RS = (5.0f - Vrl) / Vrl * RL; // Use 5V for sensor voltage
    float ppm = 943.0f * pow(RS / R0, -2.45f);
    return ppm;
}

// Clean up calibration
void Deinit_ADC_Calibration(void)
{
    if (adc_cali_handle)
    {
        adc_cali_delete_scheme_curve_fitting(adc_cali_handle);
    }
}