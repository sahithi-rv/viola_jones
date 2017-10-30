package bram_test;

import FIFO::*;
import BRAM::*;


function BRAMRequest#(Bit#(16), Bit#(16)) makeRequest(Bool write, Bit#(16) addr, Bit#(16) data);
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
	Reg#(Int#(16)) clk <- mkReg(0);
	Reg#(Int#(16)) cnt <- mkReg(0);

	BRAM_Configure cfg_alpha1 = defaultValue;
	cfg_alpha1.memorySize = 2913;
	cfg_alpha1.loadFormat = tagged Bin "../mem_files/alpha1_array.txt.mem";

	BRAM_Configure cfg_alpha2 = defaultValue;
	cfg_alpha2.memorySize = 2913;
	cfg_alpha2.loadFormat = tagged Bin "../mem_files/alpha2_array.txt.mem";

	BRAM_Configure cfg_rectangles0 = defaultValue;
	cfg_rectangles0.memorySize = 2913;
	cfg_rectangles0.loadFormat = tagged Bin "../mem_files/rectangles_array0.txt.mem";

	BRAM_Configure cfg_rectangles1 = defaultValue;
	cfg_rectangles1.memorySize = 2913;
	cfg_rectangles1.loadFormat = tagged Bin "../mem_files/rectangles_array1.txt.mem";

	BRAM_Configure cfg_rectangles2 = defaultValue;
	cfg_rectangles2.memorySize = 2913;
	cfg_rectangles2.loadFormat = tagged Bin "../mem_files/rectangles_array2.txt.mem";

	BRAM_Configure cfg_rectangles3 = defaultValue;
	cfg_rectangles3.memorySize = 2913;
	cfg_rectangles3.loadFormat = tagged Bin "../mem_files/rectangles_array3.txt.mem";

	BRAM_Configure cfg_rectangles4 = defaultValue;
	cfg_rectangles4.memorySize = 2913;
	cfg_rectangles4.loadFormat = tagged Bin "../mem_files/rectangles_array4.txt.mem";

	BRAM_Configure cfg_rectangles5 = defaultValue;
	cfg_rectangles5.memorySize = 2913;
	cfg_rectangles5.loadFormat = tagged Bin "../mem_files/rectangles_array5.txt.mem";

	BRAM_Configure cfg_rectangles6 = defaultValue;
	cfg_rectangles6.memorySize = 2913;
	cfg_rectangles6.loadFormat = tagged Bin "../mem_files/rectangles_array6.txt.mem";	

	BRAM_Configure cfg_rectangles7 = defaultValue;
	cfg_rectangles7.memorySize = 2913;
	cfg_rectangles7.loadFormat = tagged Bin "../mem_files/rectangles_array7.txt.mem";			

	BRAM_Configure cfg_rectangles8 = defaultValue;
	cfg_rectangles8.memorySize = 2913;
	cfg_rectangles8.loadFormat = tagged Bin "../mem_files/rectangles_array8.txt.mem";

	BRAM_Configure cfg_rectangles9 = defaultValue;
	cfg_rectangles9.memorySize = 2913;
	cfg_rectangles9.loadFormat = tagged Bin "../mem_files/rectangles_array9.txt.mem";

	BRAM_Configure cfg_rectangles10 = defaultValue;
	cfg_rectangles10.memorySize = 2913;
	cfg_rectangles10.loadFormat = tagged Bin "../mem_files/rectangles_array10.txt.mem";

	BRAM_Configure cfg_rectangles11 = defaultValue;
	cfg_rectangles11.memorySize = 2913;
	cfg_rectangles11.loadFormat = tagged Bin "../mem_files/rectangles_array11.txt.mem";
			
	Reg#(Bool) arr[8];
	for (Integer i=0; i<8; i=i+1)
	   arr[i] <- mkRegU;
	...
	// You can refer to the registers with []-syntax
	rule r(arr[0] == 0);
	   arr[1] = 1;
	endrule

/*
	BRAM_Configure cfg_stages_array = defaultValue;
	cfg_stages.memorySize = 2913;
	cfg_rectangles11.loadFormat = tagged Bin "../mem_files/rectangles_array11.txt.mem";*/

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
/*
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
*/

endmodule

endpackage