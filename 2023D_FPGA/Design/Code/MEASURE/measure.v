module measure #(
	parameter N=8
	)(
	input clk,
	input sample_en,
	input rst_n,
	input [N-1:0] signal_in_unsigned,
	input ma_measure_enable,
	input mf_measure_enable,
	
    output is_sine_wave,      		// 1=正弦波，0=方波
	output [15:0] freq_out,
	output [N-1:0]papr,				//峰均功率比
	output unsigned[N-1:0] vpp,
	output unsigned[N-1:0] dc_offset, 
    output [12:0] f_offset_max,
	output [7:0] ma,
	output [7:0] mf 
);

    wire signed[N-1:0] signal_dc_removed;   	// 去除直流分量后得到的信号
 	wire signal_rectified;
	wave_cal #(
		.N(N),               			// 数据位宽
		.SAMPLE_POINTS(512), 			// 采样点数
		.LOG_2_SAMPLE_POINTS(9),
		.JUDGE_THRESHOLD(700),   		// 判断阈值
		.FRE_DIV(249)
	)wave_cal_inst(
		.clk(clk),
	    .rst_n(rst_n),                		
	    .data_in_unsigned(signal_in_unsigned),	
	    
	    .signal_dc_removed(signal_dc_removed),	
	    .vpp(vpp),				
		.dc_offset(dc_offset),
		.papr(papr),   					
	    .is_sine_wave(is_sine_wave)   					
	);
	
	//波形整流模块
 	wave_rectifier #(.N(N)) wave_rectifier_inst(
		.clk(clk),                  	
		.rst_n(rst_n),                 	
		.signal_dc_removed(signal_dc_removed),
		.signal_rectified(signal_rectified)  
	);	  

	//频率测量
	frequency_counter #(
		.MEASURE_CLK_CNT(400),
		.MEASURE_CLK(20000)     //采样频率
	)frequency_counter_inst(	//5ms内计数的个数，即计数时钟的频率 
		.clk(sample_en),                		// 测频时钟
		.rst_n(rst_n),              			// 复位信号
		.signal_in(signal_rectified),          	// 输入整流后的信号
		.freq_out(freq_out)				 		// 输出频率值
	);
		
	//调制度测量
	ma_measure #(
		.N(N)
	)ma_measure_inst(
		.clk(sample_en),       //调制度测量时钟   
		.rst_n(rst_n),   
		.ma_measure_enable(is_sine_wave & ma_measure_enable),
		.vpp(vpp),
		.ma(ma) 
	); 
		//调制度测量
	mf_measure #(
		.N(N)
	)mf_measure_inst(
		.clk(sample_en),       //调制度测量时钟   
		.rst_n(rst_n),   
		.mf_measure_enable(mf_measure_enable),
		.fm_freq(freq_out),
		.vpp(vpp),
		.f_offset_max(f_offset_max),
		.mf(mf) 
	); 
	
endmodule