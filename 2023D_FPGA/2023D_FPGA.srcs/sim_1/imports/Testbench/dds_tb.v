`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/11 20:12:31
// Design Name: 
// Module Name: dds_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
//      此模块用于单独测试dds生成的调制波
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module dds_tb();

    reg aclk_0;
    wire [7:0]am_wave_signed_8bit;
    wire [15:0]sin_1k;
    wire [15:0]sin_2m;

    dds_wrapper dds_wrapper_inst(
        .aclk_0(aclk_0),
        .am_wave_signed_8bit(am_wave_signed_8bit),
        .sin_1k(sin_1k),
        .sin_2m(sin_2m)
    );

    initial begin
        aclk_0 = 0;
        # 40000;
        $stop;

    end

    always #5 aclk_0 = ~aclk_0;

endmodule
