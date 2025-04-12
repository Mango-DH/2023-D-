`timescale 1ns / 1ps

module ad_da_test(
	input clk , 		     //系统时钟
	input rst_n ,	 	   //系统复位，低电平有效	
	output da_clk ,		 	//DA(AD9708)驱动时钟,最大支持 125Mhz 时钟
	output ad_clk,          //AD(AD9280)驱动时钟,最大支持 32Mhz 时钟
	output [7:0] da_data , 	//输出给 DA 的数据
	
	input [7:0] ad_data ,   //AD 输入数据
	input [7:0] demod_data,   //输入数据
	input ad_otr 			//0:在量程范围 1:超出量程
);
	
/* 	//wire define 
	wire [7:0] rd_addr; //ROM 读地址
	wire [7:0] rd_data; //ROM 读出的数据

	//ROM 存储波形
	rom_256x8b u_rom_256x8b (
		.clka(clk),    		// input wire clka
		.addra(rd_addr), 	 	// input wire [7 : 0] addra
		.douta(rd_data)  		// output wire [7 : 0] douta
	); 
*/
	
	//DA 产生波形
	da_wave_send da_wave_send_inst(
		.clk (clk),
		.rst_n (rst_n),
		.demod_data (demod_data),
		.da_clk (da_clk), 
		.da_data (da_data)
	);
		
	//AD 数据接收
	ad_wave_rec ad_wave_rec_inst(
		.clk (clk),
		.rst_n (rst_n),
		.ad_data (ad_data),
		.ad_otr (ad_otr),
		.ad_clk (ad_clk)
	); 
	
 endmodule
