//输入三路解调信号做判断，然后把数据给da_data

module data_sele(
    input sys_clk,
    input sys_rst_n,
    input [7:0]askdemod_vpp,
    input [9:0]fskdemod_vpp,
    input [7:0]pskdemod_vpp,

    input [7:0]askdemod_dc_offset,

    input [7:0]ask_papr,
    input [9:0]fsk_papr,
    input [7:0]psk_papr,

    input ask_is_sine_wave,
	input fsk_is_sine_wave,
	
	//输入解调信号
	input [7:0] askdemod_data,
	input [9:0] fskdemod_data,
	input [7:0] pskdemod_data,
	input [39:0] fir_data_out,
    //输入要选择的频率，完全看通道
	input [15:0] ask_freq_out,
	input [15:0] fsk_freq_out,
	input [15:0] psk_freq_out,

	input [7:0] ma,
	
    output reg[7:0] demod_data,
    output reg[7:0] uart_mod_type,
    output reg[15:0]uart_demod_fre
);

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if(!sys_rst_n)begin
            demod_data <= 0;
            uart_mod_type <= 0;
            uart_demod_fre <= 0;
        end

        else begin
			if(askdemod_dc_offset < 60) begin              //如果峰峰值波动值大于20
                if(ask_papr > 5 )begin
					if(ma >= 30 && ma <= 35)
						demod_data <= askdemod_data << 1;        //输出通道一的解调信号
					else demod_data <= askdemod_data;
					uart_demod_fre <= ask_freq_out;     //输出解调信号的频率
                    uart_mod_type <= 1;             //AM信号
                end    
                else begin 
					demod_data <= askdemod_data;
					uart_demod_fre <= ask_freq_out;     //输出解调信号的频率
                    uart_mod_type <= 2;                     //ASK信号
                end
            end

            else if(fsk_papr >= 20)begin
				demod_data <= pskdemod_data;            //调信号
                uart_mod_type <= 5;                     
                uart_demod_fre <= psk_freq_out;          
            end

            else if((fsk_papr >= 5) && (fsk_papr < 20))begin
                uart_demod_fre <= fsk_freq_out;     //输出解调信号的频  
                uart_mod_type <= 3;                 //FM信号
				if(fsk_freq_out<=1500)begin
					demod_data <= {~fskdemod_data[7],fskdemod_data[6:0]<< 2};
				end
				else if(fsk_freq_out >1500&&fsk_freq_out<=2500)begin
					demod_data <= {~fskdemod_data[7],fskdemod_data[6:0]<< 1};
				end 
				else demod_data <= {~fskdemod_data[7],fskdemod_data[6:0]};
            end

            else if((fsk_papr < 5) && (fsk_papr > 0))begin
			    demod_data <= fskdemod_data[9:2];        //输出通道一的解调信号
                uart_demod_fre <= fsk_freq_out;     //输出解调信号的频  
                uart_mod_type <= 4;                 //FSK信号
            end
            
            else if (fsk_papr == 0)begin 
                uart_mod_type <= 6;                     //CW信号
            end
        end
    end
endmodule