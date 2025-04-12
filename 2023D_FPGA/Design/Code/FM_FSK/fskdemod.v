`timescale 1ns / 1ps

module	fskdemod
(
	input							rst_n,
	input							clk,
	input				[7:0]	    data_in,
	output	unsigned	[39:0]  	fir_data_out,
	output	unsigned	[8:0]  	data_out_9,
	output	unsigned	[9:0]  	data_out_10
);
		

	wire signed 		[15:0] 		i_mixer;
	wire signed 		[15:0] 		q_mixer;
	wire signed 		[15:0] 		dout;
	wire signed     	[31:0]  	unwrapped_phase_out;   //解缠后的相位
	wire signed  	  	[31:0]  	demod_out;             //微分后的最终解调信号
	wire signed   	  	[8:0]   	FM_demod_out_signed_9;
	wire signed   	  	[9:0]   	FM_demod_out_signed_10;


	IQ_generate IQ_generate_inst(	
		.clk(clk),          			// 时钟信号
		.rst_n(rst_n),       					// 复位信号（低电平有效）
		.FM_in(data_in), 						// 输入的FSK信号（8位有符号）
		.fir_tdata_i_i_mixer_short(i_mixer), 	// 输出的恢复载波（8位有符号）
		.fir_tdata_i_q_mixer_short(q_mixer)
	);	

	cordic_atan4 cordic_atan4_inst (       
      .aclk(clk),                               // input wire aclk
      .s_axis_cartesian_tvalid(1),  					// input wire s_axis_cartesian_tvalid
      .s_axis_cartesian_tdata({i_mixer,q_mixer}),    	// input wire [47 : 0] s_axis_cartesian_tdata
      .m_axis_dout_tvalid(),            				// output wire m_axis_dout_tvalid
      .m_axis_dout_tdata(dout)              			// output wire [23 : 0] m_axis_dout_tdata
    );
	
	phase_unwrap phase_unwrap_inst(
        .clk(clk),
        .reset_n(rst_n),
        .phase_in(dout),  // Q3.13格式
        .unwrapped_phase(unwrapped_phase_out)  // Q16.16格式
	);
	
	phase_differentiator phase_differentiator_inst (
        .clk(clk),
        .reset_n(rst_n),
        .unwrapped_phase(unwrapped_phase_out),  // Q16.16
        .frequency_out(demod_out) // Q16.16
    );

	wire [15:0] low_16bit;
	assign low_16bit = demod_out[15:0];
	wire [39:0] m_axis_data_tdata;
	assign fir_data_out = m_axis_data_tdata;

	// //低通滤波器滤波
    fir_lpf_fsk fir_lpf_fsk_inst(                  		// 输出前做一次滤波
        .aclk                (clk),                		// 时钟信号
        .s_axis_data_tvalid  (1),    			// 输入数据有效信号
        .s_axis_data_tready  (),       					// FIR 滤波器输入准备好信号
        .s_axis_data_tdata   (low_16bit), 				// 输入数据
        .m_axis_data_tvalid  (),       					// FIR 滤波器输出有效信号
        .m_axis_data_tdata   (m_axis_data_tdata)         // FIR 滤波器输出数据
    );
	
	assign FM_demod_out_signed_9 = m_axis_data_tdata[32:24];
	assign FM_demod_out_signed_10 = m_axis_data_tdata[33:24];
	signed_unsigned_converter #(9) signed_unsigned_converter_fsk2(
		.data_in(FM_demod_out_signed_9),  // 输入数据（8位）
		.is_signed(1),      			// 标志位：1表示输入是有符号数，0表示输入是无符号数
		.data_out(data_out_9)           	// 输出数据（8位）
	);
	signed_unsigned_converter #(10) signed_unsigned_converter_fsk3(
		.data_in(FM_demod_out_signed_10),  // 输入数据（8位）
		.is_signed(1),      			// 标志位：1表示输入是有符号数，0表示输入是无符号数
		.data_out(data_out_10)           	// 输出数据（8位）
	);
endmodule


