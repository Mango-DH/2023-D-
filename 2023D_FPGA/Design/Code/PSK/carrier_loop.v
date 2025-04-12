`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/20 17:13:06
// Design Name: 
// Module Name: carrier_loop
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


module costas_loop (
    input wire clk,          // 时钟信号
    input wire rst_n,        // 复位信号（低电平有效）
    input signed [7:0] psk_in, // 输入的2PSK信号（8位有符号）
    output reg signed [7:0] carrier_out // 输出的恢复载波（8位有符号）
);

    // 参数定义
    parameter LOOP_GAIN = 8'd4;   // 环路增益
    parameter PHASE_INC = 32'd171_798_692; // 初始相位增量（根据时钟频率调整）

    // 内部信号
    reg [31:0] phase_accumulator=32'd0; // 相位累加器
    reg signed [7:0] sine_wave=0;   // 本地振荡器生成的正弦波
    reg signed [7:0] cosine_wave=0; // 本地振荡器生成的余弦波
    reg signed [15:0] i_mixer=0;    // I路混频器输出
    reg signed [15:0] q_mixer=0;    // Q路混频器输出
    reg signed [31:0] phase_error=0;// 相位误差
    reg signed [31:0] phase_adjust=0; // 相位调整量
    wire signed [39:0] fir_tdata_i_i_mixer;
    wire signed [39:0] fir_tdata_i_q_mixer;
    wire signed [15:0] fir_tdata_i_i_mixer_short;
    wire signed [15:0] fir_tdata_i_q_mixer_short;
    reg                		mixed_valid_r = 0;    // 相乘信号有效标志
//    wire             		fir_tready_i;         // FIR 滤波器输入准备好信号
//    wire              		fir_tvalid_i;         // FIR 滤波器输出有效信号
    // 正弦波和余弦波查找表（LUT）
    reg signed [7:0] sine_lut [0:255];
    reg signed [7:0] cosine_lut [0:255];
    integer i; // 用于查找表初始化的变量

    assign fir_tdata_i_i_mixer_short=fir_tdata_i_i_mixer[39:24];
    assign fir_tdata_i_q_mixer_short=fir_tdata_i_q_mixer[39:24];
    
    // 初始化正弦波和余弦波查找表
    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            sine_lut[i] = 127 * $sin(2 * 3.1415926 * i / 256); // 正弦波
            cosine_lut[i] = 127 * $cos(2 * 3.1415926 * i / 256); // 余弦波
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phase_accumulator <= 32'd0;
            sine_wave <= 8'd0;
            cosine_wave <= 8'd0;
            i_mixer <= 16'd0;
            q_mixer <= 16'd0;
        end else begin
            phase_accumulator <= phase_accumulator + PHASE_INC + phase_adjust;
            if (phase_accumulator >= 32'd4294967295) begin
                phase_accumulator <= 32'd0;  // 防止溢出
            end
            sine_wave <= sine_lut[phase_accumulator[31:24]];
            cosine_wave <= cosine_lut[phase_accumulator[31:24]];
            i_mixer <= psk_in * sine_wave;   // I路：输入信号与正弦波混频
            q_mixer <= psk_in * cosine_wave; // Q路：输入信号与余弦波混频
        end
    end

//    // 从查找表中读取正弦波和余弦波
//    always @(posedge clk) begin
//        sine_wave <= sine_lut[phase_accumulator[31:24]];
//        cosine_wave <= cosine_lut[phase_accumulator[31:24]];
//    end

//    // I路和Q路混频器
//    always @(posedge clk) begin
//        i_mixer <= psk_in * sine_wave;   // I路：输入信号与正弦波混频
//        q_mixer <= psk_in * cosine_wave; // Q路：输入信号与余弦波混频
//    end
    always @(posedge clk) begin
        if (rst_n == 0) begin
            mixed_valid_r <= 0;
        end else 
            mixed_valid_r <= ~mixed_valid_r;
	end
    //低通滤波器滤波
    fir_lpf_psk fir_lpf_psk_psk2
    (
        .aclk                (clk),                // 时钟信号
        .s_axis_data_tvalid  (mixed_valid_r),      // 输入数据有效信号
        .s_axis_data_tready  (),       // FIR 滤波器输入准备好信号
        .s_axis_data_tdata   (i_mixer), // 输入数据（取高 8 位）
        .m_axis_data_tvalid  (),       // FIR 滤波器输出有效信号
        .m_axis_data_tdata   (fir_tdata_i_i_mixer)         // FIR 滤波器输出数据
    );
    //低通滤波器滤波
    fir_lpf_psk fir_lpf_psk_psk3
    (
        .aclk                (clk),                // 时钟信号
        .s_axis_data_tvalid  (mixed_valid_r),      // 输入数据有效信号
        .s_axis_data_tready  (),       // FIR 滤波器输入准备好信号
        .s_axis_data_tdata   (q_mixer), // 输入数据（取高 8 位）
        .m_axis_data_tvalid  (),       // FIR 滤波器输出有效信号
        .m_axis_data_tdata   (fir_tdata_i_q_mixer)         // FIR 滤波器输出数据
    );
    //相位误差检测 相位调整
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phase_error <= 32'd0;
            phase_adjust <= 32'd0;
        end else begin
            phase_error <= fir_tdata_i_i_mixer_short * fir_tdata_i_q_mixer_short; // 相位误差 = I路 * Q路
            phase_adjust <= phase_error >>> LOOP_GAIN; // 根据环路增益调整相位
        end
    end

    // 输出恢复的载波
    always @(posedge clk) begin
        carrier_out <= sine_wave; // 输出正弦波作为恢复的载波
    end
endmodule
