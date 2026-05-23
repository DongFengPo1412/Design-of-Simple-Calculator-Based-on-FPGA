module input_parser (
    input clk,
    input reset,
    input [15:0] key_code,      // 键盘扫描结果
    output reg [31:0] float_output,  // 当前浮动输入
    output reg [2:0] operator // 当前运算符（+，-，*，/）
);
    reg [31:0] int_part;         // 整数部分
    reg [23:0] frac_part;        // 小数部分（最多支持24位小数）
    reg decimal_flag;            // 是否已经输入小数点
    reg [7:0] current_operator;  // 当前操作符

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            int_part <= 32'd0;
            frac_part <= 24'd0;
            decimal_flag <= 1'b0;
            float_output <= 32'd0;
            operator <= 3'b000;  // 默认无运算符
        end else begin
            case (key_code)
                16'h31: begin // 数字 1
                    if (decimal_flag) begin
                        frac_part <= frac_part * 10 + 1;  // 小数部分累积
                    end else begin
                        int_part <= int_part * 10 + 1;    // 整数部分累积
                    end
                end
                16'h32: begin // 数字 2
                    if (decimal_flag) begin
                        frac_part <= frac_part * 10 + 2;
                    end else begin
                        int_part <= int_part * 10 + 2;
                    end
                end
                16'h33: begin // 数字 3
                    if (decimal_flag) begin
                        frac_part <= frac_part * 10 + 3;
                    end else begin
                        int_part <= int_part * 10 + 3;
                    end
                end
                16'h34: begin // 数字 4
                    if (decimal_flag) begin
                        frac_part <= frac_part * 10 + 4;
                    end else begin
                        int_part <= int_part * 10 + 4;
                    end
                end
                16'h35: begin // 数字 5
                    if (decimal_flag) begin
                        frac_part <= frac_part * 10 + 5;
                    end else begin
                        int_part <= int_part * 10 + 5;
                    end
                end
                16'h36: begin // 数字 6
                    if (decimal_flag) begin
                        frac_part <= frac_part * 10 + 6;
                    end else begin
                        int_part <= int_part * 10 + 6;
                    end
                end
                16'h37: begin // 数字 7
                    if (decimal_flag) begin
                        frac_part <= frac_part * 10 + 7;
                    end else begin
                        int_part <= int_part * 10 + 7;
                    end
                end
                16'h38: begin // 数字 8
                    if (decimal_flag) begin
                        frac_part <= frac_part * 10 + 8;
                    end else begin
                        int_part <= int_part * 10 + 8;
                    end
                end
                16'h39: begin // 数字 9
                    if (decimal_flag) begin
                        frac_part <= frac_part * 10 + 9;
                    end else begin
                        int_part <= int_part * 10 + 9;
                    end
                end
                16'h30: begin // 数字 0
                    if (decimal_flag) begin
                        frac_part <= frac_part * 10 + 0;
                    end else begin
                        int_part <= int_part * 10 + 0;
                    end
                end
                16'h2E: begin // 小数点 "."
                    if (!decimal_flag) begin
                        decimal_flag <= 1'b1;  // 设置小数点标志
                    end
                end
                16'h2B: begin // 加号 "+"
                    current_operator <= 8'h2B;
                end
                16'h2D: begin // 减号 "-"
                    current_operator <= 8'h2D;
                end
                16'h2A: begin // 乘号 "*"
                    current_operator <= 8'h2A;
                end
                16'h2F: begin // 除号 "/"
                    current_operator <= 8'h2F;
                end
                default: ;
            endcase

            // 计算浮动数值
            if (decimal_flag) begin
                // 将整数部分和小数部分合并，输出为浮动数值
                float_output <= {int_part, frac_part};  // 整数部分和小数部分组合
            end else begin
                // 如果没有小数点，则仅输出整数部分
                float_output <= int_part;
            end
        end
    end
endmodule
