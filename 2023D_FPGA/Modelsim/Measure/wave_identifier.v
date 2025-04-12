module wave_identifier#(
    parameter JUDGE_THRESHOLD = 700,   // �ж���ֵ
	parameter FRE_DIV = 1249,			//��Ƶϵ��
	parameter SAMPLE_POINTS = 64,		//��������
	parameter LOG_2_SAMPLE_POINTS = 6
	
) (
    input clk,           					// 20kHz ʱ��
    input rst_n,                			// ͬ����λ
    input signed[7:0] signal_dc_removed,   	// ����ֱ���������ź�
	input unsigned[7:0] vpp,
 	input unsigned[7:0] dc_offset,  
	   
	output reg [7:0]papr,   			// ���papr
    output reg is_sine_wave   			// 1=���Ҳ���0=����
);

	wire sample_clk;

	clk_divider #(.FRE_DIV (FRE_DIV))clk_divider_inst(
		.clk(clk),                	// ����ʱ�ӣ�50 MHz��
		.rst_n(rst_n),              // �첽��λ�źţ��͵�ƽ��Ч��
		.sample_en(sample_clk)      // ����ʹ���ź�
	);

    reg signed[31:0] sum_squares = 0;			// �ۼ�ƽ����
	reg signed[31:0] err_vpp_valid = 0;
    reg [9:0] sample_count = 0; 				// ����

    wire signed[31:0] vpp_squared = vpp * vpp;     			 			 // Vpp2�����255*255=65025
    wire signed[31:0] vpp_squared_scaled = vpp_squared >> 3; 			 // Vpp2/8 �� Vpp2>>3
    wire signed[31:0] valid = sum_squares >> LOG_2_SAMPLE_POINTS;    // Vrms2

    always @(posedge sample_clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_squares <= 32'd0;
            sample_count <= 10'd0;
            is_sine_wave <= 1'b0;
			papr <= 8'd0;
			
        end else begin      
			sample_count <= sample_count + 1'b1;
			if(dc_offset)sum_squares <= sum_squares + signal_dc_removed * signal_dc_removed;		
 
            if (sample_count == SAMPLE_POINTS - 1) begin      //����������ʱ��
				if(valid)papr <= vpp_squared/valid;
				else papr <= 0;
			
				if(valid > vpp_squared_scaled) err_vpp_valid = valid - vpp_squared_scaled;
				else err_vpp_valid = vpp_squared_scaled - valid;
			
                if (err_vpp_valid < JUDGE_THRESHOLD) begin
                    is_sine_wave <= 1'b1;  // ���Ҳ�
                end else begin
                    is_sine_wave <= 1'b0;  // ����
                end
                sum_squares <= 32'd0;
                sample_count <= 10'd0;
            end
        end
    end

endmodule