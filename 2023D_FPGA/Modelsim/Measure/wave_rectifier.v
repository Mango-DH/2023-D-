module wave_rectifier #( parameter N = 8)(
    input clk,                  	// 50Mhz 时钟
    input rst_n,                  	// 同步复位
    input signed[N-1:0] signal_dc_removed, 
    output reg signal_rectified  	// 整流后的方波信号
);

    // 整流逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            signal_rectified <= 1'b0; // 复位时输出低电平
        end else begin
			signal_rectified <= (signal_dc_removed > 0) ? 1'b1 : 1'b0;
        end
    end

endmodule