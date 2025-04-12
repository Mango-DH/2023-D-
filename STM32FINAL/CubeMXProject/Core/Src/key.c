#include "key.h"

// 定义按键结构体数组
struct Keys key[3] = {0, 0, 0, 0,0};
void HAL_TIM_PeriodElapsedCallback(TIM_HandleTypeDef *htim)  //1ms
{	
    if (htim->Instance == TIM3)
    {
			   // 读取按键当前状态
        key[0].key_sta = HAL_GPIO_ReadPin(GPIOE, GPIO_PIN_4);
        key[1].key_sta = HAL_GPIO_ReadPin(GPIOE, GPIO_PIN_3);
        key[2].key_sta = HAL_GPIO_ReadPin(GPIOE, GPIO_PIN_2);	
    }
		for(uint8_t i=0; i<3;i++)
		{
			switch(key[i].judeg_sta)
			{
				case 0:
				{	
					if(key[i].key_sta==0)key[i].judeg_sta=1;
				}break;
				
				case 1:
				{	
					if(key[i].key_sta==0)
					{
						key[i].judeg_sta=2;
					}		
					else key[i].judeg_sta=0;  
				}break;
				
				
				case 2:    
				{	
					if(key[i].key_sta==1)
					{
						key[i].judeg_sta=0;
						if(key[i].key_time<40)key[i].short_flag=1;
						key[i].key_time=0;	
					}	
					
					else   
					{
						key[i].key_time++;
						if(key[i].key_time>30)
						{
							key[i].long_flag=1;
							key[i].key_time = 0;
						}
					}break;
				}
			}		
		}
}

// 外界变量设置函数
bool key_set_value(uint16_t *value)
{
    if (key[0].long_flag == 1) // 确认按键
    {
        key[0].long_flag = 0;
        return true;
    }
    else if (key[1].long_flag == 1) // 减小按键
    {
        key[1].long_flag = 0;
        *value = (*value >= 5) ? (*value - 5) : 0; // 防止相位值下溢
    }
    else if (key[2].long_flag == 1) // 增大按键
    {
        key[2].long_flag = 0;
        *value = (*value <= 175) ? (*value + 5) : 180; // 限制最大相位值
    }
    return false;
}
