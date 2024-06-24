#include "MQ7.h"
static float R0 = 8.00;
// Đọc giá trị ADC từ MQ7
int Get_ADCValue_MQ7(void) {
    uint32_t adc_reading = 0;
    for (int i = 0; i < 10; i++) {
        adc_reading += adc1_get_raw((adc1_channel_t)ADC_CHANNEL); 
    }
    adc_reading /= 10;
    // Chuyển đổi giá trị ADC thô sang điện áp
    uint32_t voltage = esp_adc_cal_raw_to_voltage(adc_reading, adc_chars);
    return voltage;
}
// Khởi tạo MQ7
void Init_MQ7(void) {
    adc1_config_width(ADC_WIDTH);// 12 bit: => 4096
    adc1_config_channel_atten(ADC_CHANNEL, ADC_ATTEN); // adc_atten: ADC_ATTEN_DB_11

    // Tạo bộ nhớ cho đặc tính hiệu chuẩn ADC
    adc_chars = calloc(1, sizeof(esp_adc_cal_characteristics_t));
    esp_adc_cal_value_t val_type = esp_adc_cal_characterize(ADC_UNIT_1, ADC_ATTEN, ADC_WIDTH, DEFAULT_VREF, adc_chars);
    int adcValue = Get_ADCValue_MQ7();
    float Vrl = 3.3f * adcValue / 4096.f;
    float RS = (3.3f - Vrl) / Vrl * RL;
    R0 = RS /pow(CAL_PPM / 98.43, 1 / -1.523f); 
}
// Lấy giá trị PPM của khí CO từ cảm biến MQ7
float MQ7_GetPPM(void) {
    float Vrl = 3.3f * Get_ADCValue_MQ7() / 4096.f; 
    float RS = (3.3f - Vrl) / Vrl * RL;
    float ppm = 98.43f * pow(RS/R0, -1.523f);
    return ppm;
}