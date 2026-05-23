module hc595_drive #(
    parameter       SEG_NUM             =   6                   ,//需要显示的数码管个数。
    parameter       SCLK_DIV            =   4                    //sclk与系统时钟的分频系数。
)(
    //输入信号定义
    input                                   clk                 ,//系统时钟，50MHz。
    input                                   rst_n               ,//系统复位，低电平有效。

    input           [5 : 0]                 segment             ,//数码管的数据线；
    input           [SEG_NUM - 1 : 0]       seg_sel             ,//数码管的位选信号；
    input                                   din_vld             ,//段选和位选有效指示信号；
    output reg                              ds                  ,//74HC595串行数据线;
    output reg                              sclk                ,//74HC595移位寄存器时钟；
    output reg                              rclk                 //74HC595锁存器时钟；
);
    //参数定义
    localparam      SCLK_DIV_W          =   clogb2(SCLK_DIV - 1);//利用函数自动计算位宽；

    //中间信号定义
    reg                                     flag                ;//
    reg             [15 : 0]                din_r               ;//
    reg             [SCLK_DIV_W - 1 : 0]    div_cnt             ;//
    reg             [4 : 0] 	            cnt                 ;//
    wire       		                        add_cnt             ;
    wire                                    end_cnt             ;
    wire       		                        add_div_cnt         ;
    wire       		                        end_div_cnt         ;

    //自动计算位宽的函数；
    function integer clogb2(input integer depth);
        begin
            if(depth==0)
                clogb2=1;
            else if(depth!=0)
                for(clogb2=0; depth>0;clogb2=clogb2+1)
                    depth=depth>>1;
        end
    endfunction
    
    //标志信号，当需要刷新时拉高，当刷新完成时拉低；
    always@(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin//初始值为0;
            flag <= 1'b0;
        end
        else if(end_cnt)begin//计数器计数结束，表示刷新完成；
            flag <= 1'b0;
        end
        else if(din_vld)begin//有数据需要刷新；
            flag <= 1'b1;
        end
    end
    
    //当输入数据有效时，将需要显示的数据暂存；
    always@(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin//初始值为0;
            din_r <= 16'd0;
        end
        else if(din_vld)begin//数据信号存在高位，先输出；
            din_r <= {segment[5:0],seg_sel[5:0]};
        end
    end

    //分频系数计数器，当flag信号为高电平时有效；
    always@(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin//
            div_cnt <= 0;
        end
        else if(add_div_cnt)begin
            if(end_div_cnt)
                div_cnt <= 0;
            else
                div_cnt <= div_cnt + 1;
        end
    end
    
    assign add_div_cnt = flag;//处于刷新状态时，计数器对系统时钟计数；
    assign end_div_cnt = add_div_cnt && div_cnt == SCLK_DIV - 1;//计数到分频系数清零；

    //计数发送数据的位数，需要发送16位数据，且需要将锁存时钟拉高，所以需要计数17；
    always@(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin//
            cnt <= 0;
        end
        else if(add_cnt)begin
            if(end_cnt)
                cnt <= 0;
            else
                cnt <= cnt + 1;
        end
    end
    
    assign add_cnt = end_div_cnt;//当分频计数器计数结束表示1位数据发送完成，此计数器加1。
    assign end_cnt = add_cnt && cnt == 17 - 1;//当发送完16位数据且锁存时钟拉高后清零，表示完成刷新；

    //产生74hc595的移位时钟信号；
    //add_div_cnt && div_cnt == 0表示sclk的下降沿；
    //add_div_cnt && div_cnt == SCLK_DIV/2-1表示sclk的上升沿；
    always@(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin//初始值为0;
            sclk <= 1'b0;
        end
        else if(add_div_cnt)begin
            if(div_cnt == 0)//当分频计数器为0且计数条件有效时拉低。
                sclk <= 1'b0;
            else if(div_cnt == (SCLK_DIV >> 1))//当分频计数器计数到一半时拉高；
                sclk <= 1'b1;
        end
    end

    //在SCLK下降沿输出数据；
    //FPGA需要在SCLK下降沿更新数据，74HC595在上升沿才能采集稳定的数据。
    always@(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin//初始值为0;
            ds <= 1'b0;
        end//当分频计数器为0，且发送的数据小于16时，输出数据；
        else if(add_div_cnt && (div_cnt == 0) && (cnt < 16))begin
            ds <= din_r[15 - cnt];//其实就是在sclk下降沿输出数据；
        end
    end

    //产生锁存时钟信号，当数据全部发送完毕后，将锁存时钟拉高一个时钟周期。
    always@(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin//初始值为0;
            rclk <= 1'b0;
        end
        else if(end_cnt)begin
            rclk <= 1'b0;
        end
        else if(add_div_cnt && (cnt == 16))begin
            rclk <= 1'b1;
        end
    end
    
endmodule