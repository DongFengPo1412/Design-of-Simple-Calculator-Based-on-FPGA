module  key_scan #(
    parameter       TCLK            =   20                      ,//系统时钟周期，单位ns。
    parameter       TIME_20MS       =   20_000_000              //按键消抖时间，单位为ns。
)(  
    input                               clk                     ,//系统时钟信号，默认50MHz。
    input                               rst_n                   ,//系统复位，低电平有效；
    input           [3 : 0]             key_col                 ,//矩阵键盘的列号；
    output reg      [3 : 0]             key_row                 ,//矩阵键盘的行号；
    output reg      [3 : 0]             key_out                 ,//矩阵键盘被按下按键的数值；
    output reg                          key_vld                  //矩阵键盘被按下按键数据输出有效指示信号；
);  
    //自定义参数；
    localparam      CHK_COL         =   4'b0001                 ;//状态机的列扫描状态；
    localparam      CHK_ROW         =   4'b0010                 ;//状态机的的行扫描状态；
    localparam      DELAY           =   4'b0100                 ;//状态机的延时状态；
    localparam      WAIT_END        =   4'b1000                 ;//状态机的等待状态；
    localparam      TIME_20MS_NUM   =  TIME_20MS / TCLK         ;//计算出TIME_20MS对应的系统时钟个数；
    localparam      TIME_20MS_W     =   clogb2(TIME_20MS_NUM-1) ;//利用函数计算出TIME_20MS_NUM对应的寄存器位宽；

    reg   [3 : 0]                       key_col_ff0             ;
    reg   [3 : 0]                       key_col_ff1             ;
    reg   [1 : 0]                       key_col_get             ;
    reg   [3 : 0]                       state_c                 ;
    reg   [TIME_20MS_W - 1 : 0]         shake_cnt               ;
    reg   [3 : 0]                       state_n                 ;
    reg   [1 : 0]                       row_index               ;
    reg   [3 : 0]                       row_cnt                 ;

    wire                                end_shake_cnt           ;
    wire                                col2row_start           ;
    wire                                row2del_start           ;
    wire                                del2wait_start          ;
    wire                                wait2col_start          ;
    wire                                add_row_cnt             ;
    wire                                end_row_cnt             ;
    wire                                add_shake_cnt           ;
    wire                                add_row_index           ;
    wire                                end_row_index           ;

    //自动计算位宽函数；
    function integer clogb2(input integer depth);begin
        if(depth == 0)
            clogb2 = 1;
        else if(depth != 0)
            for(clogb2=0 ; depth>0 ; clogb2=clogb2+1)
                depth=depth >> 1;
        end
    endfunction

    //将输入的列信号打两拍，降低亚稳态出现的机率。
    always@(posedge clk)begin
        {key_col_ff1,key_col_ff0} <= {key_col_ff0,key_col};
    end

    //计数器shake_cnt，如果有按键被按下，则key_col_ff1!=4'hf，此时计数器计数。
    always@(posedge clk or negedge rst_n)begin
        if(rst_n==0)begin
            shake_cnt <= 0;
        end
        else if(add_shake_cnt)begin
            if(end_shake_cnt)//按键被按下20ms时，计数器清零；
                shake_cnt <= 0;
            else//否则当按键被按下时，计数器进行计数；
                shake_cnt <= shake_cnt + 1;
        end
        else begin//没有按键被按下时，计数器清零；
            shake_cnt <= 0;
        end
    end
    assign add_shake_cnt = (key_col_ff1!=4'hf);
    assign end_shake_cnt = add_shake_cnt  && shake_cnt == TIME_20MS_NUM-1 ;

    //当列检查结束时，将被按下按键所在列寄存；
    always@(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin//初始为0，没有按键被按下；
            key_col_get <= 0;
        end
        else if(col2row_start)begin//当状态机从列检查跳转到行检查时，将按键对应列保存；
            if(key_col_ff1==4'b1110)//最低位为0，则表示第0列按键被按下；
                key_col_get <= 0;
            else if(key_col_ff1==4'b1101)//第1位位0，则表示第1列按键被按下；
                key_col_get <= 1;
            else if(key_col_ff1==4'b1011)//第2位位0，则表示第2列按键被按下；
                key_col_get <= 2;
            else//否则表示第3列按键被按下；
                key_col_get <= 3;
        end
    end

    //状态机的第一段；
    always@(posedge clk or negedge rst_n)begin  
        if(rst_n==1'b0)begin  
            state_c <= CHK_COL;  
        end  
        else begin  
            state_c <= state_n;  
        end  
    end

    always@(*)begin  
        case(state_c)
            CHK_COL: begin//检查列触发；
                        if(col2row_start)begin
                            state_n = CHK_ROW;
                        end
                        else begin
                            state_n = CHK_COL;
                        end
                    end
            CHK_ROW: begin//检查行触发；
                        if(row2del_start)begin
                            state_n = DELAY;
                        end
                        else begin
                            state_n = CHK_ROW;
                        end
                    end
            DELAY :  begin//这个状态的存在是为了等待行扫描结束后，计算结果输出。
                        if(del2wait_start)begin
                            state_n = WAIT_END;
                        end
                        else begin
                            state_n = DELAY;
                        end
                    end
            WAIT_END: begin//此时四行全部输出低电平，如果按键被按下，没有松开，那么会持续之前的状态，就需要一致等待按键松开；
                        if(wait2col_start)begin
                            state_n = CHK_COL;
                        end
                        else begin
                            state_n = WAIT_END;
                        end
                    end
            default: state_n = CHK_COL;
        endcase
    end
    //状态机第三段，描述
    assign col2row_start = (state_c==CHK_COL ) && end_shake_cnt;//检查到有对应列持续20MS被按下。
    assign row2del_start = (state_c==CHK_ROW ) && end_row_index;//行扫描完成；
    assign del2wait_start= (state_c==DELAY   ) && end_row_cnt;
    assign wait2col_start= (state_c==WAIT_END) && key_col_ff1==4'hf;//4'hf表示前面的按键已经被松开，状态机重新回到列检测状态。

    //控制行数据的输出，在检查被按下按键所在行时，进行行循环扫描。
    //从第一行开始一次拉低，其余行拉高，其余时刻所有行全部拉低。
    always@(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            key_row <= 4'b0;
        end
        else if(state_c==CHK_ROW)begin//行扫描，依次将每行的电平拉低。
            key_row <= ~(1'b1 << row_index);
        end
        else begin
            key_row <= 4'b0;
        end
    end

    //行扫描的计数器，对行进行扫描。
    //每行扫描持续时间为行计数器row_cnt的计数值，目前为16个时钟周期。
    //当4行全部扫面完毕时，计数器清零；
    always@(posedge clk or negedge rst_n)begin
        if(rst_n==0)begin
            row_index <= 0;
        end
        else if(add_row_index) begin
            if(end_row_index)
                row_index <= 0;
            else
                row_index <= row_index + 1;
        end
        else if(state_c!=CHK_ROW)begin
            row_index <= 0;
        end
    end
    assign add_row_index = state_c==CHK_ROW && end_row_cnt;
    assign end_row_index = add_row_index  && row_index == 4-1 ;

    //每行扫描持续时间，初始值为0，此处设置每行扫面16个时钟周期；
    //状态机位于行扫描或者等待状态时进行计数，当计数到最大值16时清零。
    always@(posedge clk or negedge rst_n)begin
        if(rst_n==0)begin
            row_cnt <= 0;
        end
        else if(add_row_cnt)begin
            if(end_row_cnt)
                row_cnt <= 0;
            else
                row_cnt <= row_cnt + 1;
        end
    end
    assign add_row_cnt = state_c==CHK_ROW || state_c==DELAY;
    assign end_row_cnt = add_row_cnt  && row_cnt == 16-1;

    always@(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            key_out <= 0;
        end//计算被按下按键的数值；
        else if(state_c==CHK_ROW && end_row_cnt && key_col_ff1[key_col_get]==1'b0)begin
            key_out <= {row_index,key_col_get};
        end
    end

    //按键数值有效指示信号，高电平时表示key_out输出的值是有效的。
    always@(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            key_vld <= 1'b0;
        end
        else begin//当没扫描一行，前面暂存的列为低电平的时候，表示这一行，这一列的按键被按下。
            key_vld <= (state_c==CHK_ROW && end_row_cnt && key_col_ff1[key_col_get]==1'b0);
        end
    end

endmodule