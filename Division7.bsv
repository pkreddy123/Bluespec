package Division7;

import Vector::*;
import FIFO::*;
import FIFOF::*;
import Division4::*;
import FixedPoint::*;
import datatypes::*;
import pulse::*;

interface Div1 ;
        method Action put(Vector#(2,Int#(16)) datas);
        method ActionValue#(DataType) get;
endinterface


(*synthesize*)
module mkDivision7(Div1);
	
		Div dut_1 <- mkDivision4;
		Div dut_2 <- mkDivision4;
		Div dut_3 <- mkDivision4;
		
		FIFO#(Int#(16)) div1 <- mkSizedFIFO(25);
		
		FIFO#(Int#(16)) outq1 <- mkSizedFIFO(90);
		FIFO#(Bit#(16)) outq <- mkSizedFIFO(2);
		
		
		Reg#(Int#(16)) fin_q  <- mkReg(0);
		Reg#(Bit#(6)) fin_rem <- mkReg(0); 
		Reg#(Int#(16)) divi_1 <- mkReg(0);
		
		Pulse p[3];
		Reg#(Int#(16)) div_1[3];
		Reg#(Int#(16)) div_2[2];
		Reg#(Int#(16)) tmp_1[2];
		Reg#(Int#(16)) tmp_2[2];
		for(Integer i=0;i<2;i = i+1) begin
			div_2[i] <- mkReg(0);
			div_1[i] <- mkReg(0);
			tmp_1[i] <- mkReg(0);
			tmp_2[i] <- mkReg(0);
			p[i] <- mkPulse;
		end	
		div_1[2] <- mkReg(0);
		Reg#(Int#(16)) d_20 <- mkReg(0);
		Reg#(Int#(16)) t_20 <- mkReg(0);
		p[2] <- mkPulse;
		
		Reg#(Int#(16)) r[6];
		Reg#(Bit#(6))  re[6];
		Pulse pul[6];
		Pulse pac <- mkPulse;
		Pulse padd <- mkPulse;
		for(Integer i=0;i<6;i = i+1) begin
			r[i]   <- mkReg(0);
			re[i]  <- mkReg(0);
			pul[i] <- mkPulse;
		end
	
		rule lvl1;
			let ans <- dut_1.get;
			let div = div1.first;div1.deq;
			outq1.enq(ans[0]);
			div_1[0] <= div;
			d_20 <= div;
			tmp_1[0] <= ans[1];
			t_20 <= ans[1];
			p[0].send;
		endrule
		
		rule intr1;
			p[0].ishigh;
			let div = div_1[0];
			let tmp = tmp_1[0] << 1;
			 tmp = (tmp << 2) + tmp;
			div_1[1] <= div;
			tmp_1[1] <= tmp;
			p[1].send;
		endrule
		
		rule intere1;
			p[1].ishigh;
			let tmp = tmp_1[1] + tmp_2[1] ;
			if(div_1[1] < tmp) begin
				divi_1 <= tmp;
			end
			else begin
				divi_1 <= 0;
			end
			div_1[2] <= div_1[1]; 
			p[2].send;
		endrule
	
		rule inter1;
			 p[2].ishigh;
			let div = div_1[2];
			let tmp = divi_1;
	
                        Vector#(2,Int#(16)) ans = newVector;
                        ans[0] = tmp;
                        ans[1] = div;
			dut_2.put(ans);	
		endrule
		
		
		rule lvl3;
			let ans <- dut_2.get;
			r[5] <= ans[0];
			pul[5].send;
			re[5] <= 0;
		endrule
	
		for(Integer i=5;i>=1;i = i-1) begin
			rule conv;
				pul[i].ishigh;
				let ans =  r[i] << 1;
				let rem = re[i];
				if(ans >= 10) begin
					rem[i] = 1;
					ans = ans - 10;
				end
				else begin
					rem[i] = 0;
				end
				r[i-1] <= ans;
				re[i-1] <= rem;
				pul[i-1].send;
			endrule
		end	

	
		rule fin;
			pul[0].ishigh;
			fin_q <= outq1.first;outq1.deq;
			let ans = (r[0] << 1);
			let rem = re[0];
			if(ans >= 10) begin
				rem[0] = 1;
				ans = ans - 10;
			end
			else begin
				rem[0] = 0;
			end
			fin_rem <= rem;
			pac.send;
		endrule
	
		rule packing;
			pac.ishigh;
			let rem = fin_rem;
			let ans = fin_q;
			Bit#(10) inP = pack(truncate(ans));
                        Bit#(16) finalans = {inP,rem};
                        outq.enq(finalans);
		endrule

	        method ActionValue#(DataType) get ;
			let ans = outq.first;outq.deq;
			DataType data = unpack(ans);
			fxptWrite(2,data);
                   	$display("\n");
		        return data;
                endmethod

                method Action put(Vector#(2,Int#(16)) datas) ;
			dut_1.put(datas);
			div1.enq(datas[1]);
                endmethod
		
endmodule
endpackage
