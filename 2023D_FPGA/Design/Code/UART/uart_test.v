module uart_test(
	input                          	clk,       	   //system clock 50Mhz on board
	input                          	rst_n,         //reset ,low active

	input 							[7:0]uart_mod_type,
	input							[15:0]uart_demod_fre,
    input                           [7:0]uart_mod_depth,
    input                           [7:0]uart_delta_freq,
	input                          	uart_rx,       //fpga receive data
	output                         	uart_tx        //fpga send data
);
	
	parameter                       CLK_FRE = 50;//Mhz
	localparam                      IDLE =  0;
	localparam                      SEND =  1;   //send data
	localparam                      WAIT =  2;   //wait 1 second and send uart received data
	localparam                      DATA_LEH = 12;  // 数据长度
	reg[7:0]                        tx_data;
	reg[7:0]                        tx_str;
	reg                             tx_data_valid;
	wire                            tx_data_ready;
	reg[7:0]                        tx_cnt;
	wire[7:0]                       rx_data;
	wire                            rx_data_valid;
	wire                            rx_data_ready;
	reg[31:0]                       wait_cnt;
	reg[3:0]                        state;
	
	assign rx_data_ready = 1'b1;//always can receive data,
								//if HELLO ALINX\r\n is being sent, the received data is discarded
	/*************************************************************************
	1 second sends a packet HELLO ALINX\r\n , FPGA has been receiving state
	****************************************************************************/
	always@(posedge clk or negedge rst_n)begin
		if(rst_n == 1'b0)
		begin
			wait_cnt <= 32'd0;
			tx_data <= 8'd0;
			state <= IDLE;
			tx_cnt <= 8'd0;
			tx_data_valid <= 1'b0;
		end
		else
		case(state)
			IDLE:
				state <= SEND;
			SEND:
			begin
				wait_cnt <= 32'd0;
				tx_data <= tx_str;
	
				if(tx_data_valid == 1'b1 && tx_data_ready == 1'b1 && tx_cnt < DATA_LEH)//Send 12 bytes data
				begin
					tx_cnt <= tx_cnt + 8'd1; //Send data counter
				end
				else if(tx_data_valid && tx_data_ready)//last byte sent is complete
				begin
					tx_cnt <= 8'd0;
					tx_data_valid <= 1'b0;
					state <= WAIT;
				end
				else if(~tx_data_valid)
				begin
					tx_data_valid <= 1'b1;
				end
			end
			WAIT:
			begin
				wait_cnt <= wait_cnt + 32'd1;
	
				if(rx_data_valid == 1'b1)
				begin
					tx_data_valid <= 1'b1;
					tx_data <= rx_data;   // send uart received data
				end
				else if(tx_data_valid && tx_data_ready)
				begin
					tx_data_valid <= 1'b0;
				end
				else if(wait_cnt >= CLK_FRE * 1000000) // wait for 1 second
					state <= SEND;
			end
			default:
				state <= IDLE;
		endcase
	end
	
	/*************************************************************************
	combinational logic  Send "HELLO ALINX\r\n"
	****************************************************************************/
	

	// 将二进制数转换为ASCII字符
	function [7:0] to_ascii;
	    input [3:0] bin;
	    begin
	        if (bin < 10)
	            to_ascii = bin + "0"; // 0~9 转 ASCII
	        else
	            to_ascii = bin - 10 + "A"; // A~F 转 ASCII
	    end
	endfunction

//	always@(*)
//	begin
//    case(tx_cnt)
//        8'd0 : tx_str <= 8'hAD;      							//包头				
//        8'd1 : tx_str <= DATA_LEH;								//数据长度
//        8'd2 : tx_str <= to_ascii(uart_mod_type[3:0]); 			//发送调制类型
//        8'd3 : tx_str <= to_ascii(uart_demod_fre[15:12]);		//发送频率
//        8'd4 : tx_str <= to_ascii(uart_demod_fre[11:8]);
//        8'd5 : tx_str <= to_ascii(uart_demod_fre[7:4]);
//		  8'd6 : tx_str <= to_ascii(uart_demod_fre[3:0]);
//        8'd7 : tx_str <= "\n";
//		default : tx_str <= 8'd0; // 默认清零
//    endcase
//	end
    always@(*)
	begin
    case(tx_cnt)
        8'd0 : tx_str <= 8'hAD;      							//包头				
        8'd1 : tx_str <= DATA_LEH;								//数据长度
        8'd2 : tx_str <= to_ascii(uart_mod_type[3:0]); 			//发送调制类型
        8'd3 : tx_str <= to_ascii(uart_demod_fre[15:12]);		//发送频率
        8'd4 : tx_str <= to_ascii(uart_demod_fre[11:8]);
        8'd5 : tx_str <= to_ascii(uart_demod_fre[7:4]);
		8'd6 : tx_str <= to_ascii(uart_demod_fre[3:0]);
        8'd7 : tx_str <= to_ascii(uart_mod_depth[7:4]);   // 调制度高4位
        8'd8 : tx_str <= to_ascii(uart_mod_depth[3:0]);   // 调制度低4位
        8'd9 : tx_str <= to_ascii(uart_delta_freq[7:4]);   // 调制度高4位
        8'd10 : tx_str <= to_ascii(uart_delta_freq[3:0]);   // 调制度低4位
        8'd11 : tx_str <= "\n";
		default : tx_str <= 8'd0; // 默认清零
    endcase
	end
	
	// always@(*)
	// begin
	// 	case(tx_cnt)
	// 		8'd0 :  tx_str <= "M";
	// 		8'd1 :  tx_str <= "O";
	// 		8'd2 :  tx_str <= "D";
	// 		8'd3 :  tx_str <= ":";
	// 		8'd4 :  tx_str <= uart_mod_type;
	// 		8'd5 :  tx_str <= " ";
	// 		8'd6 :  tx_str <= "F";
	// 		8'd7 :  tx_str <= "R";
	// 		8'd8 :  tx_str <= "E";
	// 		8'd9 :  tx_str <= ":";
	// 		8'd10:  tx_str <= uart_demod_fre[15:8];      //发送高位
	// 		8'd11:  tx_str <= uart_demod_fre[7:0];      //发送低位
	// 		8'd12:  tx_str <= "\r";
	// 		8'd13:  tx_str <= "\n";
	// 		default:tx_str <= 8'd0;
	// 	endcase
	// end
	
	/***************************************************************************
	calling uart_tx module and uart_rx module
	****************************************************************************/
	uart_rx#
	(
		.CLK_FRE(CLK_FRE),
		.BAUD_RATE(115200)
	) uart_rx_inst
	(
		.clk                        (clk                  ),
		.rst_n                      (rst_n                    ),
		.rx_data                    (rx_data                  ),
		.rx_data_valid              (rx_data_valid            ),
		.rx_data_ready              (rx_data_ready            ),
		.rx_pin                     (uart_rx                  )
	);
	
	uart_tx#
	(
		.CLK_FRE(CLK_FRE),
		.BAUD_RATE(115200)
	) uart_tx_inst
	(
		.clk                        (clk                  ),
		.rst_n                      (rst_n                    ),
		.tx_data                    (tx_data                  ),
		.tx_data_valid              (tx_data_valid            ),
		.tx_data_ready              (tx_data_ready            ),
		.tx_pin                     (uart_tx                  )
	);
endmodule

