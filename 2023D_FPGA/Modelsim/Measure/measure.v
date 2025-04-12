module measure (
	input clk,
	input rst_n,
	input [7:0] signal_in_unsigned,
	input ma_measure_enable,
	
    output is_sine_wave,      		// 1=正弦波，0=方波
	output [15:0] freq_out,
	output [31:0]papr,				// 峰均功率比
	output [7:0] ma 
	
);

    wire signed	[7:0] signal_dc_removed;   	// 去除直流分量后得到的信号
 	wire unsigned[7:0] dc_offset;   
	wire unsigned[7:0] vpp;
	wire sample_en;
 	wire signal_rectified;

	clk_divider #(.FRE_DIV (2499))clk_divider_inst(
		.clk(clk),                	// 输入时钟（50 MHz）
		.rst_n(rst_n),              // 异步复位信号（低电平有效）
		.sample_en(sample_en)      	// 采样使能信号
	);

	//去除直流的模块
	dc_remover #(
		.N(8),               					// 数据位宽
		.SAMPLE_POINTS(32),						// 采样点数
		.LOG_2_SAMPLE_POINTS(5)						
	)dc_remover_inst(
		.clk(clk),
		.sample_clk(sample_en),                	// 时钟信号
		.rst_n(rst_n),                			// 复位信号
		.data_in_unsigned(signal_in_unsigned),	// 无符号输入数据	
		
		.vpp(vpp),
		.dc_offset(dc_offset),           		// 直流分量	
		.signal_dc_removed(signal_dc_removed) 	// 去除直流分量后的有符号输出
	);
	
	//波形整流模块
 	wave_rectifier #(.N(8)) wave_rectifier_inst(
		.clk(clk),                  	
		.rst_n(rst_n),                 	
		.signal_dc_removed(signal_dc_removed),
		.signal_rectified(signal_rectified)  
	);	  

   	//波形判断模块
 	wave_identifier #(
		.JUDGE_THRESHOLD(700),
		.FRE_DIV(1249),
		.SAMPLE_POINTS (64),
		.LOG_2_SAMPLE_POINTS(6)	
	)wave_identifier_inst(
		.clk(clk),                		// 50 MHz 时钟
		.rst_n(rst_n),                				// 同步复位
		.signal_dc_removed(signal_dc_removed),		// 去除直流的信号
		.vpp(vpp),		  							// Vpp有直流信号
		.dc_offset(dc_offset), 
		
		.papr(papr),
 		.is_sine_wave(is_sine_wave)   				// 1=正弦波，0=方波
	); 
	
	//频率测量
	frequency_counter #(
		.MEASURE_CLK_CNT(200),
		.MEASURE_CLK(20000)     //采样频率
	)frequency_counter_inst(	//5ms内计数的个数，即计数时钟的频率 
		.clk(sample_en),                		// 测频时钟
		.rst_n(rst_n),              			// 复位信号
		.signal_in(signal_rectified),          	// 输入整流后的信号
		.freq_out(freq_out)				 		// 输出频率值
	);
		
	//调制度测量
	ma_measure ma_measure_inst(
		.clk(sample_en),       //调制度测量时钟   
		.rst_n(rst_n),   
		.ma_measure_enable(is_sine_wave & ma_measure_enable),
		.vpp(vpp),
		.ma(ma) 
	); 
	
endmodule