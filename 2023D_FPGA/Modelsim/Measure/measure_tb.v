`timescale 1ns / 1ns

module measure_tb;
    reg clk;                				// 50 MHz 时钟
    reg rst_n;                				// 复位信号
    reg [7:0] signal_in_unsigned;   		// 8bit 无符号输入信号

    wire is_sine_wave;      		// 1=正弦波，0=方波
	wire [15:0] freq_out;
	wire [6:0] ma; 
	
    wire signed[7:0] signal_dc_removed;   	// 去除直流分量后得到的信号
 	wire unsigned[7:0] dc_offset;   
	wire unsigned[7:0] vpp;
 	wire signal_rectified;
	
	wire [31:0]papr;				// 峰均功率比



	//分频模块
	wire sample_en;
	clk_divider #(.FRE_DIV (2499))clk_divider_inst(
		.clk(clk),                	// 输入时钟（50 MHz）
		.rst_n(rst_n),              // 异步复位信号（低电平有效）
		.sample_en(sample_en)      	// 采样使能信号
	);
	
	wave_cal #(
		.N(8),               			// 数据位宽
		.SAMPLE_POINTS(128), 			// 采样点数
		.LOG_2_SAMPLE_POINTS(7)
		.JUDGE_THRESHOLD(700)   		// 判断阈值
	)wave_cal_inst(
		.clk(clk),
	    .sample_clk(sample_en),            
	    .rst_n(rst_n),                		
	    .data_in_unsigned(signal_in_unsigned),	
	    
	    .signal_dc_removed(signal_dc_removed),	
	    .vpp(vpp),				
		.papr(papr),   					
	    .is_sine_wave(is_sine_wave)   					
	);
	
 /*
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
		.SAMPLE_POINTS (32),
		.LOG_2_SAMPLE_POINTS(5)	
	)wave_identifier_inst(
		.sample_clk(sample_en),                		// 50 MHz 时钟
		.rst_n(rst_n),                				// 同步复位
		.signal_dc_removed(signal_dc_removed),		// 去除直流的信号
		.vpp(vpp),		  							// Vpp有直流信号
		.dc_offset(dc_offset), 
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
	);   */
	   
/* 	measure measure_inst(
		.clk(clk),
		.rst_n(rst_n),
		.signal_in_unsigned(signal_in_unsigned),
		.ma_measure_enable(1),
		
		.is_sine_wave(is_sine_wave),      		// 1=正弦波，0=方波
		.freq_out(freq_out),
		.papr(papr),
		.ma(ma) 
		
	);  */

	
    initial begin
        clk = 0;
        forever #10 clk = ~clk; // 50 MHz 时钟，周期为 20ns
    end

     
 // 测试过程
    initial begin
        rst_n = 0;
        signal_in_unsigned = 8'b0;  	
		#10; // 复位 10u
        rst_n = 1;   
		#10; // 等待 100ns 后开始生成信号

       
		repeat (2048*10) begin
            signal_in_unsigned = 40 + 25 * $sin(2 * 3.1415926 * $time / 200000); // 200us 周期
            #100; // 每个采样点间隔 20ns
        end 
		
		repeat (2048*10) begin
            signal_in_unsigned = 41 + 13 * $sin(2 * 3.1415926 * $time / 200000); // 200us 周期
            #100; // 每个采样点间隔 20ns
        end  
		
		
		
		repeat (2048*30) begin
            signal_in_unsigned = 40 + 40 * $sin(2 * 3.1415926 * $time / 333333); // 1000us 周期
            #100; // 每个采样点间隔 20ns
        end 
		
		repeat (2048*30) begin
            signal_in_unsigned = 40 + 25 * $sin(2 * 3.1415926 * $time / 333333); // 1000us 周期
            #100; // 每个采样点间隔 20ns
        end 
		
		repeat (2048*30) begin
            signal_in_unsigned = 41 + 13 * $sin(2 * 3.1415926 * $time / 333333); // 1000us 周期
            #100; // 每个采样点间隔 20ns
        end  
		
		repeat (2048*50) begin
            signal_in_unsigned = 40 + 40 * $sin(2 * 3.1415926 * $time / 1000000); // 1000us 周期
            #100; // 每个采样点间隔 20ns
        end 
		
		repeat (2048*50) begin
            signal_in_unsigned = 40 + 25 * $sin(2 * 3.1415926 * $time / 1000000); // 1000us 周期
            #100; // 每个采样点间隔 20ns
        end 
		
		repeat (2048*50) begin
            signal_in_unsigned = 41 + 13 * $sin(2 * 3.1415926 * $time / 1000000); // 1000us 周期
            #100; // 每个采样点间隔 20ns
        end  
		
		repeat (2048*50) begin
            signal_in_unsigned = 127 + 127* $sin(2 * 3.1415926 * $time / 1000000); // 1000us 周期
            #100; // 每个采样点间隔 20ns
        end  
		
		repeat (2048*50) begin
            signal_in_unsigned = 2 + 2* $sin(2 * 3.1415926 * $time / 1000000); // 1000us 周期
            #100; // 每个采样点间隔 20ns
        end  

        repeat (100) begin         
            signal_in_unsigned = 128; // 高电平
            #500000;            // 保持高电平 100us
            signal_in_unsigned = 0;  // 低电平
            #500000;            // 保持低电平 100us
        end 

		repeat (2048*10) begin
            signal_in_unsigned = 40 + 40 * $sin(2 * 3.1415926 * $time / 200000); // 200us 周期
            #100; // 每个采样点间隔 20ns
        end 
		

        repeat (100) begin         
            signal_in_unsigned = 79; // 高电平
            #500000;            // 保持高电平 100us
            signal_in_unsigned = 0;  // 低电平
            #500000;            // 保持低电平 100us
        end  
		 
		$stop; 
	end 
		 
/*        // 信号生成：DC → Noise → DC → Noise
	initial begin
		rst_n = 0;
		signal_in_unsigned = 8'b0;  	
		#10; // 复位 10u
		rst_n = 1;   
		#10; // 等待 100ns 后开始生成信号
	
		repeat (2048*50) begin
            signal_in_unsigned = 40 + 40 * $sin(2 * 3.1415926 * $time / 1000000); // 1000us 周期
            #100; // 每个采样点间隔 20ns
        end 
	
	    repeat (100) begin         
            signal_in_unsigned = 79; // 高电平
            #500000;            // 保持高电平 100us
            signal_in_unsigned = 0;  // 低电平
            #500000;            // 保持低电平 100us
        end  
	
		// 初始化
		signal_in_unsigned = 128;
		
		
		repeat (100) begin         
			signal_in_unsigned = 128;
			// 第一段：直流（DC）
			#100000;  // 保持100us直流
			
			// 第二段：噪声（Noise）
			generate_noise(50);  // 生成50个噪声样本
			
        end  
		
		$stop;
	end
	
	// 噪声生成任务
	task generate_noise(input integer samples);
		integer i;
		for (i=0; i<samples; i=i+1) begin
			signal_in_unsigned = $urandom_range(0, 255);  // 随机噪声（0~255）
			#1000;  // 每个噪声点持续1us
		end
	endtask  */

endmodule