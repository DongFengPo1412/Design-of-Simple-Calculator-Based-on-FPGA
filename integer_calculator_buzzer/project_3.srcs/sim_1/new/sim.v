module tb_fp_multiplier;
    reg [31:0] a, b;
    wire [31:0] result;

    // 实例化浮点数乘法器
    fp_multiplier uut (
        .a(a),
        .b(b),
        .result(result)
    );

    initial begin
        // 测试用例 1
        a = 32'h40490FDB; // 3.14
        b = 32'h40000000; // 2.0
        #10;
        $display("a = %h, b = %h, result = %h", a, b, result);

        // 测试用例 2
        a = 32'hC0490FDB; // -3.14
        b = 32'h40490FDB; // 3.14
        #10;
        $display("a = %h, b = %h, result = %h", a, b, result);

        // 测试用例 3
        a = 32'h3F800000; // 1.0
        b = 32'h3F800000; // 1.0
        #10;
        $display("a = %h, b = %h, result = %h", a, b, result);

        $stop;
    end
endmodule
