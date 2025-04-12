module wave_cal #(
    parameter N = 8,                       // 数据位宽
    parameter SAMPLE_POINTS = 64,         // 采样点数
    parameter LOG_2_SAMPLE_POINTS = 6,    // 采样点数的对数
    parameter JUDGE_THRESHOLD = 700,      // 判断阈值
    parameter FRE_DIV = 1249              // 频率分频系数
)(
    input wire clk,                       // 主时钟 (20kHz)
    input wire rst_n,                     // 复位信号
    input wire [N-1:0] data_in_unsigned,  // 无符号输入数据
    
    output reg signed[N-1:0] signal_dc_removed,  // 去除直流分量后的有符号输出
    output reg unsigned[N-1:0] vpp,              // 峰峰值
    output reg unsigned[N-1:0] dc_offset,        // 直流分量
    output reg [N-1:0] papr,                       // 峰均功率比
    output reg is_sine_wave                      // 1=正弦波，0=非正弦波
);

    // DC Remover部分变量
    reg [N-1:0] sampled_data [0:SAMPLE_POINTS-1];
    reg [LOG_2_SAMPLE_POINTS:0] sample_count_dc;
    reg unsigned[N-1:0] max_value;
    reg unsigned[N-1:0] min_value;
    reg [N:0] max_plus_min;

	
    // Wave Identifier部分变量
    wire sample_clk;
    reg signed[31:0] sum_squares = 0;
    reg signed[31:0] err_vpp_valid = 0;
    reg [LOG_2_SAMPLE_POINTS:0] sample_count_id = 0;
    
    // 时钟分频器
    clk_divider #(.FRE_DIV (FRE_DIV)) clk_divider_inst(
        .clk(clk),
        .rst_n(rst_n),
        .sample_en(sample_clk)
    );
    
    // DC Remover采样过程
    always @(posedge sample_clk or negedge rst_n) begin
        if (!rst_n) begin
            sample_count_dc <= 0;
            max_value <= 0;
            min_value <= {N{1'b1}};  // 初始化为最大值
            vpp <= 0;
            dc_offset <= 0;
        end else begin
            sampled_data[sample_count_dc] <= data_in_unsigned;
            
            // 更新最大值和最小值
            if (data_in_unsigned > max_value) begin
                max_value <= data_in_unsigned;
            end
            
            if (data_in_unsigned < min_value) begin
                min_value <= data_in_unsigned;
            end
            
            // 在采样周期结束时计算vpp和dc_offset
            if(sample_count_dc == SAMPLE_POINTS -1) begin
                // 使用临时变量计算中间结果
                max_plus_min = max_value + min_value;  // 先计算和

                vpp = max_value - min_value;
                dc_offset <= max_plus_min >> 1;  // 相当于(max + min)/2
                max_value <= 0;
                min_value <= {N{1'b1}};
                sample_count_dc <= 0;
            end else begin
                sample_count_dc <= sample_count_dc + 1;
            end
        end
    end

    // // DC Remover采样过程
    // always @(posedge sample_clk or negedge rst_n) begin
    //     if (!rst_n) begin
    //         sample_count_dc <= 0;
    //         max_value <= 0;
    //         min_value <= {N{1'b1}};  // 初始化为最大值
    //         vpp <= 0;
    //         dc_offset <= 0;
    //     end else begin
    //         sampled_data[sample_count_dc] <= data_in_unsigned;
    //         if (data_in_unsigned > max_value) begin
    //             max_value <= data_in_unsigned;
    //         end
            
    //         if (data_in_unsigned < min_value) begin
    //             min_value <= data_in_unsigned;
    //         end
    //         // sample_count_dc <= sample_count_dc + 1;
            
    //         if(sample_count_dc == SAMPLE_POINTS -1)begin
    //             vpp <= max_value - min_value;
    //             dc_offset <= (max_value >> 1 + min_value >> 1) ;
    //             max_value <= 0;
    //             min_value <= {N{1'b1}};
    //             sample_count_dc <= 0;  // 重置计数器
    //         end else 
    //             sample_count_dc <= sample_count_dc + 1;
    //     end
    // end
    
    // 去除直流分量
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            signal_dc_removed <= 0;
        end else if (dc_offset) begin     //只要计算出直流分量的值
            signal_dc_removed <= data_in_unsigned - dc_offset;
        end
    end
    
    // Wave Identifier计算部分
    wire signed[31:0] vpp_squared = vpp * vpp;                     // Vpp2
    wire signed[31:0] vpp_squared_scaled = vpp_squared >> 3;       // Vpp2/8 ≒ Vpp2>>3
    wire signed[31:0] valid = sum_squares >> LOG_2_SAMPLE_POINTS;   // Vrms2
    reg signed[31:0] valid_final;   // Vrms2


    always @(posedge sample_clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_squares <= 32'd0;
            sample_count_id <= 10'd0;
            is_sine_wave <= 1'b0;
            papr <= 8'd0;
        end else begin      
            // sample_count_id <= sample_count_id + 1'b1;
            sum_squares <= sum_squares + signal_dc_removed * signal_dc_removed;        
 
            if (sample_count_id == SAMPLE_POINTS - 1) begin      //达到采样点的周期
                if(valid) papr <= vpp_squared/valid;
                else papr <= 0;
            
                if(valid > vpp_squared_scaled) err_vpp_valid = valid - vpp_squared_scaled;
                else err_vpp_valid = vpp_squared_scaled - valid;
            
                if (err_vpp_valid < JUDGE_THRESHOLD) begin
                    is_sine_wave <= 1'b1;  // 正弦波
                end else begin
                    is_sine_wave <= 1'b0;  // 非正弦波
                end
                valid_final <= valid;
                sum_squares <= 32'd0;
                sample_count_id <= 10'd0;
            end else
                sample_count_id <= sample_count_id + 1'b1;
        end
    end

endmodule