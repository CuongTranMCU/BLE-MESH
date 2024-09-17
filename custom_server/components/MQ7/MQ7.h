#include "driver/adc.h"
#include "esp_adc_cal.h"
#include "math.h"
#include <stdio.h>
#define CAL_PPM 10
#define RL 10

// Cấu hình ADC (thay đổi các giá trị này cho phù hợp với phần cứng của bạn)
#define ADC_CHANNEL ADC1_CHANNEL_6 
#define ADC_ATTEN ADC_ATTEN_DB_11
#define ADC_WIDTH ADC_WIDTH_BIT_12
#define DEFAULT_VREF 1100 // Sử dụng giá trị mặc định của ESP32// điện áp mặc định của ADC là 1.1V

extern esp_adc_cal_characteristics_t *adc_chars;
int Get_ADCValue_MQ7(void);
void Init_MQ7(void);
float MQ7_GetPPM(void);