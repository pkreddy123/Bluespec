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
		FIFO#(Int#(16)) div2 <- mkSizedFIFO(25);
		
		FIFO#(Int#(16)) outq1 <- mkSizedFIFO(90);
		FIFO#(Int#(16)) outq2 <- mkSizedFIFO(50);
		FIFO#(Int#(16)) outq3 <- mkSizedFIFO(30);
		FIFO#(Bit#(16)) outq <- mkSizedFIFO(2);
		
		FIFO#(Vector#(2,Int#(16))) intermediate1 <- mkSizedFIFO(2);
		FIFO#(Vector#(2,Int#(16))) intermediate2 <- mkSizedFIFO(2);

		Reg#(Int#(16)) mp[4];
		Reg#(Bit#(6)) re[4];
		Reg#(Int#(16)) inter[4];
		Pulse p[4];
	
		for(Integer i=0;i<4;i = i+1) begin
			mp[i] <- mkReg(0);
			re[i] <- mkReg(0);
			p[i] <- mkPulse;
			inter[i] <- mkReg(0);
		end
		
		rule lvl1;
			let ans <- dut_1.get;
			let div = div1.first;div1.deq;
			outq1.enq(ans[0]);
		//	Int#(16) tmp = ans[1];
			inter[0] <= div;
			inter[1] <= ans[1];
			p[2].send;
		endrule
	
		rule inter1;
			 p[2].ishigh;
			let div = inter[0];
			let tmp = inter[1];
			if(div < (tmp*10)) begin
                                tmp = tmp * 10;
                        end

                        else if(div < (tmp * 100)) begin
                                tmp = tmp*100;
                        end

                        else begin
                                tmp = 0;
                        end
	
                        Vector#(2,Int#(16)) das = newVector;
                        das[0] = tmp;
                        das[1] = div;
                        intermediate1.enq(das);
	
		endrule
		
		rule lvl2;
		
			let ans = intermediate1.first;intermediate1.deq;
			dut_2.put(ans);	
			div2.enq(ans[1]);
//			$display("lvl2\n");
		endrule
		
		
		rule lvl3;
			let ans <- dut_2.get;
			let div = div2.first;div2.deq;
			outq2.enq(ans[0]);
			inter[3] <= ans[1];
			inter[2] <= div ;
//			$display("lvl3\n");
			p[3].send;
		endrule
	
		rule inter2;
			p[3].ishigh;
			let div = inter[2];
			let tmp = inter[3];
			if(div < (tmp*10)) begin
                                tmp = tmp * 10;
                        end

                        else if(div < (tmp * 100)) begin
                                tmp = tmp*100;
                        end

                        else begin
                                tmp = 0;
                        end
	
			Vector#(2,Int#(16)) das = newVector;
                        das[0] = tmp;
                        das[1] = div;
                        intermediate2.enq(das);
	
		endrule
		
		rule lvl4;
			let ans = intermediate2.first;intermediate2.deq;
				dut_3.put(ans);
			//$display("lvl4\n");
		endrule

		rule lvl5;
			let ans <- dut_3.get;
			outq3.enq(ans[0]);
		//	$display("lvl5\n");
		endrule
		
		rule lvl6;
			mp[0] <= outq1.first;outq1.deq;
			let tmp1 = outq2.first;outq2.deq;
			let tmp2 = outq3.first;outq3.deq;
				mp[1] <= tmp1*10 + tmp2;
				p[0].send;
		endrule
	
		rule con;
			p[0].ishigh;
			 Vector#(2,Int#(16)) ans =  newVector;
			ans[0] = mp[0];
			ans[1] = mp[1];
			 Bit#(6) rem = 0;
                        for(Integer i = 5;i>=3;i = i-1) begin

                                if((ans[1] << 1) >= 100) begin
                                        rem[i] = 1;
                                        ans[1] = (ans[1] << 1) - 100;
                                end
                                else begin
                                        rem[i] = 0;
                                        ans[1] = ans[1] << 1;
                                end

                        end
			re[0] <= rem;
			mp[2] <= ans[0];
			mp[3] <= ans[1];
			p[1].send;
		endrule


		rule conversion;
			p[1].ishigh;
			 Vector#(2,Int#(16)) ans =  newVector;
			ans[0] = mp[2];
			ans[1] = mp[3];
			Bit#(6) rem = re[0];
			for(Integer i = 2;i>=0;i = i-1) begin
		
				if((ans[1] << 1) >= 100) begin
					rem[i] = 1;
					ans[1] = (ans[1] << 1) - 100;
				end
				else begin
					rem[i] = 0;
					ans[1] = ans[1] << 1;
				end
		
			end
		
			Bit#(10) inP = pack(truncate(ans[0]));
			Bit#(16) finalans = {inP,rem};
			outq.enq(finalans);
	//		$display("########conversion###\n");
		endrule	
		
	        method ActionValue#(DataType) get ;
			let ans = outq.first;outq.deq;
			DataType data = unpack(ans);
			fxptWrite(2,data);
                   	$display("\n");
		        return data;
                endmethod

                method Action put(Vector#(2,Int#(16)) datas) ;
                 //  	$display("########input#########\n");
			dut_1.put(datas);
			div1.enq(datas[1]);
                endmethod
		
endmodule
endpackage
