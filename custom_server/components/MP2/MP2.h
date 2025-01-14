#include "driver/adc.h"
#include "esp_log.h"
#include "esp_err.h"
#include "esp_adc/adc_cali.h"
#include "esp_adc/adc_cali_scheme.h"
#include <math.h>
#include <stdlib.h>
#define ADC_CHANNEL ADC1_CHANNEL_1 // Example: GPIO34
#define ADC_WIDTH ADC_WIDTH_BIT_12
#define ADC_ATTEN ADC_ATTEN_DB_11
#define DEFAULT_VREF 1100          // Default reference voltage in mV
#define RL 10.0f                   // Load resistor value in kΩ
#define CAL_PPM 100.0f             // Calibration PPM value

// Cấu hình ADC (thay đổi các giá trị này cho phù hợp với phần cứng của bạn)
#define ADC_CHANNEL ADC1_CHANNEL_1
#define ADC_ATTEN ADC_ATTEN_DB_11
#define ADC_WIDTH ADC_WIDTH_BIT_12
#define DEFAULT_VREF 1100 // Sử dụng giá trị mặc định của ESP32// điện áp mặc định của ADC là 1.1V

int Get_ADCValue_MP2(void);
void Init_MP2(void);
float MP2_GetSmokePPM(void);