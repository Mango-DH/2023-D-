`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/11 22:27:41
// Design Name: 
// Module Name: top_dds_fir
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


module dds_fir_test(
    input clk,
    input reset_n,
    output [7:0] am_wave_signed_8bit, 	        //滤波器解调信号输出
    output wire[7:0]am_wave_abs_8bit,            //记录整流后的数据的寄存器
	output wire[31:0]am_demod_32bit
);

    dds_wrapper dds_wrapper_inst(
        .aclk_0(clk),
        .am_wave_signed_8bit(am_wave_signed_8bit),
        .sin_1k(),
        .sin_2m()
    );

    //分频部分
	reg data_tvalid;
	reg [3:0] cnt;
	always @(posedge clk or negedge reset_n) begin // div 5
		if(!reset_n) begin
			cnt <= 4'd0;
			data_tvalid <= 1'b0;
		end
		else begin      
			if(cnt == 4) begin
				cnt <= 4'd0;
				data_tvalid <= 1'b1;
			end
			else begin
				cnt <= cnt +4'd1;
				data_tvalid <= 1'b0;
			end
		end
	end
	
	//整流模块
	reg signed [7:0] abs_din;    //记录整流后的数据的寄存器
	always @(posedge data_tvalid or negedge reset_n) begin
		if(!reset_n)
			abs_din <= 8'd0;
		else if(am_wave_signed_8bit[7])   //负数
			// abs_din <= ~am_wave_signed_8bit + 8'd1;
			abs_din <= 0;
		else
			abs_din <= am_wave_signed_8bit;
	end
  
    assign am_wave_abs_8bit = abs_din;


	//滤波器模块
	wire s_axis_data_tvalid;
	wire [7:0] s_axis_data_tdata;
	wire [31:0] m_axis_data_tdata;

	assign s_axis_data_tvalid = data_tvalid;	
	assign s_axis_data_tdata = abs_din;           //整流数据
	assign am_demod_32bit = m_axis_data_tdata;

	fir_lpf_ask fir_lpf_ask_inst (
	  .aclk(clk),                              // input wire aclk
	  .s_axis_data_tvalid(s_axis_data_tvalid),  // input wire s_axis_data_tvalid
	  .s_axis_data_tready(),  // output wire s_axis_data_tready
	  .s_axis_data_tdata(s_axis_data_tdata),    // input wire [7 : 0] s_axis_data_tdata
	  .m_axis_data_tvalid(),  // output wire m_axis_data_tvalid
	  .m_axis_data_tdata(m_axis_data_tdata)    // output wire [31 : 0] m_axis_data_tdata
	);


endmodule
