#ifndef __KEY_H_
#define __KEY_H_
#define uint unsigned int
#define uchar unsigned char

#include "main.h"
#include "stdbool.h"

struct Keys
{
	uint8_t judeg_sta;
	bool key_sta;    
	bool short_flag;
	uint8_t key_time;
	bool long_flag;
};

void HAL_TIM_PeriodElapsedCallback(TIM_HandleTypeDef *htim);
bool key_set_value(uint16_t *value);  

#endif
