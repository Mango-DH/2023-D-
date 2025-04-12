module dc_remover #(
    parameter N = 8,               			// 数据位宽
    parameter SAMPLE_POINTS = 8 , 			// 采样点数
	parameter LOG_2_SAMPLE_POINTS = 3  
)(
	input wire clk,
    input wire sample_clk,                	// 时钟信号
    input wire rst_n,                		// 复位信号
    input wire [N-1:0] data_in_unsigned,	// 无符号输入数据	
	
    output reg signed[N-1:0] signal_dc_removed,	// 去除直流分量后的有符号输出	
	output reg unsigned[N-1:0] vpp,				// 峰峰值 (最高位符号位去掉后就是unsigned类型数据位)
    output reg unsigned[N-1:0] dc_offset     	// 直流分量，采样计算结束的标志
);

    // 存储采样点
    reg [N-1:0] sampled_data [0:SAMPLE_POINTS-1];
    reg [LOG_2_SAMPLE_POINTS:0] sample_count; 	// 采样计数器
    reg unsigned[N-1:0]  max_value;           		// 最大值
    reg unsigned[N-1:0]  min_value;           		// 最小值


    // 采样过程
    always @(posedge sample_clk or negedge rst_n) begin
        if (!rst_n) begin
            sample_count <= 0;
            max_value <= 0;
            min_value <= {N{1'b1}};  // 初始化为最大值
			vpp <= 0;
			dc_offset <= 0;
			
        end else begin
            if (sample_count < SAMPLE_POINTS) begin
                sampled_data[sample_count] <= data_in_unsigned;
                if (data_in_unsigned > max_value) begin
                    max_value <= data_in_unsigned;
                end
				
                if (data_in_unsigned < min_value) begin
                    min_value <= data_in_unsigned;
                end
                sample_count <= sample_count + 1;
            end else begin
				vpp <= max_value - min_value;
                dc_offset <= ((max_value + min_value) >> 1);
				max_value <= 0;
				min_value <= {N{1'b1}};
                sample_count <= 0;  // 重置计数器
            end
        end
    end

	
    // 去除直流分量
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            signal_dc_removed <= 0;
        end else if (dc_offset) begin     //只要计算出直流分量的值
            signal_dc_removed <= data_in_unsigned - dc_offset;
        end
    end 
	

endmodule