`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/04/02 17:26:15
// Design Name: 
// Module Name: phase_differentiator
// Project Name: 微分模块
// Target Devices: 
// Tool Versions: 
// Description: 对输入信号进行微分
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module phase_differentiator (
    input wire clk,
    input wire reset_n,
    input wire signed [31:0] unwrapped_phase,  // Q16.16格式输入
    output reg signed [31:0] frequency_out     // Q16.16格式输出
);

    reg signed [31:0] prev_phase;
    localparam KF = 32'sd50000; // 频偏常数kf的倒数，根据实际系统调整
    reg [15:0] count = 0;
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            prev_phase <= 0;
            frequency_out <= 0;
            count <= 0;
        end else if(unwrapped_phase!=prev_phase)begin
            if(count==300)begin
                // 基本微分计算
                frequency_out <= (unwrapped_phase - prev_phase);            
                prev_phase <= unwrapped_phase;
                count <= 0;
            end else count <= count+1;
        end
    end
endmodule
