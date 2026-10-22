`timescale 1ns/1ps
module tb_calculator;
    reg clk=0;
    always #5 clk=~clk;
    reg [15:0] btn=0;
    wire [5:0] digit;
    wire [7:0] segment;
    cal dut(.clk_in(clk),.btn(btn),.sw1(1'b1),.sw2(1'b1),.DIG(digit),.seg(segment));
    reg [31:0] frequency=1000;
    wire divided;
    FreDiv divider(.clk(clk),.frequency(frequency),.clk_out(divided));
    reg [18:0] tone_count=8;
    wire tone;
    Buzzercontrol sound(.clk(clk),.buzzer_count(tone_count),.buzzer(tone));
    integer a,b,cases=0;
    task press;
        input integer key;
        begin
            @(negedge clk);#1;btn=16'b1<<key;
            @(negedge clk);#1;btn=0;
            @(negedge clk);#1;
        end
    endtask
    task number;
        input integer n;
        begin
            if(n>=10)press(n/10);
            press(n%10);
        end
    endtask
    task calculate;
        input integer left,operation,right;
        begin
            press(15);number(left);press(operation);number(right);press(14);
        end
    endtask
    initial begin
        #1;
        if(divided!==0 || tone!==0 || dut.result!==0 || dut.res!==0)
            $fatal(1,"Startup contains unknown state");
        // Divider endpoint: 25000 input cycles per half-period for the existing
        // 50 MHz assumption. Place the real counter just before the boundary.
        @(negedge clk);#1;divider.count=24998;
        @(posedge clk);#1;if(divided!==0)$fatal(1,"Divider toggled early");
        @(posedge clk);#1;if(divided!==1)$fatal(1,"Divider endpoint incorrect");
        frequency=0;
        @(posedge clk);#1;if(divided!==0)$fatal(1,"Zero frequency not disabled");
        tone_count=0;
        @(posedge clk);#1;if(tone!==0 || sound.count!==0)$fatal(1,"Tone restart not deterministic");
        for(a=0;a<100;a=a+1)begin
            for(b=1;b<100;b=b+1)begin
                calculate(a,13,b);
                if(dut.result!==a/b || dut.res!==a%b)
                    $fatal(1,"Division %0d/%0d got %0d r%0d",a,b,dut.result,dut.res);
                cases=cases+1;
            end
        end
        calculate(98,13,99);
        repeat(12)@(negedge clk);#1;
        if(dut.h_bit!==9 || dut.l_bit!==8)$fatal(1,"98/99 fractional digits wrong");
        calculate(8,13,0);
        if(dut.result!==0 || dut.res!==0)$fatal(1,"Division by zero produced unknown data");
        calculate(8,10,2);press(12);number(3);press(14);
        if(dut.result!==30 || dut.op!==12)$fatal(1,"Mixed chained operator was lost");
        calculate(2,11,8);
        if(dut.result!==6 || dut.minus!==1)$fatal(1,"Negative subtraction wrong");
        press(15);
        if(dut.result!==0 || dut.res!==0)$fatal(1,"Clear retained arithmetic state");
        $display("PASS: %0d exhaustive two-digit divisions, decimal/zero/chaining/startup checks",cases);
        $finish;
    end
    initial begin #100000000;$fatal(1,"Simulation timeout");end
endmodule
