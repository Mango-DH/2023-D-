module ma_measure (
    input        clk,
    input        rst_n,
	input        ma_measure_enable,
    input  		[7:0] vpp,      // 峰峰值，8位无符号
    output reg 	[7:0] ma    // 调制度，范围30~100（百分比）
);
    reg [31:0] vpp_mult;   // 放大vpp*10000
    reg [31:0] sum;
    reg [31:0] ma_temp;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vpp_mult <= 0;
            sum      <= 0;
            ma_temp  <= 0;
            ma       <= 0;
        end else if (ma_measure_enable)begin
            // vpp * 10000 = vpp*(8192 + 1024 + 512 + 256 + 16)
            vpp_mult <= (vpp << 13) + (vpp << 10) + (vpp << 9) + (vpp << 8) + (vpp << 4);

            // sum = vpp*10000 + 7143
            sum <= vpp_mult + 7143;

            // ma = sum / 8714, 8714 ≈ 2^13 + 2^9 + 2^7 + 2^5 + 2
            // 为避免除法，用乘法近似除法：(sum * 15) >> 17 ≈ sum / 8714
            ma_temp <= (sum * 15) >> 17;

            // 限制范围30~100
            if (ma_temp < 30)
                ma <= 30;
            else if (ma_temp > 100)
                ma <= 100;
            else
                ma <= ma_temp[7:0];
        end
    end
endmodule
