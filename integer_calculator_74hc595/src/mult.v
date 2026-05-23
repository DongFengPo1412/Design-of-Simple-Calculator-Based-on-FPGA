module mult #(
    parameter			MULT_D		        =		8		        ,//被乘数位宽；
    parameter			MULT_R		        =		4		         //乘数位宽；
)(
    input									        clk		        ,//系统时钟信号；
    input									        rst_n	        ,//系统复位信号，低电平有效；

    input                                           start           ,//开始运算信号，高电平有效；
    input               [MULT_D - 1 : 0]            multiplicand    ,//被乘数；
    input               [MULT_R - 1 : 0]            multiplier      ,//乘数；
    output  reg         [MULT_D + MULT_R - 1 : 0]   product         ,//乘积输出；
    output  reg                                     product_vld     ,//乘积有效指示信号，高电平有效；
    output  reg                                     rdy              //模块忙闲指示信号，高电平表示空闲；
);
    reg                                             flag            ;
    reg                 [MULT_D - 1 : 0]            multiplier_r    ;//乘数的寄存器
    reg                 [MULT_D + MULT_R - 1 : 0]   multiplicand_r  ;//被乘数的寄存器。
    reg                 [MULT_D + MULT_R - 1 : 0]   product_r       ;//乘积寄存器；

    wire                                            start_f         ;

    //开始计算信号有效且乘数和被乘数均不等于0；
    assign start_f = (~flag) && (start && (multiplicand != 0) && (multiplier != 0));

    //运算标志信号，
    always@(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin//初始值为0;
            flag <= 1'b0;
        end
        else if(start_f)begin//开始运算时拉高
            flag <= 1'b1;
        end
        else if(multiplier_r == 1)begin//运算结束时拉低；
            flag <= 1'b0;
        end
    end

    always@(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin//初始值为0;
            multiplicand_r <= {{MULT_D + MULT_R}{1'b0}};
            multiplier_r <= {{MULT_R}{1'b0}};
        end
        else if(start_f)begin//当计算开始时；
            multiplicand_r <= multiplicand;//将被乘数加载到被乘数寄存器中。
            multiplier_r <= multiplier;//将乘数加载到乘积寄存器中。
        end
        else if(flag)begin//正常计算标志信号有效时，被乘数左移一位，乘数右移一位。
            multiplicand_r <= multiplicand_r << 1;
            multiplier_r <= multiplier_r >> 1;
        end
    end

    //计算乘法运算结果，开始信号有效时，将乘积清零。
    //当乘数寄存器最低位为1时，加上此时被乘数的值。
    always@(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin//初始值为0;
            product_r <= {{MULT_D + MULT_R}{1'b0}};
        end
        else if(start)//当乘数或者被乘数为0时，乘积输出0.
            product_r <= {{MULT_D + MULT_R}{1'b0}};
        else if(flag && multiplier_r[0])begin//如果乘积的最低位为1，则把乘积的高位数据与被乘数相加。
            product_r <= product_r + multiplicand_r;
        end
    end

    //输出乘积和乘积有效指示信号；
    always@(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin//初始值为0;
            product <= {{MULT_D + MULT_R}{1'b0}};
            product_vld <= 1'b0;
        end
        else if((~flag) && (start && ((multiplicand == 0) || (multiplier == 0))))begin
            product <= {{MULT_D + MULT_R}{1'b0}};//如果开始计算时，乘数或者被乘数为0，则直接输出0；
            product_vld <= 1'b1;
        end
        else if(flag && (multiplier_r == 1))begin//计算完成时，把计算结果输出，且乘积有效指示信号拉高；
            product <= product_r + multiplicand_r;
            product_vld <= 1'b1;
        end
        else begin//其余时间把有效指示信号拉低；
            product_vld <= 1'b0;
        end
    end

    //生成模块忙闲指示信号；
    always@(*)begin//当开始信号有效或者标志信号有效时，模块处于工作状态；
        if(start || flag)
            rdy = 1'b0;
        else//否则模块处于空闲状态；
            rdy = 1'b1;
    end

endmodule