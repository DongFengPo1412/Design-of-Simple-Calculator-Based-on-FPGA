`timescale 1ns / 1ps


module Top(
    input clk,
    input rst,
    input [11:0] sw,
    input [3:0] col,
    output [3:0] row,
    output [11:0] led,
    output [7:0] seg,
    output [5:0] an
    );

reg clkout =0;




div50 div50(//分频，用于时钟消抖
    .clkin(clk),
    .clr(clr),
    .clkout(clkout)
);




operation_ctrl control(//控制模块，整体的状态机
    .clk(clk),
    .rst_n(rst),
    .din_key(btn_out),
    .din_key_vld(),
    .mult_in(),
    .mult_en(),
    .data1(),
    .dout()

);



v_ajxd uut_ajxd(    //调用按键消抖动IP
    .clk(clk_ms),
    .btn_clk(clkout),
    .col(col),
    .row(row),
    .btn_out(btnout)
 );


//数据转化，将输入的数转为浮点数,第一个数
input_parser inpu_data1(
    .clk(clk),
    .reset(rst),
    .key_code(btn_out),
    .float_output(data1),
    .operator(S)
);


input_parser inpu_data2(
    .clk(clk),
    .reset(rst),
    .key_code(btn_out),
    .float_output(data2)
);

float_to_ieee754 data1
(
    .value(data1),
    .ieee754_val(data_iee754_1)
);

float_to_ieee754 data2
(
    .value(data1),
    .ieee754_val(data_iee754_2)
);



ALU_float ALU_float( //计算模块，用于实现计算
        .clk(clk),
        .rst_n(rst),//复位信号
        .start(start),
        .S(S),
        .A(data_iee754_1),
        .B(data_iee754_2),
        .C(C),
        .error(error),
        .ready(ready)
);

float_display disp
(
    .float_in(C),
    .clk(clk),
    .seg(seg),
    .dig(dig)
);






endmodule