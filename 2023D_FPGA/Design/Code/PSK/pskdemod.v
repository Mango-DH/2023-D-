`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/16 11:49:59
// Design Name: 
// Module Name: PSK_DM
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module pskdemod(
    input clk,
    input rst_n,
	input signed [7:0] signal_in,    // 8bit 无符号输入信号 
    output [7:0] data_out
);
    wire signed [7:0]  PSK_data_signed;
    wire signed [7:0] carrier_out_signed;
    wire signed [15:0] mixed_PSK_data_signed;
    wire signed [39:0] fir_tdata_i;
    reg                		mixed_valid_r = 0;    // 相乘信号有效标志
    wire             		fir_tready_i;         // FIR 滤波器输入准备好信号
    wire              		fir_tvalid_i;         // FIR 滤波器输出有效信号
    reg [7:0] square_wave=0; // 输出的方波信号
//    //生成一个2PSK调制后波形以便仿真
//    psk_modulator uu_2PSK(
//    .clk(clk),
//    .rst_n(rst_n),
//	.signal_in(signal_in),
//    .data_in(prbs_data),
//    .psk_out(PSK_data_signed)
//    );
    costas_loop costas_loop_inst(
        .clk(clk),          // 时钟信号
        .rst_n(rst_n),       // 复位信号（低电平有效）
        .psk_in(signal_in), // 输入的2PSK信号（8位有符号）
        .carrier_out(carrier_out_signed) // 输出的恢复载波（8位有符号）
    );
    //乘法器相乘
    mult_gen_0	mult_gen_psk(
   	    .CLK	(clk),
   	    .A		(signal_in),
    	.B		(carrier_out_signed),
   	    .P		(mixed_PSK_data_signed)
	);
	
	always @(posedge clk) begin
        if (rst_n == 0) begin
            mixed_valid_r <= 0;
        end else 
            mixed_valid_r <= 1;
	end
	//低通滤波器滤波
    fir_lpf_psk fir_lpf_psk_psk1
    (
        .aclk                (clk),                // 时钟信号
        .s_axis_data_tvalid  (mixed_valid_r),      // 输入数据有效信号
        .s_axis_data_tready  (fir_tready_i),       // FIR 滤波器输入准备好信号
        .s_axis_data_tdata   (mixed_PSK_data_signed), // 输入数据（取高 8 位）
        .m_axis_data_tvalid  (fir_tvalid_i),       // FIR 滤波器输出有效信号
        .m_axis_data_tdata   (fir_tdata_i)         // FIR 滤波器输出数据
    );
    // 方波整形逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            square_wave <= 8'd0; // 复位时输出为0
        end else begin
            // 根据 fir_tdata_i 的符号位进行判决
            if (fir_tdata_i>0) begin // 判断符号位
                square_wave <= 249;  // 负值输出高电平
            end else begin
                square_wave <= 0; // 正值输出低电平
            end
        end
    end

    assign data_out = square_wave; // 输出方波信号
endmodule
