module hex2bcd #(
    parameter   IN_DATA_W       =           27              ,//输入数据位宽；
    parameter   OUT_DATA_W      =           clogb2({{IN_DATA_W}{1'b1}})//自动计算输出数据对应的十进制位数；
)(
    input                                   clk             ,//系统时钟；
    input                                   rst_n           ,//系统复位，低电平有效；

    input       [IN_DATA_W-1:0]             din             ,//输入二进制数据；
    input                                   din_vld         ,//输入数据有效指示信号，高电平有效；

    output reg  [4*OUT_DATA_W-1:0]          dout            ,//输出8421BCD码；
    output reg                              dout_vld         //输出数据有效指示信号，高电平有效；
    );

    localparam  CNT_W           =           clogb(IN_DATA_W-3);//根据输入数据的位宽自动计算需要移动的轮数；
	//localparam  OUT_DATA_W      =           clogb2({{IN_DATA_W}{1'b1}});//自动计算输出数据对应的十进制位数；

	reg         [IN_DATA_W-1:0]             din_ff0     ;
    reg                                     flag        ;
    reg         [CNT_W-1:0]                 cnt         ;
    reg         [IN_DATA_W+OUT_DATA_W*4-1:0]data_shift  ;
    reg                                     end_cnt_ff0 ;

    wire        [OUT_DATA_W*4-1:0]          data_compare;
    wire                                    add_cnt     ;
    wire                                    end_cnt     ;

	function integer clogb2(input integer depth);
        begin
            if(depth==0)
                clogb2 = 1;
            else if(depth!=0)
                for(clogb2=0;depth>0;clogb2=clogb2+1)
                    depth=depth/10;
        end
    endfunction

     //自动计算位宽
    function integer clogb(input integer depth);begin
        if(depth==0)
            clogb = 1;
        else if(depth!=0)
            for(clogb=0;depth>0;clogb=clogb+1)
                depth=depth>>1;
    end
    endfunction
    
    //当输入数据有效并且此时该模块空闲时保存输入数据，否则不保存输入数据，这样可以保证本次转换数据完全正确；
    always@(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            din_ff0 <= 0;
        end
        else if(din_vld)begin
            din_ff0 <= din;
        end
    end

    //标志信号flag，当输入数据有效时拉高，当计数器计数完成时清零；
    always@(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            flag <= 1'b0;
        end
        else if(din_vld)begin
            flag <= 1'b1;
        end
        else if(end_cnt)begin
            flag <= 1'b0;
        end
    end

    //移位计数器，每次转换需要移动IN_DATA_W-2次，初始值为0，加一条件flag信号有效，结束条件是计数到IN_DATA_W-2次；
    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            cnt <= 0;
        end
        else if(add_cnt)begin
            if(end_cnt)
                cnt <= 0;
            else
                cnt <= cnt + 1;
        end
    end

    assign add_cnt = flag;       
    assign end_cnt = add_cnt && cnt == IN_DATA_W-3;

    always@(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            data_shift <= 0;
        end
        else if(add_cnt)begin
            if(cnt==0)begin//初始时将输入数据左移三位保存；
                data_shift <= {{{OUT_DATA_W-3}{1'b0}},din_ff0,3'b0};
            end
            else begin//计数器加一条件有效时，将移位寄存器数据左移一位；
                data_shift <= {data_compare[OUT_DATA_W*4-2:0],data_shift[IN_DATA_W-1:0],1'b0};
            end
        end
    end

    //移位后大于等于5之后加3；
    generate
        genvar bit_num;
				for(bit_num = 0 ; bit_num < OUT_DATA_W ; bit_num = bit_num + 1)begin : DATA
                    assign data_compare[4*bit_num+3 : 4*bit_num] = data_shift[IN_DATA_W+4*bit_num+3 : IN_DATA_W+4*bit_num] + (data_shift[IN_DATA_W+4*bit_num+3 : IN_DATA_W+4*bit_num]>=5 ? 4'd3 : 4'd0);
        end
    endgenerate

    //将计数器延迟一拍，用于生成输出信号；
    always@(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            end_cnt_ff0 <= 1'b0;
        end
        else begin
            end_cnt_ff0 <= end_cnt;
        end
    end

    //通过计数器结束条件产生输出信号；
    always@(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            dout <= 0;
        end
        else if(end_cnt_ff0)begin
            dout <= data_shift[IN_DATA_W+OUT_DATA_W*4-1 : IN_DATA_W];
        end
    end

    //通过计数器结束条件生成输出有效指示信号；
    always@(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            dout_vld <= 1'b0;
        end
        else begin
            dout_vld <= end_cnt_ff0;
        end
    end

    endmodule