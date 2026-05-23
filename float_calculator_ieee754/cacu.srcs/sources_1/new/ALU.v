`timescale 1ns / 1ps
//
//IEEE754标准
//1_数符 8_阶码 23_尾数
//其中阶码使用移码表示，尾数使用原码表示,尾数有隐藏高位
//S:00 加法  11 减法  01 乘法
//C:A+B A-B A*B
//ready 结果有效
//start 开始运算
//error 溢出标志
module ALU_float(
    input clk,
    input rst_n,
    input start,
    input [1:0] S,
    input [31:0] A,
    input [31:0] B,
    output [31:0] C,
    output reg error,
    output reg ready
    );
    parameter   idle = 3'd0,    //空闲
                S0 = 3'd1,      //对阶
                S1 = 3'd2,      //尾数求和
                S2 = 3'd3,      //规格化
                S3 = 3'd4,      //溢出判断
                S4 = 3'd5,      //阶码运算
                S5 = 3'd6,      //尾数乘除
                S6 = 3'd7;
    reg [2:0] c_state,n_state;
    reg [7:0] A_jie_R,B_jie_R;
    reg  [23:0] A_wei_R,B_wei_R;
    wire [8:0] A_jie_jian_B_jie;
    wire bit_C;

 
    reg [8:0] C_jie_R;
    reg [24:0] C_wei_R_high;
    reg [23:0] C_wei_R_low;
    reg sign;
    reg start_div;
    wire [23:0] div_0;

    always @(posedge clk , negedge rst_n) begin
        if (!rst_n) begin
            c_state <= idle;
        end else begin
            c_state <= n_state;
        end
    end
    always @(*) begin
        case (c_state)
            idle: begin
                if(start)
                    if(^S) 
                        if(A[30:0] && B[30:0]) n_state = S4;
                        else n_state = S3;
                    else n_state = S0;
                else
                    n_state = idle;
            end
            S0:begin
                n_state = S1;
            end
            S1:begin
                n_state = S2;
            end
            S2:begin
                if(S == 2'b01)
                    n_state = S6;
                else
                    n_state = S3;
            end
            S3:begin
                n_state = idle;
            end
            S4:begin
                n_state = S5;
            end
            S5:begin
                    n_state = S2;

            end
            S6:begin
                n_state = S3;
            end
        endcase
    end
 
    always @(posedge clk , negedge rst_n) begin
        if (!rst_n) begin
            A_jie_R <= 0;
            B_jie_R <= 0;
            C_jie_R <= 0;
            A_wei_R <= 0;
            B_wei_R <= 0;
            C_wei_R_high <= 0;
            C_wei_R_low <= 0;
            sign <= 0;
            error <= 0;
            ready <= 0;
            start_div <= 0;
        end else begin
            case (c_state)
                idle: begin
                    B_wei_R <= {1'b1,B[22:0]};
                    A_wei_R <= {1'b1,A[22:0]};
                    A_jie_R <= A[30:23];
                    B_jie_R <= B[30:23];
                    C_jie_R <= 0;
                    C_wei_R_high <= 0;
                    C_wei_R_low <= 0;
                    sign <= 0;
                    error <= 0;
                    ready <= 0;
                    start_div <= 0;
                end
                S0:begin
                    if (A_jie_jian_B_jie[8]) begin  
                        B_jie_R <= B_jie_R;
                        A_jie_R <= B_jie_R;
                        B_wei_R <= B_wei_R; 
                        A_wei_R <= (A_wei_R >> (~A_jie_jian_B_jie + 1'b1)) + bit_C;
                    end else begin
                        B_jie_R <= A_jie_R;
                        A_jie_R <= A_jie_R;
                        A_wei_R <= A_wei_R;
                        B_wei_R <= (B_wei_R >> A_jie_jian_B_jie) + bit_C;
                    end
                end
                S1:begin
                    if(((A[31]^B[31])&(S == 2'b00)) | (~(A[31]^B[31])&(S == 2'b11)))
                        if(A_wei_R > B_wei_R) begin
                            C_wei_R_high <= (A_wei_R - B_wei_R) >> 1 ;
                            sign <= A[31];
                        end
                        else
                        begin
                            C_wei_R_high <= (B_wei_R - A_wei_R) >> 1;
                            sign <= ~A[31];
                        end  
                    else
                    begin
                        sign <= A[31];
                        C_wei_R_high <= (A_wei_R + B_wei_R) >> 1;                       
                    end
                    C_jie_R <= {1'b0,B_jie_R} + 8'd1;
                end
                S2:begin
                    if (C_wei_R_high[23]) begin
                        {C_wei_R_high,C_wei_R_low} <= {C_wei_R_high,C_wei_R_low};
                        C_jie_R <= C_jie_R;
                    end else if(C_wei_R_high[22]) begin
                        {C_wei_R_high,C_wei_R_low} <= {C_wei_R_high,C_wei_R_low} << 1;
                        C_jie_R <= C_jie_R -9'd1;
                    end else if(C_wei_R_high[21]) begin
                        {C_wei_R_high,C_wei_R_low} <= {C_wei_R_high,C_wei_R_low} << 2;
                        C_jie_R <= C_jie_R -9'd2;
                    end else if(C_wei_R_high[20]) begin
                        {C_wei_R_high,C_wei_R_low} <= {C_wei_R_high,C_wei_R_low} << 3;
                        C_jie_R <= C_jie_R -9'd3;
                    end else if(C_wei_R_high[19]) begin
                        {C_wei_R_high,C_wei_R_low} <= {C_wei_R_high,C_wei_R_low} << 4;
                        C_jie_R <= C_jie_R -9'd4;
                    end else if(C_wei_R_high[18]) begin
                        {C_wei_R_high,C_wei_R_low} <= {C_wei_R_high,C_wei_R_low} << 5;
                        C_jie_R <= C_jie_R -9'd5;
                    end else if(C_wei_R_high[17]) begin
                        {C_wei_R_high,C_wei_R_low} <= {C_wei_R_high,C_wei_R_low} << 6;
                        C_jie_R <= C_jie_R -9'd6;
                    end else if(C_wei_R_high[16]) begin
                        {C_wei_R_high,C_wei_R_low} <= {C_wei_R_high,C_wei_R_low} << 7;
                        C_jie_R <= C_jie_R -9'd7;
                    end else if(C_wei_R_high[15]) begin
                        {C_wei_R_high,C_wei_R_low} <= {C_wei_R_high,C_wei_R_low} << 8;
                        C_jie_R <= C_jie_R -9'd8;
                    end else if(C_wei_R_high[14]) begin
                        {C_wei_R_high,C_wei_R_low} <= {C_wei_R_high,C_wei_R_low} << 9;
                        C_jie_R <= C_jie_R -9'd9;
                    end else if(C_wei_R_high[13]) begin
                        {C_wei_R_high,C_wei_R_low} <= {C_wei_R_high,C_wei_R_low} << 10;
                        C_jie_R <= C_jie_R -9'd10;
                    end else if(C_wei_R_high[12]) begin
                        {C_wei_R_high,C_wei_R_low} <= {C_wei_R_high,C_wei_R_low} << 11;
                        C_jie_R <= C_jie_R -9'd11;
                    end else if(C_wei_R_high[11]) begin
                        {C_wei_R_high,C_wei_R_low} <= {C_wei_R_high,C_wei_R_low} << 12;
                        C_jie_R <= C_jie_R -9'd12;
                    end else if(C_wei_R_high[10]) begin
                        {C_wei_R_high,C_wei_R_low} <= {C_wei_R_high,C_wei_R_low} << 13;
                        C_jie_R <= C_jie_R -9'd13;
                    end else if(C_wei_R_high[9]) begin
                        {C_wei_R_high,C_wei_R_low} <= {C_wei_R_high,C_wei_R_low} << 14;
                        C_jie_R <= C_jie_R -9'd14;
                    end else if(C_wei_R_high[8]) begin
                        {C_wei_R_high,C_wei_R_low} <= {C_wei_R_high,C_wei_R_low} << 15;
                        C_jie_R <= C_jie_R -9'd15;
                    end else if(C_wei_R_high[7]) begin
                        {C_wei_R_high,C_wei_R_low} <= {C_wei_R_high,C_wei_R_low} << 16;
                        C_jie_R <= C_jie_R -9'd16;
                    end else if(C_wei_R_high[6]) begin
                        {C_wei_R_high,C_wei_R_low} <= {C_wei_R_high,C_wei_R_low} << 17;
                        C_jie_R <= C_jie_R -9'd17;
                    end else if(C_wei_R_high[5]) begin
                        {C_wei_R_high,C_wei_R_low} <= {C_wei_R_high,C_wei_R_low} << 18;
                        C_jie_R <= C_jie_R -9'd18;
                    end else if(C_wei_R_high[4]) begin
                        {C_wei_R_high,C_wei_R_low} <= {C_wei_R_high,C_wei_R_low} << 19;
                        C_jie_R <= C_jie_R -9'd19;
                    end else if(C_wei_R_high[3]) begin
                        {C_wei_R_high,C_wei_R_low} <= {C_wei_R_high,C_wei_R_low} << 20;
                        C_jie_R <= C_jie_R -9'd20;
                    end else if(C_wei_R_high[2]) begin
                        {C_wei_R_high,C_wei_R_low} <= {C_wei_R_high,C_wei_R_low} << 21;
                        C_jie_R <= C_jie_R -9'd21;
                    end else if(C_wei_R_high[1]) begin
                        {C_wei_R_high,C_wei_R_low} <= {C_wei_R_high,C_wei_R_low} << 22;
                        C_jie_R <= C_jie_R -9'd22;
                    end else if(C_wei_R_high[0]) begin
                        {C_wei_R_high,C_wei_R_low} <= {C_wei_R_high,C_wei_R_low} << 23;
                        C_jie_R <= C_jie_R -9'd23;
                    end else 
                    if(S == 2'b01)begin
                        if (C_wei_R_low[23]) begin
                            {C_wei_R_high,C_wei_R_low} <= {C_wei_R_high,C_wei_R_low} << 24;
                            C_jie_R <= C_jie_R -9'd24;
                        end else if(C_wei_R_low[22]) begin
                            {C_wei_R_high,C_wei_R_low} <= {C_wei_R_high,C_wei_R_low} << 25;
                            C_jie_R <= C_jie_R -9'd25;
                        end else if(C_wei_R_low[21]) begin
                            {C_wei_R_high,C_wei_R_low} <= {C_wei_R_high,C_wei_R_low} << 26;
                            C_jie_R <= C_jie_R -9'd26;
                        end else if(C_wei_R_low[20]) begin
                            {C_wei_R_high,C_wei_R_low} <= {C_wei_R_high,C_wei_R_low} << 27;
                            C_jie_R <= C_jie_R -9'd27;
                        end else if(C_wei_R_low[19]) begin
                            {C_wei_R_high,C_wei_R_low} <= {C_wei_R_high,C_wei_R_low} << 28;
                            C_jie_R <= C_jie_R -9'd28;
                        end else if(C_wei_R_low[18]) begin
                            {C_wei_R_high,C_wei_R_low} <= {C_wei_R_high,C_wei_R_low} << 29;
                            C_jie_R <= C_jie_R -9'd29;
                        end else if(C_wei_R_low[17]) begin
                            {C_wei_R_high,C_wei_R_low} <= {C_wei_R_high,C_wei_R_low} << 30;
                            C_jie_R <= C_jie_R -9'd30;
                        end else if(C_wei_R_low[16]) begin
                            {C_wei_R_high,C_wei_R_low} <= {C_wei_R_high,C_wei_R_low} << 31;
                            C_jie_R <= C_jie_R -9'd31;
                        end else if(C_wei_R_low[15]) begin
                            {C_wei_R_high,C_wei_R_low} <= {C_wei_R_high,C_wei_R_low} << 32;
                            C_jie_R <= C_jie_R -9'd32;
                        end else if(C_wei_R_low[14]) begin
                            {C_wei_R_high,C_wei_R_low} <= {C_wei_R_high,C_wei_R_low} << 33;
                            C_jie_R <= C_jie_R -9'd33;
                        end else if(C_wei_R_low[13]) begin
                            {C_wei_R_high,C_wei_R_low} <= {C_wei_R_high,C_wei_R_low} << 34;
                            C_jie_R <= C_jie_R -9'd34;
                        end else if(C_wei_R_low[12]) begin
                            {C_wei_R_high,C_wei_R_low} <= {C_wei_R_high,C_wei_R_low} << 35;
                            C_jie_R <= C_jie_R -9'd35;
                        end else if(C_wei_R_low[11]) begin
                            {C_wei_R_high,C_wei_R_low} <= {C_wei_R_high,C_wei_R_low} << 36;
                            C_jie_R <= C_jie_R -9'd36;
                        end else if(C_wei_R_low[10]) begin
                            {C_wei_R_high,C_wei_R_low} <= {C_wei_R_high,C_wei_R_low} << 37;
                            C_jie_R <= C_jie_R -9'd37;
                        end else if(C_wei_R_low[9]) begin
                            {C_wei_R_high,C_wei_R_low} <= {C_wei_R_high,C_wei_R_low} << 38;
                            C_jie_R <= C_jie_R -9'd38;
                        end else if(C_wei_R_low[8]) begin
                            {C_wei_R_high,C_wei_R_low} <= {C_wei_R_high,C_wei_R_low} << 39;
                            C_jie_R <= C_jie_R -9'd39;
                        end else if(C_wei_R_low[7]) begin
                            {C_wei_R_high,C_wei_R_low} <= {C_wei_R_high,C_wei_R_low} << 40;
                            C_jie_R <= C_jie_R -9'd40;
                        end else if(C_wei_R_low[6]) begin
                            {C_wei_R_high,C_wei_R_low} <= {C_wei_R_high,C_wei_R_low} << 41;
                            C_jie_R <= C_jie_R -9'd41;
                        end else if(C_wei_R_low[5]) begin
                            {C_wei_R_high,C_wei_R_low} <= {C_wei_R_high,C_wei_R_low} << 42;
                            C_jie_R <= C_jie_R -9'd42;
                        end else if(C_wei_R_low[4]) begin
                            {C_wei_R_high,C_wei_R_low} <= {C_wei_R_high,C_wei_R_low} << 43;
                            C_jie_R <= C_jie_R -9'd43;
                        end else if(C_wei_R_low[3]) begin
                            {C_wei_R_high,C_wei_R_low} <= {C_wei_R_high,C_wei_R_low} << 44;
                            C_jie_R <= C_jie_R -9'd44;
                        end else if(C_wei_R_low[2]) begin
                            {C_wei_R_high,C_wei_R_low} <= {C_wei_R_high,C_wei_R_low} << 45;
                            C_jie_R <= C_jie_R -9'd45;
                        end else if(C_wei_R_low[1]) begin
                            {C_wei_R_high,C_wei_R_low} <= {C_wei_R_high,C_wei_R_low} << 46;
                            C_jie_R <= C_jie_R -9'd46;
                        end else if(C_wei_R_low[0]) begin
                            {C_wei_R_high,C_wei_R_low} <= {C_wei_R_high,C_wei_R_low} << 47;
                            C_jie_R <= C_jie_R -9'd47;
                        end
                    end
                    else begin
                        {C_wei_R_high,C_wei_R_low} <= {C_wei_R_high,C_wei_R_low};
                        C_jie_R <= C_jie_R;
                    end
 
                end
                S3:begin
                    ready <= 1;
                    if(^S)
                        sign <= A[31] | B[31];
                    if(C_jie_R[8:7] == 2'b10 || C_jie_R == 9'd255 ) begin
                        error <= 1'd1;
                        C_jie_R <= 9'd511;
                        C_wei_R_high <= 0;
                    end
                    else if(C_jie_R[8:7] == 2'b11) begin
                        C_wei_R_high <= 0;
                        C_jie_R <= 0;
                    end
                end
                S4:begin
                    if(S[1])
                        C_jie_R <= A_jie_jian_B_jie + 9'd127;
                    else
                        C_jie_R <= A_jie_R + B_jie_R - 9'd127;
                end
                S5:begin
                    start_div <= 1;
                    if(start_div)
                            C_wei_R_high <= C_wei_R_high;
                    else
                        if(S[1]) begin
                            if(A_wei_R > B_wei_R) begin
                                A_wei_R <= A_wei_R >> 1;
                                C_jie_R <= C_jie_R + 9'd1;
                            end
                            else begin
                                A_wei_R <= A_wei_R;
                            end                        
                        end
                        else begin
                            {C_wei_R_high,C_wei_R_low} <= A_wei_R * B_wei_R;
                            C_jie_R <= C_jie_R + 9'd1;
                        end
                        
                end
                S6:begin 
                    if(C_wei_R_low[23])
                        C_wei_R_high <= C_wei_R_high + 25'd1;
                    else
                        C_wei_R_high <= C_wei_R_high;
                end
            endcase
        end
    end
    assign A_jie_jian_B_jie = A_jie_R - B_jie_R;
    assign bit_C = A_jie_jian_B_jie ? 
                 ((A_jie_jian_B_jie <= 9'd24) || (A_jie_jian_B_jie >= 9'd488) ? 
                  (A_jie_jian_B_jie[8] ? 
                   A_wei_R[~A_jie_jian_B_jie] : B_wei_R[A_jie_jian_B_jie - 8'd1]) : 1'b0) : 1'b0;
    assign C = {sign,C_jie_R[7:0],C_wei_R_high[22:0]};//信号的拼接
endmodule
 