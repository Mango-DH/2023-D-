module phase_unwrap (
    input wire clk,
    input wire reset_n,
    input wire signed [15:0] phase_in,  // Q3.13格式输入
    output reg signed [31:0] unwrapped_phase  // Q16.16格式输出
);

    reg signed [15:0] prev_phase;
    localparam PI_Q13 = 16'sd25736;      // Q3.13格式的π值 (π * 8192)
    localparam TWO_PI_Q16 = 32'sd411775; // Q16.16格式的2π (2π * 65536)
    wire signed [16:0] phase_diff = {phase_in[15], phase_in} - {prev_phase[15], prev_phase};
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            prev_phase <= 0;
            unwrapped_phase <= 0;
        end else begin
            // 计算相位差（符号扩展为17位）
           
            
            // 解缠逻辑
            if (phase_diff > PI_Q13) begin
                // +π跳变 → 补偿 -2π
                unwrapped_phase <= unwrapped_phase + (phase_diff - 2*PI_Q13);
            end else if (phase_diff < -PI_Q13) begin
                // -π跳变 → 补偿 +2π
                unwrapped_phase <= unwrapped_phase + (phase_diff + 2*PI_Q13);
            end else begin
                // 无跳变 → 直接累加
                unwrapped_phase <= unwrapped_phase + phase_diff;
            end
            
            prev_phase <= phase_in;
        end
    end
endmodule