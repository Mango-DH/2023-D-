module ad_wave_rec(
	input clk ,   			//时钟
	input rst_n ,			//复位信号，低电平有效
	input [7:0] ad_data , 	//AD 输入数据
	
	//模拟输入电压超出量程标志(本次试验未用到)
	input ad_otr , 			//0:在量程范围 1:超出量程
	output reg ad_clk 		//AD(AD9280)驱动时钟,最大支持 32Mhz 时钟
);
	
	//时钟分频(10 分频,时钟频率为 5Mhz),产生 AD 时钟
	reg [2:0] count; // 计数器，用于计数 5 个周期
	
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			count <= 3'b0;  // 复位时计数器清零
			ad_clk <= 1'b0; // 复位时输出时钟为低电平
		end else begin
			if (count == 3'd1) begin // 计数到 9 时
				ad_clk <= ~ad_clk;   // 翻转输出时钟
				count <= 3'b0;       // 计数器清零
			end 
 			else begin
				count <= count + 3'b1; // 计数器加 1
			end 
		end
	end

	
	
	
endmodule