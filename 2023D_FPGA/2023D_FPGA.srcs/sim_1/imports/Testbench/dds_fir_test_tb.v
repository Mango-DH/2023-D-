`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/12 16:17:21
// Design Name: 
// Module Name: dds_fir_test_tb
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


module dds_fir_test_tb();

    reg clk;
    reg reset_n;
    wire [7:0] am_wave_signed_8bit; 	    //滤波器解调信号输出
    wire [7:0] am_wave_abs_8bit;    
    wire [31:0]am_demod_32bit;


    dds_fir_test dds_fir_test_inst(
        .clk(clk),
        .reset_n(reset_n),
        .am_wave_signed_8bit(am_wave_signed_8bit), 	 //滤波器解调信号输出
        .am_wave_abs_8bit(am_wave_abs_8bit),         //记录整流后的数据的寄存器
        .am_demod_32bit(am_demod_32bit)
    );

    initial begin
        clk = 0;
        reset_n = 0;
        # 10;
        reset_n = 1;
        # 40000;
        $stop;

    end

    always #5 clk = ~clk;

endmodule
