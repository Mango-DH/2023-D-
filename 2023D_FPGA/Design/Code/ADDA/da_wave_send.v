`timescale 1ns / 1ps
module da_wave_send (
	input clk , //时钟
	input rst_n , //复位信号，低电平有效	
	input [7:0] demod_data , 		//解调数据	
	output da_clk , //DA(AD9708)驱动时钟,最大支持 125Mhz 时钟
	output [7:0] da_data //输出给 DA 的数据 
);

	//数据rd_data 是在 clk 的上升沿更新的，所以 DA 芯片在 clk 的下降沿锁存数据是稳定的时刻
	//而 DA 实际上在 da_clk 的上升沿锁存数据,所以时钟取反,这样 clk 的下降沿相当于 da_clk 的上升
	assign da_clk = ~clk; 
	assign da_data = demod_data; //将读到的 ROM 数据赋值给 DA 数据端口
	
/*	//reg define
	reg [7:0] freq_cnt ; //频率调节计数器
	
 	//频率调节计数器
	always @(posedge clk or negedge rst_n) begin
		if(rst_n == 1'b0)
			freq_cnt <= 8'd0;
		else if(freq_cnt == FREQ_ADJ) 
			freq_cnt <= 8'd0;
		else 
			freq_cnt <= freq_cnt + 8'd1;
	end
	
	//读 ROM 地址
	always @(posedge clk or negedge rst_n) begin
		if(rst_n == 1'b0)
			rd_addr <= 8'd0;
		else begin
			if(freq_cnt == FREQ_ADJ) begin
				rd_addr <= rd_addr + 8'd1;
			end 
		end 
	end */
	
 endmodule