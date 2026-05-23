module div50 (clkin,clr,clkout);  //50hz
 input	clkin,clr;
 output    reg   clkout=0;
 //用reg后面always中需要改变数值。
 integer    qout=0;
 //用行为描述实现
 always@(posedge clkin)
 begin    
    if(clr)    
    begin   
           qout<=0;    clkout<=0;  
    end 
    else  if(qout=='d499999) 
    	begin
     		qout<=0;
              clkout<=~clkout;
     	end
     	else
              qout<=qout+1;
 end
 endmodule