package vj_tb;

import IFC::*;
import vj_fsm::*;
(* synthesize *)
module mkVjTb (Empty);
	Reg#(Bool) y    <- mkReg(True);
	Reg#(Bool) init    <- mkReg(True);

	VJ_ifc dut <- mkVjfsm;
	
	rule start( init);
		init <= False;
		dut.start(y);
	endrule

	rule done;
		let a = dut.result();
		let b = unpack(a);
		$display("%d", b);
		$finish(0);
	endrule

endmodule
endpackage