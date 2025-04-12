`timescale 1ns / 1ps

module askdemod(
    input clk,  		//50MHz
    input rst_n,
    input signed[7:0] data_in,    			
    output unsigned[7:0] data_out	 	
   );
   
	//截取滤波器输出数据的有效部分
	assign data_out = m_axis_data_tdata[25:18];

    //分频部分
	reg data_tvalid;
	reg [3:0] cnt;
	always @(posedge clk or negedge rst_n) begin // div 5
		if(!rst_n) begin
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

	
	//半波整流
	reg signed [7:0] abs_din;
	always @(posedge data_tvalid or negedge rst_n) begin
		if(!rst_n)
			abs_din <= 8'd0;
		else if(data_in[7])   //符号位为1,负数
			abs_din <= 0;
		else
			abs_din <= data_in;
	end

	
	//滤波器模块
	wire s_axis_data_tvalid;
	wire [7:0] s_axis_data_tdata;
	wire [31:0] m_axis_data_tdata;
	
	assign s_axis_data_tvalid = data_tvalid;	
	assign s_axis_data_tdata = abs_din;           //整流数据

	fir_lpf_ask fir_lpf_ask_inst (
	  .aclk(clk),                              // input wire aclk
	  .s_axis_data_tvalid(s_axis_data_tvalid),  // input wire s_axis_data_tvalid
	  .s_axis_data_tready(),  // output wire s_axis_data_tready
	  .s_axis_data_tdata(s_axis_data_tdata),    // input wire [7 : 0] s_axis_data_tdata
	  .m_axis_data_tvalid(),  // output wire m_axis_data_tvalid
	  .m_axis_data_tdata(m_axis_data_tdata)    // output wire [31 : 0] m_axis_data_tdata
	);

endmodule
