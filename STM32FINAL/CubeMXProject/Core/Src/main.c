/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file           : main.c
  * @brief          : Main program body
  ******************************************************************************
  * @attention
  *
  * Copyright (c) 2024 STMicroelectronics.
  * All rights reserved.
  *
  * This software is licensed under terms that can be found in the LICENSE file
  * in the root directory of this software component.
  * If no LICENSE file comes with this software, it is provided AS-IS.
  *
  ******************************************************************************
  */
/* USER CODE END Header */
/* Includes ------------------------------------------------------------------*/
#include "main.h"
#include "tim.h"
#include "usart.h"
#include "gpio.h"
#include "fsmc.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */
#include "lcd.h"
#include "stdio.h"
#include "stdbool.h"
#include "string.h"
#include "arm_const_structs.h"
#include "arm_math.h"
#include "key.h"

/* USER CODE END Includes */

/* Private typedef -----------------------------------------------------------*/
/* USER CODE BEGIN PTD */
#define   RXBUFF_SIZE              32           //定义接收数据的深度

/* USER CODE END PTD */

/* Private define ------------------------------------------------------------*/
/* USER CODE BEGIN PD */

/* USER CODE END PD */

/* Private macro -------------------------------------------------------------*/
/* USER CODE BEGIN PM */

/* USER CODE END PM */

/* Private variables ---------------------------------------------------------*/

/* USER CODE BEGIN PV */
/*============================= 全局变量定义 ==================================*/
uint8_t Lcd_String[20];     		 //LCD输出的字符串
uint16_t value = 0;

uint8_t rxBuffer[RXBUFF_SIZE];
uint8_t rxChar;                  //定义接收单个字节的数据
uint16_t rxIndex;
uint8_t dataLength = 0;  // 数据长度
uint8_t receivingData = 0;  // 标志位，表示是否正在接收数据帧

/*-------------------------解析的数据------------------------------*/
uint8_t modeType;
uint32_t frequency;
uint32_t modDepth;
double modDepth_double_mf_h;
double modDepth_double_ma;
uint32_t deltaFreq;
uint8_t old_modeType=0;

/* USER CODE END PV */

/* Private function prototypes -----------------------------------------------*/
void SystemClock_Config(void);
/* USER CODE BEGIN PFP */

/* USER CODE END PFP */

/* Private user code ---------------------------------------------------------*/
/* USER CODE BEGIN 0 */


/* USER CODE END 0 */

/**
  * @brief  The application entry point.
  * @retval int
  */
int main(void)
{
  /* USER CODE BEGIN 1 */

  /* USER CODE END 1 */

  /* MCU Configuration--------------------------------------------------------*/

  /* Reset of all peripherals, Initializes the Flash interface and the Systick. */
  HAL_Init();

  /* USER CODE BEGIN Init */

  /* USER CODE END Init */

  /* Configure the system clock */
  SystemClock_Config();

  /* USER CODE BEGIN SysInit */

  /* USER CODE END SysInit */

  /* Initialize all configured peripherals */
  MX_GPIO_Init();
  MX_FSMC_Init();
  MX_USART1_UART_Init();
  MX_TIM3_Init();
  /* USER CODE BEGIN 2 */
	/*============================= 模块初始化 ==================================*/
	lcd_init(); 	
	
	HAL_TIM_Base_Start_IT(&htim3);          //开启普通中断定时器,用于按键延时
  HAL_UART_Receive_IT(&huart1, (uint8_t *)&rxChar, 1);	 //开启串口中断


  /* USER CODE END 2 */

  /* Infinite loop */
  /* USER CODE BEGIN WHILE */
  while (1)
  {
    /* USER CODE END WHILE */

    /* USER CODE BEGIN 3 */
		key_set_value(&value);

		//串口发送测试
//		HAL_UART_Transmit(&huart1, (uint8_t *)"hello windows!\r\n", 16 , 0xffff);
//		HAL_Delay(1000);  //延时1s
		
		modDepth_double_mf_h=(double)modDepth/10;
		modDepth_double_ma=(double)modDepth/100;


		
		/*--------------------------LCD显示-------------------------------*/		
		lcd_show_string(10, 40, 240, 32, 32, "2023D", BLACK);
		if(old_modeType!=modeType)
		{
			lcd_clear(WHITE);
			old_modeType=modeType;
		}
		switch(modeType)
		{
				case 1:
				{
					lcd_show_string(10, 80, 300, 24, 24, "Modulation Types: AM ", BLUE);
					sprintf((char *)Lcd_String, "Demod Frequency: %ukHz    ", frequency/1000); 
					lcd_show_string(10, 120, 300, 24, 24, (char *)Lcd_String, BLUE);	
					sprintf((char *)Lcd_String, "Ma: %0.2f", modDepth_double_ma); 
					lcd_show_string(10, 160, 300, 24, 24, (char *)Lcd_String, BLUE);
				}break;
				
				case 2:
				{
					lcd_show_string(10, 80, 300, 24, 24, "Modulation Types: ASK", BLUE);
					sprintf((char *)Lcd_String, "Rc: %ukbs    ", frequency/1000 * 2); 
					lcd_show_string(10, 120, 300, 24, 24, (char *)Lcd_String, BLUE);
				}break;
										
				case 3:
				{
					lcd_show_string(10, 80, 300, 24, 24, "Modulation Types: FM ", BLUE);
					sprintf((char *)Lcd_String, "Demod Frequency: %ukHz    ", frequency/1000); 
					lcd_show_string(10, 120, 300, 24, 24, (char *)Lcd_String, BLUE);		
					sprintf((char *)Lcd_String, "Mf: %0.1f", modDepth_double_mf_h); 
					lcd_show_string(10, 160, 300, 24, 24, (char *)Lcd_String, BLUE);
					sprintf((char *)Lcd_String, "delta_f_max: %uHz", deltaFreq*100); 
					lcd_show_string(10, 200, 300, 24, 24, (char *)Lcd_String, BLUE);
				}break;	
				
				case 4:
				{
					lcd_show_string(10, 80, 300, 24, 24, "Modulation Types: FSK", BLUE);
					sprintf((char *)Lcd_String, "Demod Frequency: %ukbs    ", frequency/1000 * 2); 
					lcd_show_string(10, 120, 300, 24, 24, (char *)Lcd_String, BLUE);	
					sprintf((char *)Lcd_String, "h: %0.1f", modDepth_double_mf_h ); 
					lcd_show_string(10, 160, 300, 24, 24, (char *)Lcd_String, BLUE);
				}break;	
				
				case 5:
				{
					lcd_show_string(10, 80, 300, 24, 24, "Modulation Types: PSK", BLUE);
					sprintf((char *)Lcd_String, "Demod Frequency: %ukbs    ", frequency/1000 *2); 
					lcd_show_string(10, 120, 300, 24, 24, (char *)Lcd_String, BLUE);			
				}break;
				
				case 6:
				{
					lcd_show_string(10, 80, 300, 24, 24, "Modulation Types: CW ", BLUE);
					sprintf((char *)Lcd_String, "Demod Frequency: NONE     "); 
					lcd_show_string(10, 120, 300, 24, 24, (char *)Lcd_String, BLUE);					
				}break;
				
				default:
				{
					lcd_show_string(10, 80, 300, 24, 24, "Modulation Types: CW ", BLUE);
					sprintf((char *)Lcd_String, "Demod Frequency: NONE     "); 
					lcd_show_string(10, 120, 300, 24, 24, (char *)Lcd_String, BLUE);				
				}
		}
		
//		sprintf((char *)Lcd_String, "Demod_Type: %d      ", modeType); 
//		lcd_show_string(10, 80, 240, 24, 24, (char *)Lcd_String, BLUE); 		
  }
  /* USER CODE END 3 */
}

/**
  * @brief System Clock Configuration
  * @retval None
  */
void SystemClock_Config(void)
{
  RCC_OscInitTypeDef RCC_OscInitStruct = {0};
  RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};

  /** Configure the main internal regulator output voltage
  */
  __HAL_RCC_PWR_CLK_ENABLE();
  __HAL_PWR_VOLTAGESCALING_CONFIG(PWR_REGULATOR_VOLTAGE_SCALE1);

  /** Initializes the RCC Oscillators according to the specified parameters
  * in the RCC_OscInitTypeDef structure.
  */
  RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSE;
  RCC_OscInitStruct.HSEState = RCC_HSE_ON;
  RCC_OscInitStruct.PLL.PLLState = RCC_PLL_ON;
  RCC_OscInitStruct.PLL.PLLSource = RCC_PLLSOURCE_HSE;
  RCC_OscInitStruct.PLL.PLLM = 8;
  RCC_OscInitStruct.PLL.PLLN = 336;
  RCC_OscInitStruct.PLL.PLLP = RCC_PLLP_DIV2;
  RCC_OscInitStruct.PLL.PLLQ = 4;
  if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK)
  {
    Error_Handler();
  }

  /** Initializes the CPU, AHB and APB buses clocks
  */
  RCC_ClkInitStruct.ClockType = RCC_CLOCKTYPE_HCLK|RCC_CLOCKTYPE_SYSCLK
                              |RCC_CLOCKTYPE_PCLK1|RCC_CLOCKTYPE_PCLK2;
  RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_PLLCLK;
  RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;
  RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV4;
  RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV2;

  if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_5) != HAL_OK)
  {
    Error_Handler();
  }
}

/* USER CODE BEGIN 4 */
/*============================= 数据解析程序 ================================*/
// 修改后的解析数据帧函数，传入频率和种类指针
void parse_data_frame(uint8_t *rxBuffer, uint8_t *modType, uint32_t *frequency, uint32_t *modDepth, uint32_t *deltaFreq)
{
    if (rxBuffer[0] == 0xAD)  // 校验包头
    {
        uint8_t dataLength = rxBuffer[1];  // 获取数据长度
        if (dataLength == 0x0C)  // 校验数据长度
        {
            *modType = rxBuffer[2] - '0';  // 获取调制种类并更新指针

					char freq_str[5] = {0};  // 频率字符串，最后一位放 '\0'
					freq_str[0] = rxBuffer[3];  // '1'
					freq_str[1] = rxBuffer[4];  // '3'
					freq_str[2] = rxBuffer[5];  // '8'
					freq_str[3] = rxBuffer[6];  // '8'
					*frequency = (uint16_t)strtol(freq_str, NULL, 16);
					char Depth_str [5] = {0};  // 频率字符串，最后一位放 '\0'
					Depth_str[0] = rxBuffer[7];  // '1'
					Depth_str[1] = rxBuffer[8];  // '3'
					*modDepth = (uint16_t)strtol(Depth_str, NULL, 16);
					char Delta_str [5] = {0};  // 频率字符串，最后一位放 '\0'
					Delta_str[0] = rxBuffer[9];  // '1'
					Delta_str[1] = rxBuffer[10];  // '3'
					*deltaFreq = (uint16_t)strtol(Delta_str, NULL, 16);
				}
		}
}		
		
/*============================= 串口中断程序 ================================*/
void HAL_UART_RxCpltCallback(UART_HandleTypeDef *huart)
{
    if(huart->Instance == USART1)
    {
        if(rxChar == 0xAD)  // 检查包头
        {
            rxIndex = 0;  // 重置接收索引
            receivingData = 1;  // 开始接收数据
            rxBuffer[rxIndex++] = rxChar;  // 存储包头
        }
        else if (receivingData)
        {
            rxBuffer[rxIndex++] = rxChar;  // 存储数据

            // 确保数据帧长度合法，避免数组越界
            if (rxIndex >= sizeof(rxBuffer))  
            {
                receivingData = 0;  // 停止接收，防止溢出
                rxIndex = 0;  
            }
            // 检查是否接收完整帧
            else if (rxIndex == rxBuffer[1])  // 包头 + 数据长度
            {
                receivingData = 0;  // 停止接收
                parse_data_frame(rxBuffer, &modeType, &frequency, &modDepth, &deltaFreq);  // 解析数据

                // 清空 rxBuffer
                memset(rxBuffer, 0, sizeof(rxBuffer));
                rxIndex = 0;
            }
        }
        // 继续开启 UART 接收中断
        HAL_UART_Receive_IT(&huart1, (uint8_t *)&rxChar, 1);
    }
}




/* USER CODE END 4 */

/**
  * @brief  This function is executed in case of error occurrence.
  * @retval None
  */
void Error_Handler(void)
{
  /* USER CODE BEGIN Error_Handler_Debug */
  /* User can add his own implementation to report the HAL error return state */
  __disable_irq();
  while (1)
  {
  }
  /* USER CODE END Error_Handler_Debug */
}

#ifdef  USE_FULL_ASSERT
/**
  * @brief  Reports the name of the source file and the source line number
  *         where the assert_param error has occurred.
  * @param  file: pointer to the source file name
  * @param  line: assert_param error line source number
  * @retval None
  */
void assert_failed(uint8_t *file, uint32_t line)
{
  /* USER CODE BEGIN 6 */
  /* User can add his own implementation to report the file name and line number,
     ex: printf("Wrong parameters value: file %s on line %d\r\n", file, line) */
  /* USER CODE END 6 */
}
#endif /* USE_FULL_ASSERT */
