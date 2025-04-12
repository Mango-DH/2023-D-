module frequency_counter  #(
	parameter MEASURE_CLK_CNT = 200,		//1s内计数的个数，即计数时钟的频率
	parameter MEASURE_CLK = 20000
)(
    input clk,                	// 测频时钟
    input rst_n,              	// 复位信号
    input signal_in,          	// 输出整流后的信号
    output reg [15:0] freq_out 	// 输出频率值
);
    reg signal_prev;          // 用于检测上升沿
    reg [16:0] count_clk;     // 主频时钟计数器
    reg [16:0] count_signal;  // 输入信号计数器
    reg [16:0] N1;            // 主频时钟上升沿计数
    reg [16:0] N2;            // 输入信号上升沿计数

    // 检测输入信号的上升沿
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            signal_prev <= 1'b0;
        end else begin
            signal_prev <= signal_in;
        end
    end

    // 主频时钟和输入信号的上升沿计数
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count_clk <= 16'd0;
            count_signal <= 16'd0;
            N1 <= 16'd0;
            N2 <= 16'd0;
        end else begin
            count_clk <= count_clk + 1;  // 主频时钟计数

            // 检测输入信号的上升沿
            if (signal_in && !signal_prev) begin
                count_signal <= count_signal + 1;  // 输入信号计数
            end

            // 在固定时间内记录计数
            if (count_clk == MEASURE_CLK_CNT) begin  //计数时钟是20kHz
                N1 <= count_clk;
                N2 <= count_signal;
                count_clk <= 16'd0;
                count_signal <= 16'd0;
            end
        end
    end

    // 计算频率
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            freq_out <= 16'd0;
        end else if (N1 != 16'd0) begin
            freq_out <= (N2 * MEASURE_CLK) / N1;  // 频率计算公式
        end
    end
endmodule