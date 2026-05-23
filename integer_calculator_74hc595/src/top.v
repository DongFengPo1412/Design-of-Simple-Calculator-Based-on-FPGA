module top #( 
    parameter           TCLK        =       83          ,//系统时钟周期，默认83ns.
    parameter           TIME_20MS   =       20_000_000  ,//按键消抖时间，默认20ms，单位ns。
    parameter           TIME_20US   =       20_000      ,//每个数码管刷新时间，默认20us。
    parameter           SEG_NUM     =       6           ,//数码管的个数，默认6个；
    parameter           SCLK_DIV    =       4            //sclk与系统时钟的分频系数。 
)(
    input									clk		    ,//系统时钟信号,12MHz，周期约83ns。
    input									rst_n	    ,//系统复位信号，低电平有效；

    input				[3 : 0]	            key_col     ,//矩阵键盘列输入；
    output              [3 : 0]             key_row     ,//矩阵键盘行输出；
    output                                  ds          ,//74HC595串行数据线;
    output                                  sclk        ,//74HC595移位寄存器时钟；
    output                                  rclk         //74HC595锁存器时钟；
);
    wire                [3 : 0]             key_out     ;
    wire                                    key_vld     ;
    wire                                    div_en      ;
    wire                                    mult_en     ;
    wire                [26 : 0]            data1       ;
    wire                [26 : 0]            data2       ;
    wire                [26 : 0]            product     ;
    wire                                    product_vld ;
    wire                [26 : 0]            quotient    ;
    wire                                    quotient_vld;
    wire                [26 : 0]            operat_out  ;
    wire                [31 : 0]            bcd_out     ;
    wire                [6 : 0]             segment     ;//八段数码管段选信号；
    wire                [SEG_NUM - 1 : 0]   seg_sel     ;//八段数码管位选信号；
    wire                                    sel_vld     ;

    wire                [31 : 0]            float_data1;   // 浮点数输入1
    wire                [31 : 0]            float_data2;   // 浮点数输入2
    wire                [31 : 0]            float_result;  // 浮点数运算结果
    wire                                    float_en;       // 浮点运算使能
    wire                                    float_vld;      // 浮点运算结果有效指示信号

    //例化矩阵键盘，按键检测模块；
    key_scan #(
        .TCLK       ( TCLK      ),//系统时钟clk周期，单位ns；
        .TIME_20MS  ( TIME_20MS ) //按键消抖时间，默认20ms，单位ns。
    )
    u_key_scan (
        .clk        ( clk       ),//系统时钟信号，默认50MHz。
        .rst_n      ( rst_n     ),//系统复位信号，低电平有效；
        .key_col    ( key_col   ),//矩阵键盘列输入信号；
        .key_row    ( key_row   ),//矩阵键盘行输出信号；
        .key_out    ( key_out   ),//矩阵键盘被按下按键的编号；
        .key_vld    ( key_vld   ) //矩阵键盘被按下键盘编号有效指示信号；
    );

    //例化浮点运算模块
    ALU_float u_ALU_float (
        .clk        ( clk           ),  // 系统时钟
        .rst_n      ( rst_n         ),  // 系统复位，低电平有效
        .start         ( float_en      ),  // 浮点运算使能信号
        .A      ( float_data1   ),  // 浮点数输入1
        .B      ( float_data2   ),  // 浮点数输入2
        .C     ( float_result  ),  // 浮点运算结果
        .error        ( float_vld     )   // 运算结果有效指示信号
    );

    //例化运算控制模块；
    operation_ctrl  u_operation_ctrl (
        .clk            ( clk           ),
        .rst_n          ( rst_n         ),
        .din_key        ( key_out       ),
        .din_key_vld    ( key_vld       ),
        .mult_vld       ( product_vld   ),
        .mult_in        ( product       ),
        .mult_en        ( mult_en       ),
        .data1          ( data1         ),
        .data2          ( data2         ),
        .dout           ( operat_out    )
    );

    //例化二进制转BCD模块；
    hex2bcd #(
        .IN_DATA_W  ( 27    )//输入27位2进制数据；
        )
    u_hex2bcd (
        .clk        ( clk       ),//系统时钟信号，默认50MHz。
        .rst_n      ( rst_n     ),//系统复位信号，低电平有效；
        .din        ( operat_out),//需要被转换的二进制数据；
        .din_vld    ( 1'b1      ),//输入数据一直有效；
        .dout       ( bcd_out   ),//转换完成的BCD码数据；
        .dout_vld   (           )
    );

    //例化数码管显示模块；
    seg_disp #(
        .TIME_20US  ( TIME_20US ),//每个数码管刷新时间，默认20us。
        .TCLK       ( TCLK      ),//系统时钟周期，默认83ns.
        .SEG_NUM    ( SEG_NUM   ) //数码管的个数，默认6个；
    )
    u_seg_disp (
        .clk        ( clk       ),//系统时钟信号，默认12MHz。
        .rst_n      ( rst_n     ),//系统复位信号，低电平有效；
        .din        ( bcd_out   ),//将BCD码进行显示；
        .segment    ( segment   ),//数码管的段选信号；
        .seg_sel    ( seg_sel   ),//数码管的位选信号；
        .dout_vld   ( sel_vld   )
    );
 
endmodule
