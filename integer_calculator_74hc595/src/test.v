`timescale 1 ns/1 ns
module test();
    localparam 	CYCLE		=   20          ;//系统时钟周期，单位ns，默认20ns；
    localparam 	RST_TIME	=   10          ;//系统复位持续时间，默认10个系统时钟周期；
    localparam  TIME_20MS   =   4_000       ;//按键消抖时间，默认20ms，单位ns,仿真时将时间缩短；
    localparam  TIME_20US   =   4000        ;//每个数码管刷新时间，默认20us；

    reg			                clk         ;//系统时钟，默认100MHz；
    reg			                rst_n       ;//系统复位，默认低电平有效；
    reg   [3 : 0]               key_col     ;
    reg   [3 : 0]               key_col_r   ;
    reg                         key_col_sel ;
    reg   [1 : 0]               now_row     ;//当前行
    reg   [1 : 0]               now_col     ;//当前列；

    wire  [3 : 0]               key_row     ;
    wire                        ds          ;
    wire                        sclk        ;
    wire                        rclk        ;

    //例化需要测试的模块；
    top #(
        .TCLK       ( CYCLE     ),
        .TIME_20MS  ( TIME_20MS ),
        .TIME_20US  ( TIME_20US )
    )
    u_top (
        .clk        ( clk       ),
        .rst_n      ( rst_n     ),
        .key_col    ( key_col   ),
        .key_row    ( key_row   ),
        .ds         ( ds        ),
        .sclk       ( sclk      ),
        .rclk       ( rclk      ) 
    );

    //生成周期为CYCLE数值的系统时钟;
    initial begin
        clk = 0;
        forever #(CYCLE/2) clk = ~clk;
    end

    //生成复位信号；
    initial begin
        rst_n = 1;key_col = 4'hf;key_col_sel=0;
        key_col_r = 4'hf;now_col = 0;now_row = 0;
        #1;
        rst_n = 0;//开始时复位10个时钟；
        #(RST_TIME*CYCLE);
        rst_n = 1;
        #(20*CYCLE);
        key_task(0,1);//按下第0行第1列按键；输入2
        key_task(1,2);//按下第1行第2列按键；输入6
        key_task(0,3);//按下第0行第3列按键，输入加号
        key_task(0,1);//按下第0行第1列按键；输入2
        key_task(2,2);//按下第2行第2列按键；输入9
        key_task(3,0);//按下第3行第0列按键，输入0
        key_task(3,2);//按下第3行第2列按键，输入等号
        key_task(1,3);//按下第1行第3列按键，输入减号
        key_task(2,1);//按下第2行第1列按键；输入8
        key_task(0,1);//按下第0行第1列按键，输入2
        key_task(3,2);//按下第3行第2列按键，输入等号
        key_task(2,3);//按下第2行第3列按键，输入乘号
        key_task(0,0);//按下第0行第0列按键；输入1
        key_task(0,2);//按下第0行第2列按键，输入3
        key_task(2,3);//按下第2行第3列按键，输入乘号
        key_task(3,3);//按下第3行第3列按键，输入除号
        key_task(3,2);//按下第3行第2列按键，输入等号
        key_task(3,3);//按下第3行第3列按键，输入除号
        key_task(2,0);//按下第2行第0列按键；输入7
        key_task(0,0);//按下第0行第0列按键，输入1
        key_task(3,2);//按下第3行第2列按键，输入等号
        #(20*CYCLE);
        $stop;//停止仿真；
    end

    //生成对应按键的信号；
    task key_task(
        input	[1 : 0]		row	,//被按下按键的行号；
        input	[1 : 0]	    col  //被按下按键的列号；
    );
        begin
            now_col <= col;
            now_row <= row;
            key_col_r <= 4'hf;//初始时，没有按键被按下；
            key_col_sel <= 1'b0;
            @(posedge clk);
            key_col_r[col] <= 1'b0;//
            repeat(20) begin//将信号随机翻转20次，模拟按键按下时的抖动。
                #(({$random} % (TIME_20MS/(CYCLE+5))) * CYCLE);
                key_col_r[col] <= ~key_col_r[col];
            end
            key_col_sel <= 1'b1;//列选通信号拉高；
            repeat(TIME_20MS/7)begin//按键按下的保持时间；
                @(posedge clk);
            end
            key_col_sel <= 1'b0;//列选通信号拉低；
            key_col_r <= 4'hf;//按键被释放；
            repeat(20) begin//将信号随机翻转20次，模拟按键释放时的抖动。
                #(({$random} % (TIME_20MS/(CYCLE+5))) * CYCLE);
                key_col_r[col] <= ~key_col_r[col];
            end
            #(({$random} % (TIME_20MS/(CYCLE+20))) * CYCLE);
            key_col_r[col] <= 1'b1;//确保按键被释放；
            repeat(TIME_20MS)begin//释放按键的保持时间；
                @(posedge clk);
            end
        end
    endtask

    always@(*)begin
        if(key_col_sel)begin
            case (now_col)
                    2'd0 : key_col <= {3'd7,key_row[now_row]};
                    2'd1 : key_col <= {2'd3,key_row[now_row],1'd1};
                    2'd2 : key_col <= {1'd1,key_row[now_row],2'd3};
                    2'd3 : key_col <= {key_row[now_row],3'd7};
            endcase
        end
        else begin
            key_col <= key_col_r;
        end
    end

endmodule