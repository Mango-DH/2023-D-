`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/12 22:38:02
// Design Name: 
// Module Name: signed_unsigned_converter
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


module signed_unsigned_converter #(parameter WIDTH = 16) (
    input wire [WIDTH-1:0] data_in,  // 输入数据（16位）
    input wire is_signed,            // 标志位：1表示输入是有符号数，0表示输入是无符号数
    output reg [WIDTH-1:0] data_out  // 输出数据（16位）
);

    // 内部信号
    reg signed [WIDTH-1:0] signed_data;   // 有符号数表示
    reg [WIDTH-1:0] unsigned_data;        // 无符号数表示

    always @(*) begin
        if (is_signed) begin
            // 如果输入是有符号数，转换为无符号数
            signed_data = data_in;  // 将输入数据视为有符号数
            unsigned_data = signed_data + (1 << (WIDTH-1));  // 转换为无符号数
            data_out = unsigned_data;
        end else begin
            // 如果输入是无符号数，转换为有符号数
            unsigned_data = data_in;  // 将输入数据视为无符号数
            signed_data = unsigned_data - (1 << (WIDTH-1));  // 转换为有符号数
            data_out = signed_data;
        end
    end

endmodule
