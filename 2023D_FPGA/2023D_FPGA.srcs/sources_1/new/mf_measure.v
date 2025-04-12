`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/04/10 02:54:46
// Design Name: 
// Module Name: mf_measure
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


module mf_measure#(
	parameter N=16
)(
    input        clk,
    input        rst_n,
	input        mf_measure_enable,
	input       [15:0] fm_freq,
    input  		[N-1:0] vpp,      // 峰峰值，8位无符号
    output reg  [12:0] f_offset_max,
    output reg 	[7:0] mf    // 调制度，范围30~100（百分比）
);
    reg [31:0] vpp_mult;   // 放大vpp*10000
    reg [31:0] sum;
    reg [31:0] mf_temp;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vpp_mult <= 0;
            sum      <= 0;
            mf_temp  <= 0;
            mf       <= 0;
        end else if (mf_measure_enable)begin
            // vpp * 1000 = vpp*(1024 - 16 - 8)
			vpp_mult <= (vpp << 10) - (vpp << 4) - (vpp << 3);
            f_offset_max <= vpp_mult / 10;
            // ma = sum / 8714, 8714 ≈ 2^13 + 2^9 + 2^7 + 2^5 + 2
            // 为避免除法，用乘法近似除法：(sum * 15) >> 17 ≈ sum / 8714
            mf_temp <= vpp_mult / fm_freq;

            // 限制范围30~100
            if (mf_temp < 10)
                mf <= 10;
            else if (mf_temp > 50)
                mf <= 50;
            else
                mf <= mf_temp[7:0];
        end
    end
endmodule
