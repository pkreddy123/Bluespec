
package Testbench;

import Vector::*;
import LFSR :: *;
import Division7 :: *;

Int#(32) n = 5;

(* synthesize *)
module mkTestbench (Empty);

   Reg#(int) in <- mkReg(0);	
   Reg#(int) clk <- mkReg(0);	
   Reg#(int) out <- mkReg(0);	

   Div1 sorter <- mkDivision7;

	rule cll;
	clk <= clk+1;
	$display("clk:%d\n",clk);
	endrule
	
   rule rl_feed_inputs(in < 360);
      Vector#(2,Int#(16)) x = newVector;
      Bit#(16) v1 = pack(truncate(in + 2535));
      Bit#(16) v2 = pack(truncate(in +  32));
       x[0] = unpack (v1);
      x[1] = unpack (v2);
      sorter.put (x);
      in <= in +1;
      $display ("%d: x1 = %0d x2 = %0d , Expected:%0d\n",in,x[0], x[1] , x[0] / x[1]);
   endrule

  rule out1;
		 let ans <- sorter.get();
         //       $display("**** %d **** %d \n ",ans[0],ans[1]);
  	 	out <= out + 1;
  endrule

  	rule fin (clk == 600);
	$display("%d %d\n",in,out);
	$finish;
	endrule
  
endmodule


endpackage
