package bram_test;

import FIFO::*;
import BRAM::*;


function BRAMRequest#(Bit#(8), Bit#(8)) makeRequest(Bool write, Bit#(8) addr, Bit#(8) data);
	return BRAMRequest{
		write: write,
		responseOnWrite:False,
		address: addr,
		datain: data
		};
endfunction


(*synthesize*)
module mkBramTest(Empty);
	
	Reg#(Bool) init <- mkReg(False);
	Reg#(Int#(8)) clk <- mkReg(0);
	Reg#(Int#(8)) cnt <- mkReg(0);

	BRAM_Configure cfg = defaultValue;
	cfg.memorySize = 100;
	//cfg.loadFormat = tagged Hex "inp1.txt";

/*	BRAM2Port#(Bit#(8), Bit#(8)) dut <- mkBRAM2Server(cfg);

	rule update_clk;
		clk <= clk + 1;
		cnt <= cnt + 2;
		$display("%d %d\n", clk, cnt);
	endrule

	rule put_values(cnt <= 78);
		Bit#(8) a = pack(cnt);
		Bit#(8) b = pack(cnt+1);
		dut.portA.request.put(makeRequest(False, a, 0));
		dut.portB.request.put(makeRequest(False, b, 0));
	endrule

	rule get_values( cnt>1 && cnt<=79 );
		$display("%x", dut.portA.response.get);
		$display("%x", dut.portB.response.get);
	endrule
*/

	BRAM2Port#(Bit#(8), Bit#(8)) dut <- mkBRAM2Server(cfg);

	rule update_clk;
		clk <= clk + 1;
		cnt <= cnt + 1;
	endrule

	rule put_values(cnt<=78);
		Bit#(8) a = pack(cnt);

		dut.portA.request.put(makeRequest(True, a, a));
	endrule

	rule get_values( cnt>1 && cnt<=80 );
		Bit#(8) a = pack(cnt-2);

		dut.portB.request.put(makeRequest(False, a, 0));
	endrule

	rule get_data(cnt>2 && cnt<=81);
		$display("%x", dut.portB.response.get);
	endrule

	rule done(cnt>81);
		$finish(0);
	endrule


endmodule

endpackage