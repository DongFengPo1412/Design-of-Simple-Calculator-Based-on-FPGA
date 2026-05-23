module fp_multiplier (
    input [31:0] a, // 第一个浮点数
    input [31:0] b, // 第二个浮点数
    output [31:0] result
);
    // 提取符号位、阶码和尾数
    wire sign_a = a[31];
    wire sign_b = b[31];
    wire [7:0] exp_a = a[30:23];
    wire [7:0] exp_b = b[30:23];
    wire [23:0] mant_a = {1'b1, a[22:0]};
    wire [23:0] mant_b = {1'b1, b[22:0]};
    
    // 符号位计算
    wire sign_res = sign_a ^ sign_b;

    // 阶码计算
    wire [8:0] exp_sum = exp_a + exp_b - 8'd127;

    // 尾数乘法
    wire [47:0] mant_mult = mant_a * mant_b;

    // 规格化处理
    wire [22:0] mant_res;
    wire [7:0] exp_res;
    if (mant_mult[47]) begin
        mant_res = mant_mult[46:24];
        exp_res = exp_sum + 1;
    end else begin
        mant_res = mant_mult[45:23];
        exp_res = exp_sum;
    end

    // 结果组合
    assign result = {sign_res, exp_res, mant_res};
endmodule
