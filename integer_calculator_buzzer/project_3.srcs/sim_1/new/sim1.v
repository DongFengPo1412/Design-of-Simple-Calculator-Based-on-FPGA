module tb_signed_multiplier;
    reg  signed [10:0] A, B;      // 输入信号
    wire signed [19:0] Product;   // 输出信号

    // 实例化被测模块
    signed_multiplier uut (
        .A(A),
        .B(B),
        .Product(Product)
    );

    initial begin
        // 测试用例
        A = 11'sd123;  B = 11'sd45;   #10; // 123 * 45 = 5535
        A = 11'sd-123; B = 11'sd45;   #10; // -123 * 45 = -5535
        A = 11'sd999;  B = 11'sd-999; #10; // 999 * -999 = -998001
        A = 11'sd-1023; B = 11'sd-1023; #10; // -1023 * -1023 = 1046529
        A = 11'sd0;    B = 11'sd999;  #10; // 0 * 999 = 0
        A = 11'sd-1;   B = 11'sd-1;   #10; // -1 * -1 = 1
        $finish;
    end
endmodule
