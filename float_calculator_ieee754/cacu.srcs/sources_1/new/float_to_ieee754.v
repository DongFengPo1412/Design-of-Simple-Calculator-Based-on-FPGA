module float_to_ieee754 (
    input [31:0] value,           // 输入的浮点数
    output reg [31:0] ieee754_val // 转换后的IEEE 754格式
);
    reg sign;        // 符号位
    reg [7:0] exponent;   // 指数位
    reg [22:0] mantissa;  // 尾数位
    reg [31:0] int_part, frac_part;  // 整数部分和小数部分
    reg [7:0] exp_offset;    // 偏移量
    integer i;

    always @(*) begin
        if (value == 0) begin
            ieee754_val = 32'b0; // 如果输入为零，则IEEE 754为全零
        end else begin
            // 1. 符号位
            sign = (value[31] == 1) ? 1 : 0;
            
            // 2. 将浮点数拆分为整数部分和小数部分
            int_part = value;
            frac_part = value - int_part;

            // 3. 获取指数并调整
            exponent = 0;
            while (int_part >= (2 ** (exponent + 1))) begin
                exponent = exponent + 1;
            end

            // 4. 调整指数位以符合偏移量 (127偏移量)
            exponent = exponent + 127; // 加上127偏移量

            // 5. 计算尾数并去掉前导的1（隐式的1）
            mantissa = 0;
            for (i = 22; i >= 0; i = i - 1) begin
                frac_part = frac_part * 2;
                if (frac_part >= 1) begin
                    mantissa[i] = 1;
                    frac_part = frac_part - 1;
                end else begin
                    mantissa[i] = 0;
                end
            end

            // 6. 输出IEEE 754格式
            ieee754_val = {sign, exponent, mantissa}; // 合成最终结果
        end
    end
endmodule
