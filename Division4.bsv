package Division4;
import Vector::*;
import FIFO::*;
import FIFOF::*;


interface Div ;
        method Action put(Vector#(2,Int#(16)) datas);
        method ActionValue#(Vector#(2,Int#(16))) get;
endinterface


(*synthesize*)
module mkDivision4(Div);

		Integer n = 16;
		FIFOF#(Vector#(2,Int#(16))) inq <- mkFIFOF;
		FIFOF#(Vector#(2,Int#(16))) outq <- mkFIFOF;
                Reg#(int) clk <- mkReg(0);
                Reg#(Int#(32)) rem[n+2];
                Reg#(Int#(32)) div[n+2];
                Reg#(Bit#(16)) q[n+2];
                Reg#(int)      stage[n+2];
		Reg#(Int#(32)) divisor <- mkReg(0);
		
		for(Integer i =0;i<n+2;i = i+1) begin
			rem[i]   <- mkReg(0);
			div[i]   <- mkReg(0);
			q[i]     <- mkReg(0);
			stage[i] <- mkReg(0);
		end

		rule cl;
		clk <= clk+1;
		endrule
		
		rule stage_0;
			let in    = inq.first;inq.deq;
			stage[0] <= 1 ;
			rem[0]   <= extend(in[0]);
			div[0]   <= (extend(in[1]) << 16);
			divisor  <= (extend(in[1]) << 16);
		endrule
		
		rule noinput ( !inq.notEmpty);
			stage[0] <= 0;
		endrule
		for(Integer i = 0; i < 16 ; i=i+1) begin
         
		       rule stage1;
			Int#(32) tmp = rem[i] - div[i];
			if(tmp >= 0)  	begin
				rem[i+1] <= tmp;
				q[i+1]   <= ((q[i] << 1) | 1);
			end
			
			else begin
				q[i+1] <= (q[i] << 1);
				rem[i+1] <= rem[i];
			end
			
			div[i+1] <= (div[i] >> 1);
			stage[i+1] <= stage[i];
                	
		endrule
		
		end

		
		
		rule fin_stage (stage[16] == 1);
                       Vector#(2,Int#(16)) das = newVector;
			Bit#(16) qou = 0 ; Int#(32) remainder = 0;
			 if((rem[16] - div[16]) >= 0)      begin   
                                qou         =  ((q[16] << 1) | 1);
                                remainder   =  rem[16] - div[16];
                         end

                         else begin
                                qou        = (q[16] << 1);
                                remainder  =  rem[16];
                         end
				das[0] = unpack(qou);
				das[1] = truncate(remainder);
				
			outq.enq(das);
                        stage[17] <= 1;
			
		endrule
	
		
                method ActionValue#(Vector#(2,Int#(16))) get;
                      let das = outq.first;outq.deq;
                        return das;
                endmethod

                method Action put(Vector#(2,Int#(16)) datas) ;
			inq.enq(datas);
                endmethod

endmodule
endpackage
