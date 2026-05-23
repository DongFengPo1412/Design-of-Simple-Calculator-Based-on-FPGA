module operation_ctrl (
    //输入信号定义
    input                           clk             ,//系统时钟，50MHz。
    input                           rst_n           ,//系统复位，低电平有效。

    input       [3 : 0]             din_key         ,//按键按下的数值；
    input                           din_key_vld     ,//按下指示信号，高电平有效；
    input                           mult_vld        ,//乘法模块运算结果有效指示信号；
    input       [26 : 0]            mult_in         ,//乘法模块运算结果；
    //输出信号定义
    output reg                      mult_en         ,//乘法模块使能信号；
    output reg  [26 : 0]            data1           ,//被乘数数据；
    output reg  [26 : 0]            data2           ,//乘数数据；
    output reg  [26 : 0]            dout             //输出数码管需要显示的数据；
);
    localparam  IDLE        =       5'b00001        ;//状态机的空闲状态编码；
    localparam  IDATA1      =       5'b00010        ;//状态机的输入参数1状态编码；
    localparam  OPERAT      =       5'b00100        ;//状态机的输入运算符状态编码；
    localparam  IDATA2      =       5'b01000        ;//状态机的输入参数2状态编码；
    localparam  RESULT      =       5'b10000        ;//状态机的计算结果状态编码；

    reg                             number_flag     ;//高电平表示由数字按键被按下；
    reg                             operat_flag     ;//高电平表示有运算符按键被按下；
    reg                             din_key_vld_r0  ;//
    reg                             din_key_vld_r1  ;
    reg         [1 : 0]             operation       ;//
    reg         [3 : 0]             din_key_r0      ;//
    reg         [3 : 0]             din_key_r1      ;//
    reg         [4 : 0]             state_n         ;
    reg         [4 : 0]             state_c         ;
    reg         [3 : 0]             key_value       ;//
    reg                             operat_flag_r   ;

    wire                            idl2idata1_start    ;
    wire                            operat2idata2_start ;
    wire                            idata12operat_start ;
    wire                            idata22result_start ;
    wire                            result2idata1_start ;
    wire                            result2operat_start ;

    //第一段：同步时序always模块，描述次态寄存器向现态寄存器转移
    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            state_c <= IDLE;
        end
        else if(din_key_vld && din_key==13)begin//按下清除按键时，状态机回到空闲状态；
            state_c <= IDLE;
        end
        else begin
            state_c <= state_n;
        end
    end

    //第二段：组合逻辑always模块描述状态转移条件判断
    always@(*)begin
        case(state_c)
            IDLE:begin
                if(idl2idata1_start)begin
                    state_n = IDATA1;
                end
                else begin
                    state_n = state_c;
                end
            end
            IDATA1:begin
                if(idata12operat_start)begin
                    state_n = OPERAT;
                end
                else begin
                    state_n = state_c;
                end
            end
            OPERAT:begin
                if(operat2idata2_start)begin
                    state_n = IDATA2;
                end
                else begin
                    state_n = state_c;
                end
            end
            IDATA2:begin
                if(idata22result_start)begin
                    state_n = RESULT;
                end
                else begin
                    state_n = state_c;
                end
            end
            RESULT:begin
                if(result2idata1_start)begin
                    state_n = IDATA1;
                end
                else if(result2operat_start)begin
                    state_n = OPERAT;
                end
                else begin
                    state_n = state_c;
                end
            end
            default:begin
                state_n = IDLE;
            end
        endcase
    end

    //第三段：设计转移条件；
    assign idl2idata1_start    = ((state_c == IDLE) && (number_flag));//空闲状态下有数字按键按下；
    assign idata12operat_start = ((state_c == IDATA1) && (operat_flag));//在输入数据1状态下，有运算符按键按下；
    assign operat2idata2_start = ((state_c == OPERAT) && (number_flag));//在输入运算符状态下，有数字按键被按下；
    assign idata22result_start = ((state_c == IDATA2) && (din_key_vld && din_key==14));//在输入数据2状态下，等号被按下； 
    assign result2idata1_start = ((state_c == RESULT) && (number_flag));//在输出运算结果的状态下，有数字按键被按下；
    assign result2operat_start = ((state_c == RESULT) && (operat_flag));//在输出运算结果的状态下，有运算符被按下；

    always@(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            number_flag <= 1'b0;
        end
        else begin
            number_flag <= din_key_vld && (din_key != 3) && (din_key != 7) && (din_key != 11) && (din_key != 13) && (din_key != 14) && (din_key != 15);
        end
    end

    always@(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            operat_flag <= 1'b0;
        end
        else begin
            operat_flag <= din_key_vld && ((din_key == 3) || (din_key == 7) || (din_key == 11));
        end
    end

    always@(posedge clk)begin
        operat_flag_r <= operat_flag;
        {din_key_r1,din_key_r0} <= {din_key_r0,din_key};
        {din_key_vld_r1,din_key_vld_r0} <= {din_key_vld_r0,din_key_vld};
    end

    always@(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            key_value <= 4'd0;
        end
        else if(din_key_vld_r0)begin
            case(din_key_r0)
                    4'd0  : key_value <= 4'd1;
                    4'd1  : key_value <= 4'd2;
                    4'd2  : key_value <= 4'd3;
                    4'd4  : key_value <= 4'd4;
                    4'd5  : key_value <= 4'd5;
                    4'd6  : key_value <= 4'd6;
                    4'd8  : key_value <= 4'd7;
                    4'd9  : key_value <= 4'd8;
                    4'd10 : key_value <= 4'd9;
                    4'd12 : key_value <= 4'd0;
                default : key_value <= 4'd0;
            endcase
        end
    end

    always@(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            operation <= 2'd0;
        end
        else if((state_c == OPERAT) && din_key_vld_r1)begin
            case(din_key_r1)
                        4'd3  : operation <= 2'd0;
                        4'd7  : operation <= 2'd1;
                        4'd11 : operation <= 2'd2;
                default: operation <= 2'd0;
            endcase
        end
    end

    always@(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            data1 <= 14'd0;
        end
        else if(idl2idata1_start || result2idata1_start)begin
            data1 <= 14'd0;
        end
        else if(result2operat_start)begin
            data1 <= dout;
        end
        else if(din_key_vld_r1 && (state_c == IDATA1))begin
            data1 <= (data1 << 3) + (data1 << 1) + key_value;
        end
    end

    always@(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            data2 <= 14'd0;
        end
        else if(operat2idata2_start)begin
            data2 <= 14'd0;
        end
        else if(~operat_flag_r && din_key_vld_r1 && (state_c == IDATA2))begin
            data2 <= (data2 << 3) + (data2 << 1) + key_value;
        end
    end

    always@(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            dout <= 27'd0;
        end
        else if(state_c == IDATA1)begin
            dout <= data1;
        end
        else if(state_c == IDATA2)begin
            dout <= data2;
        end
        else if(state_c == RESULT)begin
            case (operation)
                    2'd0 : dout <= data1 + data2;
                    2'd1 : dout <= data1 - data2;
                    2'd2 : if(mult_vld) dout <= mult_in;
                default : dout <= dout;
            endcase
        end
        else if(state_c == IDLE)begin
            dout <= 27'd0;
        end
    end

    always@(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            mult_en <= 1'b0;
        end
        else begin
            mult_en <= (idata22result_start && (operation == 2'd2));
        end
    end

endmodule