module seg_disp #( 
    parameter       TCLK                    =   20      , //系统时钟周期，单位ns。
    parameter       TIME_20US               =   20_000  , //数码管刷新时间，默认20us。
    parameter       SEG_NUM                 =   6        //需要显示的数码管个数。
)(
    //输入信号定义
    input                                       clk     , //系统时钟，50MHz。
    input                                       rst_n   , //系统复位，低电平有效。
    input           [(SEG_NUM * 4) - 1  :0]     din     , //需要数码管显示的BCD码数码；
    input           [SEG_NUM - 1 : 0]           dp      , //小数点控制信号，1表示点亮小数点。

    //输出信号定义
    output reg      [7 : 0]                     segment , //数码管的数据线；
    output reg      [SEG_NUM - 1 : 0]           seg_sel , //数码管的位选信号；
    output reg                                  dout_vld //为高电平时，表示段选和位选信号有效；
);
    //参数定义
    localparam      TIME                    =   TIME_20US/TCLK  ;
    localparam      TIME_W                  =   clogb2(TIME-1)  ; //计算数码管扫描时间的时钟数据位宽；
    localparam      SEG_W                   =   clogb2(SEG_NUM) ;
    localparam      DOT                     =   8'h80           ; //小数点对应的段码。
    localparam      ZERO                    =   8'h3F  ; //共阴极段码；
    localparam      ONE                     =   8'h06  ;
    localparam      TWO                     =   8'h5B  ;
    localparam      THREE                   =   8'h4F  ;
    localparam      FOUR                    =   8'h66  ;
    localparam      FIVE                    =   8'h6D  ;
    localparam      SIX                     =   8'h7D  ;
    localparam      SEVEN                   =   8'h07  ;
    localparam      EIGHT                   =   8'h7F  ;
    localparam      NINE                    =   8'h6F  ;
    localparam      ERR                     =   8'h77  ;

    //中间信号定义
    reg             [3 : 0]                     sel_result  ;
    reg             [SEG_W - 1 : 0]             sel         ;
    reg             [SEG_W - 1 : 0]             sel_ff0     ;
    reg             [TIME_W - 1 : 0]            cnt_20us    ;
    reg                                         add_sel_r   ;//

    wire                                        end_cnt_20us;
    wire                                        add_sel     ;
    wire                                        end_sel     ;

    //自动计算位宽的函数；
    function integer clogb2(input integer depth);
        begin
            if(depth == 0)
                clogb2 = 1;
            else if(depth != 0)
                for(clogb2 = 0; depth > 0; clogb2 = clogb2 + 1)
                    depth = depth >> 1;
        end
    endfunction

    //计数器部分保持不变，略...

    //sel_result信号是当前被点亮数码管需要显示的数据；
    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            sel_result <= 4'd0;
        end
        else if(add_sel)begin
            sel_result <= din[4*sel+3 -: 4];
        end
    end

    //译码器部分修改，增加小数点控制；
    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            segment <= ZERO;
        end
        else if(add_sel_r)begin
            case(sel_result)
                0: segment <= ZERO ;
                1: segment <= ONE  ;
                2: segment <= TWO  ;
                3: segment <= THREE;
                4: segment <= FOUR ;
                5: segment <= FIVE ;
                6: segment <= SIX  ;
                7: segment <= SEVEN;
                8: segment <= EIGHT;
                9: segment <= NINE ;
                default: segment <= ERR;
            endcase

            //根据 dp 控制信号，设置小数点；
            if(dp[sel]) begin
                segment <= segment | DOT; //打开小数点。
            end
        end
    end

    //为了与段选动态扫描，保持同步，此时位选应该打一拍再赋给位选信号 seg_sel
    always@(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            sel_ff0 <= 0;
        end
        else if(add_sel)begin
            sel_ff0 <= sel;
        end
    end

    always@(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin//初始值为0，全部数码管被点亮；
            seg_sel <= {{SEG_NUM}{1'b0}};
        end
        else if(add_sel_r)begin//将1右移sel_ff0位之后取反，seg_sel的第sel_ff0输出低电平，对应的第sel_ff0个数码管被点亮了，其余位输出高电平，对应的数码管熄灭；
            seg_sel <= ~({1'b1,{{SEG_NUM-1}{1'b0}}} >> sel_ff0);//~(6'h1<<sel_ff0);
        end
    end

    //移位寄存器，将数据更新的指示信号暂存；
    //dout_vld与segment、seg_sel对齐。
    always@(posedge clk)begin
        add_sel_r <= add_sel;
        dout_vld <= add_sel_r;
    end

endmodule