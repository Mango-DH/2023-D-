`timescale 1ns / 1ps

module top(
	/******************** Global Value *********************/
	input 	sys_clk ,     			//系统时钟
	input	sys_rst_n ,  		 	//系统复位，低电平有效	
	
	/******************** AD/DA IO *********************/	
	output 	da_clk , 				//DA(AD9708)驱动时钟,最大支持 125Mhz 时钟
	output 	ad_clk ,				//AD(AD9280)驱动时钟,最大支持 32Mhz 时钟
	output 	[7:0] da_data , 		//输出给 DA 的数据
	input   [7:0] ad_data , 		//AD 输入数据

	/******************** UART IO *********************/	
	input 	uart_rx,     		 	//fpga receive data
	output 	uart_tx,     			//fpga send data
	
	/******************** LED IO *********************/	
	output [3:0] led
	
);
	/******************** Parameter *********************/
	
	/****************** 输入信号去直流 *********************/	
	wire signed [7:0] ad_data_dc_removed;
	assign ad_data_dc_removed = ad_data - 128;
	


	/********************wire define *********************/	
	wire [7:0] ma;
	wire [7:0] mf;
	wire [12:0] f_offset_max;
	reg [7:0] uart_mod_depth;
	reg [7:0] uart_delta_freq;
	wire ask_is_sine_wave;
	wire fsk_is_sine_wave;

	wire unsigned[7:0] askdemod_data;       //AM解调得到的波形
	wire unsigned[8:0] fskdemod_data_9;       //AM解调得到的波形
	wire unsigned[9:0] fskdemod_data_10;       //AM解调得到的波形
	wire unsigned[7:0] pskdemod_data;       //PSK解调得到的波形
	wire unsigned[7:0] demod_data;			//最终输出的数据

	wire unsigned[7:0] askdemod_vpp;
	wire unsigned[9:0] fskdemod_vpp;
	wire unsigned[7:0] pskdemod_vpp;

	wire unsigned[7:0] askdemod_dc_offset;

	wire unsigned[7:0] ask_papr;			//fsk解调通道的峰均功率比
	wire unsigned[9:0] fsk_papr;			//fsk解调通道的峰均功率比
	wire unsigned[7:0] psk_papr;			//fsk解调通道的峰均功率比

	wire [15:0] ask_freq_out;
	wire [15:0] fsk_freq_out;
	wire [15:0] psk_freq_out;

	wire [7:0]  uart_mod_type;    					//调制模式
	wire [15:0] uart_demod_fre;						//输出解调信号的频率
	
	wire [39:0] fir_data_out;

	/******************** ILA ip核 逻辑分析仪 *********************/	
	ila_sys ila_0_inst (
		.clk		(sys_clk), 						//输入时钟					
		.probe0		(fskdemod_vpp),				 
		.probe1		(fsk_papr),
		.probe2		(fskdemod_data)
	); 

	/******************** 信号的输入与输出 *********************/	
	//例化AD模块和DA模块
	ad_da_test ad_da_test_inst(
		.clk			(sys_clk), 
		.rst_n			(sys_rst_n), 
		.da_data		(da_data), 
		.ad_data		(ad_data),
		.demod_data     (demod_data),
		.da_clk			(da_clk), 
		.ad_clk			(ad_clk) 
	);	

	/******************** 信号解调 *********************/	
 	//例化AM解调模块
	askdemod askdemod_inst(
		.clk					(sys_clk),  		//50MHz
		.rst_n					(sys_rst_n),
		.data_in				(ad_data_dc_removed),
		.data_out				(askdemod_data)		//解调信号输出
   ); 	

	//例化FSK解调模块
	fskdemod fskdemod_inst(
		.clk					(sys_clk),
		.rst_n					(sys_rst_n),
		.data_in				(ad_data_dc_removed),
		.fir_data_out 			(fir_data_out),
		.data_out_9				(fskdemod_data_9),
		.data_out_10			(fskdemod_data_10)
	);

    //例化PSK解调模块
	pskdemod pskdemod_inst(
		.clk				    (sys_clk),  		//50MHz
		.rst_n			        (sys_rst_n),
		.signal_in	            (ad_data_dc_removed),
		.data_out	            (pskdemod_data)	//解调信号输出
    ); 	

	/******************** 参数计算 *********************/	
	//分频模块
	wire sample_en;							 //40kHz分频得到的信
	clk_divider #(.FRE_DIV (2499))clk_divider_inst(
		.clk(sys_clk),                // 输入时钟（50 MHz）
		.rst_n(sys_rst_n),              // 异步复位信号（低电平有效）
		.sample_en(sample_en)      // 采样使能信号
	);

	//ASK解调信号参数计算
	measure #(
		.N(8)
	)measure_ask(
		.clk                    (sys_clk),
		.sample_en				(sample_en),
		.rst_n                  (sys_rst_n),
		.signal_in_unsigned     (askdemod_data),
		.ma_measure_enable      (1),                  			//是否计算Ma
        .mf_measure_enable      (0),  
        
		.is_sine_wave           (ask_is_sine_wave),      		// 1=正弦波，0=方波
		.freq_out               (ask_freq_out),
		.papr					(ask_papr),
		.vpp                    (askdemod_vpp),
		.dc_offset				(askdemod_dc_offset),
		.f_offset_max           (),
		.ma                     (ma),
		.mf                     ()
	);

	//FSK解调信号参数计算
	measure #(
		.N(9)
	)measure_fsk(
		.clk                    (sys_clk),
		.sample_en				(sample_en),
		.rst_n                  (sys_rst_n),
		.signal_in_unsigned     (fskdemod_data_9),
		.ma_measure_enable      (0),                  //计算解调参数
		.mf_measure_enable      (1),

		.is_sine_wave           (fsk_is_sine_wave),   // 1=正弦波，0=方波
		.freq_out               (fsk_freq_out),
		.papr					(fsk_papr),
		.vpp                    (fskdemod_vpp),
		.f_offset_max           (f_offset_max),
		.ma                     (),
		.mf                     (mf)
	);
	
	//PSK解调信号参数计算
	measure #(
		.N(8)
	)measure_psk(
		.clk                    (sys_clk),
		.sample_en				(sample_en),
		.rst_n                  (sys_rst_n),
		.signal_in_unsigned     (pskdemod_data),
		.ma_measure_enable      (0),                //计算解调参数
        .mf_measure_enable      (0),
        
		.is_sine_wave           (),      			// 1=正弦波，0=方波
		.freq_out               (psk_freq_out),
		.papr					(psk_papr),
		.vpp                    (pskdemod_vpp),
		.f_offset_max           (),
		.ma                     (),
		.mf                     ()
	);

	/******************** 输出信号选择 *********************/	
	//选择要输出的解调信号，发送给串口的数据
	data_sele data_sele_inst(
    	.sys_clk				(sys_clk),
    	.sys_rst_n				(sys_rst_n),
    	.askdemod_vpp			(askdemod_vpp),
   		.fskdemod_vpp			(fskdemod_vpp),
    	.pskdemod_vpp			(pskdemod_vpp),

		.ask_papr				(ask_papr),
		.fsk_papr				(fsk_papr),
		.psk_papr				(psk_papr),
		.askdemod_dc_offset		(askdemod_dc_offset),
		.ask_is_sine_wave		(ask_is_sine_wave),
		.fsk_is_sine_wave		(fsk_is_sine_wave),

		.askdemod_data			(askdemod_data),
		.fskdemod_data			(fskdemod_data_10),
		.pskdemod_data			(pskdemod_data),
		
		.ma						(ma),
		
		.ask_freq_out			(ask_freq_out),
		.fsk_freq_out			(fsk_freq_out),
 		.psk_freq_out      		(psk_freq_out),
		.fir_data_out			(fir_data_out),
		.demod_data				(demod_data),			//输出解调信号
		.uart_mod_type			(uart_mod_type),		//判断解调信号的种类
    	.uart_demod_fre			(uart_demod_fre)
	);

	
	//例化UART模块
	uart_test uart_test_inst (
		.clk					(sys_clk),
		.rst_n  				(sys_rst_n), 
		.uart_mod_type			(uart_mod_type),
		.uart_demod_fre 		(uart_demod_fre),
		.uart_mod_depth         (uart_mod_depth),
		.uart_delta_freq         (uart_delta_freq),
		.uart_rx				(uart_rx),
		.uart_tx				(uart_tx) 
	);		
    always @(posedge sys_clk or negedge sys_rst_n)begin
        if(!sys_rst_n) begin
            uart_mod_depth <= 0;
            uart_delta_freq <= 0;
        end
        else if(uart_mod_type==1)
            uart_mod_depth <= ma;
	    else if(uart_mod_type==3||uart_mod_type==4)begin
            uart_mod_depth <= mf;
            if(uart_mod_type==3)
                uart_delta_freq <= fskdemod_vpp;
        end
        else begin 
            uart_mod_depth <= 0;
            uart_delta_freq <= 0;
        end 
    end
	// //例化LED模块
	// led_test led_test_inst(
	// 	.clk			(sys_clk), 		
	// 	.rst_n			(sys_rst_n), 		
	// 	.led			(led)
	// );
	
endmodule
