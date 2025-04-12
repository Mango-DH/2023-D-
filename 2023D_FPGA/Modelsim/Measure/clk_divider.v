module clk_divider #(
	parameter FRE_DIV = 2499				//分频系数
)(
    input clk,                // 输入时钟（50 MHz）
    input rst_n,              // 异步复位信号（低电平有效）
    output reg sample_en      // 采样使能信号
);

    reg [15:0] clk_div;       // 分频计数器

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 复位时清零计数器和使能信号
            clk_div <= 0;
            sample_en <= 0;
        end else begin
            if (clk_div == FRE_DIV) begin
                // 当计数器达到分频系数时，生成采样使能信号
                clk_div <= 0;
                sample_en <= 1;
            end else begin
                // 否则继续计数，并使能信号置为 0
                clk_div <= clk_div + 1;
                sample_en <= 0;
            end
        end
    end

endmodule