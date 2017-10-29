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
module mkVJmain(Empty);
	

endmodule

endpackage