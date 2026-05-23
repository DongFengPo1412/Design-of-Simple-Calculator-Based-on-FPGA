module float_display(
    input [31:0] float_in,        // 输入IEEE 754单精度浮点数
    input clk,                    // 时钟信号
    output reg [7:0] seg,         // 七段显示器段选
    output reg [5:0] dig          // 数字选择
);
    // 分频
    reg [24:0] clk_div_cnt = 0;
    reg clk_div = 0;
    always @(posedge clk) begin
        if (clk_div_cnt == 49999) begin // 1kHz时钟
            clk_div = ~clk_div;
            clk_div_cnt = 0;
        end else begin
            clk_div_cnt = clk_div_cnt + 1;
        end
    end

    // 提取IEEE 754浮点数各个部分
    wire sign = float_in[31];
    wire [7:0] exponent = float_in[30:23];
    wire [22:0] mantissa = float_in[22:0];

    // 计算浮点数的值
    reg [31:0] float_value;
    always @(float_in) begin
        if (exponent == 8'hff) begin
            // Inf 或 NaN 处理
            float_value = 32'h7f800000; // +∞
        end else if (exponent == 8'h00) begin
            // 非规范化数或零
            float_value = 32'h00000000;
        end else begin
            // 计算规范化浮点数
            float_value = {sign, exponent - 8'd127, mantissa};
        end
    end

    // 处理浮点数为整数和小数
    reg [15:0] integer_part;
    reg [7:0] decimal_part;
    always @(float_value) begin
        // 你可以根据自己的需求转换为合适的整数和小数值
        integer_part = float_value[15:0];  // 假设只取低16位
        decimal_part = float_value[23:16]; // 取高8位作为小数部分
    end

    // 分时显示的计数器
    reg [2:0] num = 0;
    always @(posedge clk_div) begin
        if (num >= 5) num = 0;
        else num = num + 1;
    end

    // 显示数字选择器
    reg [3:0] disp_data;
    always @(num) begin
        case(num)
            0: disp_data = integer_part[3:0];
            1: disp_data = integer_part[7:4];
            2: disp_data = integer_part[11:8];
            3: disp_data = integer_part[15:12];
            4: disp_data = decimal_part[3:0];
            5: disp_data = decimal_part[7:4];
            default: disp_data = 0;
        endcase
    end

    // 七段显示译码器
    always @(disp_data) begin
        case(disp_data)
            4'h0: seg = 8'h3f;
            4'h1: seg = 8'h06;
            4'h2: seg = 8'h5b;
            4'h3: seg = 8'h4f;
            4'h4: seg = 8'h66;
            4'h5: seg = 8'h6d;
            4'h6: seg = 8'h7d;
            4'h7: seg = 8'h07;
            4'h8: seg = 8'h7f;
            4'h9: seg = 8'h6f;
            default: seg = 8'h00;
        endcase
    end

    // 数字选择器译码器
    always @(num) begin
        case(num)
            0: dig = 6'b111110;
            1: dig = 6'b111101;
            2: dig = 6'b111011;
            3: dig = 6'b110111;
            4: dig = 6'b101111;
            5: dig = 6'b011111;
            default: dig = 6'b111111;
        endcase
    end
endmodule
