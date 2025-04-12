module wave_identifier#(
    parameter JUDGE_THRESHOLD = 700,   // 判断阈值
	parameter FRE_DIV = 1249,			//分频系数
	parameter SAMPLE_POINTS = 64,		//采样点数
	parameter LOG_2_SAMPLE_POINTS = 6
	
) (
    input clk,           					// 20kHz 时钟
    input rst_n,                			// 同步复位
    input signed[7:0] signal_dc_removed,   	// 输入直流分量的信号
	input unsigned[7:0] vpp,
 	input unsigned[7:0] dc_offset,  
	   
	output reg [7:0]papr,   			// 输出papr
    output reg is_sine_wave   			// 1=正弦波，0=方波
);

	wire sample_clk;

	clk_divider #(.FRE_DIV (FRE_DIV))clk_divider_inst(
		.clk(clk),                	// 输入时钟（50 MHz）
		.rst_n(rst_n),              // 异步复位信号（低电平有效）
		.sample_en(sample_clk)      // 采样使能信号
	);

    reg signed[31:0] sum_squares = 0;			// 累加平方和
	reg signed[31:0] err_vpp_valid = 0;
    reg [9:0] sample_count = 0; 				// 计数

    wire signed[31:0] vpp_squared = vpp * vpp;     			 			 // Vpp2，最大255*255=65025
    wire signed[31:0] vpp_squared_scaled = vpp_squared >> 3; 			 // Vpp2/8 ≈ Vpp2>>3
    wire signed[31:0] valid = sum_squares >> LOG_2_SAMPLE_POINTS;    // Vrms2

    always @(posedge sample_clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_squares <= 32'd0;
            sample_count <= 10'd0;
            is_sine_wave <= 1'b0;
			papr <= 8'd0;
			
        end else begin      
			sample_count <= sample_count + 1'b1;
			if(dc_offset)sum_squares <= sum_squares + signal_dc_removed * signal_dc_removed;		
 
            if (sample_count == SAMPLE_POINTS - 1) begin      //到达采样点的时候
				if(valid)papr <= vpp_squared/valid;
				else papr <= 0;
			
				if(valid > vpp_squared_scaled) err_vpp_valid = valid - vpp_squared_scaled;
				else err_vpp_valid = vpp_squared_scaled - valid;
			
                if (err_vpp_valid < JUDGE_THRESHOLD) begin
                    is_sine_wave <= 1'b1;  // 正弦波
                end else begin
                    is_sine_wave <= 1'b0;  // 方波
                end
                sum_squares <= 32'd0;
                sample_count <= 10'd0;
            end
        end
    end

endmodule