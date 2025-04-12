`timescale 1ns / 1ns

module measure_tb;
    reg clk;                				// 50 MHz ʱ��
    reg rst_n;                				// ��λ�ź�
    reg [7:0] signal_in_unsigned;   		// 8bit �޷��������ź�

    wire is_sine_wave;      		// 1=���Ҳ���0=����
	wire [15:0] freq_out;
	wire [6:0] ma; 
	
    wire signed[7:0] signal_dc_removed;   	// ȥ��ֱ��������õ����ź�
 	wire unsigned[7:0] dc_offset;   
	wire unsigned[7:0] vpp;
 	wire signal_rectified;
	
	wire [31:0]papr;				// ������ʱ�



	//��Ƶģ��
	wire sample_en;
	clk_divider #(.FRE_DIV (2499))clk_divider_inst(
		.clk(clk),                	// ����ʱ�ӣ�50 MHz��
		.rst_n(rst_n),              // �첽��λ�źţ��͵�ƽ��Ч��
		.sample_en(sample_en)      	// ����ʹ���ź�
	);
	
	wave_cal #(
		.N(8),               			// ����λ��
		.SAMPLE_POINTS(128), 			// ��������
		.LOG_2_SAMPLE_POINTS(7)
		.JUDGE_THRESHOLD(700)   		// �ж���ֵ
	)wave_cal_inst(
		.clk(clk),
	    .sample_clk(sample_en),            
	    .rst_n(rst_n),                		
	    .data_in_unsigned(signal_in_unsigned),	
	    
	    .signal_dc_removed(signal_dc_removed),	
	    .vpp(vpp),				
		.papr(papr),   					
	    .is_sine_wave(is_sine_wave)   					
	);
	
 /*
	//ȥ��ֱ����ģ��
	dc_remover #(
		.N(8),               					// ����λ��
		.SAMPLE_POINTS(32),						// ��������
		.LOG_2_SAMPLE_POINTS(5)						
	)dc_remover_inst(
		.clk(clk),
		.sample_clk(sample_en),                	// ʱ���ź�
		.rst_n(rst_n),                			// ��λ�ź�
		.data_in_unsigned(signal_in_unsigned),	// �޷�����������	
		
		.vpp(vpp),
		.dc_offset(dc_offset),           		// ֱ������	
		.signal_dc_removed(signal_dc_removed) 	// ȥ��ֱ����������з������
	);
	
	//��������ģ��
 	wave_rectifier #(.N(8)) wave_rectifier_inst(
		.clk(clk),                  	
		.rst_n(rst_n),                 	
		.signal_dc_removed(signal_dc_removed),
		.signal_rectified(signal_rectified)  
	);	  

   	//�����ж�ģ��
 	wave_identifier #(
		.JUDGE_THRESHOLD(700),
		.SAMPLE_POINTS (32),
		.LOG_2_SAMPLE_POINTS(5)	
	)wave_identifier_inst(
		.sample_clk(sample_en),                		// 50 MHz ʱ��
		.rst_n(rst_n),                				// ͬ����λ
		.signal_dc_removed(signal_dc_removed),		// ȥ��ֱ�����ź�
		.vpp(vpp),		  							// Vpp��ֱ���ź�
		.dc_offset(dc_offset), 
 		.is_sine_wave(is_sine_wave)   				// 1=���Ҳ���0=����
	); 
	
	//Ƶ�ʲ���
	frequency_counter #(
		.MEASURE_CLK_CNT(200),
		.MEASURE_CLK(20000)     //����Ƶ��
	)frequency_counter_inst(	//5ms�ڼ����ĸ�����������ʱ�ӵ�Ƶ�� 
		.clk(sample_en),                		// ��Ƶʱ��
		.rst_n(rst_n),              			// ��λ�ź�
		.signal_in(signal_rectified),          	// ������������ź�
		.freq_out(freq_out)				 		// ���Ƶ��ֵ
	);
		
	//���ƶȲ���
	ma_measure ma_measure_inst(
		.clk(sample_en),       //���ƶȲ���ʱ��   
		.rst_n(rst_n),   
		.ma_measure_enable(is_sine_wave & ma_measure_enable),
		.vpp(vpp),
		.ma(ma) 
	);   */
	   
/* 	measure measure_inst(
		.clk(clk),
		.rst_n(rst_n),
		.signal_in_unsigned(signal_in_unsigned),
		.ma_measure_enable(1),
		
		.is_sine_wave(is_sine_wave),      		// 1=���Ҳ���0=����
		.freq_out(freq_out),
		.papr(papr),
		.ma(ma) 
		
	);  */

	
    initial begin
        clk = 0;
        forever #10 clk = ~clk; // 50 MHz ʱ�ӣ�����Ϊ 20ns
    end

     
 // ���Թ���
    initial begin
        rst_n = 0;
        signal_in_unsigned = 8'b0;  	
		#10; // ��λ 10u
        rst_n = 1;   
		#10; // �ȴ� 100ns ��ʼ�����ź�

       
		repeat (2048*10) begin
            signal_in_unsigned = 40 + 25 * $sin(2 * 3.1415926 * $time / 200000); // 200us ����
            #100; // ÿ���������� 20ns
        end 
		
		repeat (2048*10) begin
            signal_in_unsigned = 41 + 13 * $sin(2 * 3.1415926 * $time / 200000); // 200us ����
            #100; // ÿ���������� 20ns
        end  
		
		
		
		repeat (2048*30) begin
            signal_in_unsigned = 40 + 40 * $sin(2 * 3.1415926 * $time / 333333); // 1000us ����
            #100; // ÿ���������� 20ns
        end 
		
		repeat (2048*30) begin
            signal_in_unsigned = 40 + 25 * $sin(2 * 3.1415926 * $time / 333333); // 1000us ����
            #100; // ÿ���������� 20ns
        end 
		
		repeat (2048*30) begin
            signal_in_unsigned = 41 + 13 * $sin(2 * 3.1415926 * $time / 333333); // 1000us ����
            #100; // ÿ���������� 20ns
        end  
		
		repeat (2048*50) begin
            signal_in_unsigned = 40 + 40 * $sin(2 * 3.1415926 * $time / 1000000); // 1000us ����
            #100; // ÿ���������� 20ns
        end 
		
		repeat (2048*50) begin
            signal_in_unsigned = 40 + 25 * $sin(2 * 3.1415926 * $time / 1000000); // 1000us ����
            #100; // ÿ���������� 20ns
        end 
		
		repeat (2048*50) begin
            signal_in_unsigned = 41 + 13 * $sin(2 * 3.1415926 * $time / 1000000); // 1000us ����
            #100; // ÿ���������� 20ns
        end  
		
		repeat (2048*50) begin
            signal_in_unsigned = 127 + 127* $sin(2 * 3.1415926 * $time / 1000000); // 1000us ����
            #100; // ÿ���������� 20ns
        end  
		
		repeat (2048*50) begin
            signal_in_unsigned = 2 + 2* $sin(2 * 3.1415926 * $time / 1000000); // 1000us ����
            #100; // ÿ���������� 20ns
        end  

        repeat (100) begin         
            signal_in_unsigned = 128; // �ߵ�ƽ
            #500000;            // ���ָߵ�ƽ 100us
            signal_in_unsigned = 0;  // �͵�ƽ
            #500000;            // ���ֵ͵�ƽ 100us
        end 

		repeat (2048*10) begin
            signal_in_unsigned = 40 + 40 * $sin(2 * 3.1415926 * $time / 200000); // 200us ����
            #100; // ÿ���������� 20ns
        end 
		

        repeat (100) begin         
            signal_in_unsigned = 79; // �ߵ�ƽ
            #500000;            // ���ָߵ�ƽ 100us
            signal_in_unsigned = 0;  // �͵�ƽ
            #500000;            // ���ֵ͵�ƽ 100us
        end  
		 
		$stop; 
	end 
		 
/*        // �ź����ɣ�DC �� Noise �� DC �� Noise
	initial begin
		rst_n = 0;
		signal_in_unsigned = 8'b0;  	
		#10; // ��λ 10u
		rst_n = 1;   
		#10; // �ȴ� 100ns ��ʼ�����ź�
	
		repeat (2048*50) begin
            signal_in_unsigned = 40 + 40 * $sin(2 * 3.1415926 * $time / 1000000); // 1000us ����
            #100; // ÿ���������� 20ns
        end 
	
	    repeat (100) begin         
            signal_in_unsigned = 79; // �ߵ�ƽ
            #500000;            // ���ָߵ�ƽ 100us
            signal_in_unsigned = 0;  // �͵�ƽ
            #500000;            // ���ֵ͵�ƽ 100us
        end  
	
		// ��ʼ��
		signal_in_unsigned = 128;
		
		
		repeat (100) begin         
			signal_in_unsigned = 128;
			// ��һ�Σ�ֱ����DC��
			#100000;  // ����100usֱ��
			
			// �ڶ��Σ�������Noise��
			generate_noise(50);  // ����50����������
			
        end  
		
		$stop;
	end
	
	// ������������
	task generate_noise(input integer samples);
		integer i;
		for (i=0; i<samples; i=i+1) begin
			signal_in_unsigned = $urandom_range(0, 255);  // ���������0~255��
			#1000;  // ÿ�����������1us
		end
	endtask  */

endmodule