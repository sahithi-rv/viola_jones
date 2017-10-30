package vj_main;
import BRAM::*;
import constants::*;
import Vector :: * ;

function BRAMRequest#(Bit#(16), Bit#(16)) makeRequest(Bool write, Bit#(16) addr, Bit#(16) data);
	return BRAMRequest{
		write: write,
		responseOnWrite:False,
		address: addr,
		datain: data
		};
endfunction

Sizet r = fromInteger(valueof(IMGR));
Sizet c = fromInteger(valueof(IMGC));
Sizet sz = fromInteger(valueof(WSZ));
Sizet init_time = fromInteger(valueof(INIT_TIME));
Sizet wt = fromInteger(valueof(WT));
(*synthesize*)
module mkVJmain(Empty);
	Reg#(Int#(16)) clk <- mkReg(0);
	Reg#(Int#(16)) wait_time <- mkReg(0);
	Reg#(Int#(16)) dont_wait <- mkReg(0);

	Reg#(Int#(16)) row <- mkReg(0);
	Reg#(Int#(16)) col <- mkReg(0);

	BRAM_Configure cfg_ii = defaultValue;
	cfg_ii.memorySize = 5*5;
	cfg_ii.loadFormat = tagged Binary "../mem_files/temp.mem";

	BRAM2Port#(BitSz, Pixels) ii <- mkBRAM2Server(cfg_ii);
	BRAM_Configure cfg_lbuffer = defaultValue;
	cfg_lbuffer.memorySize = 5;

	Vector#(WSZ,  BRAM2Port#(BitSz, Pixels) ) lbuffer <- replicateM(mkBRAM2Server(cfg_lbuffer)) ; // size = 20*240
	Vector#(WSZ, Vector#(WSZ, Reg#(Pixels) )) wbuffer <- replicateM(replicateM(mkReg(0))); // size = 20*20

	Vector#(WSZ,  Reg#(Pixels)) tempRegs <- replicateM(mkReg(0));


	rule update_clk;
		clk <= clk + 1;

		if( clk<init_time )
		begin 
			dont_wait <= 1;
		end
		else
		begin
			dont_wait <= 0;
			if( wait_time == (wt-1) )
			begin
				wait_time <= 0;
			end
			else
			begin
				wait_time <= wait_time + 1;
			end
		end

	endrule

	rule shift_lbuffer(wait_time == 0 || (dont_wait == 1) ); // read values of column in line buffers
		if( col == (c-1) )
		begin
			col <= 0;
			row <= row +1;
		end
		else
		begin 
			col <= col + 1;
		end

		BitSz a = pack(c*row + col);
		let b = unpack(a);
		$display("pos %d", b);
		ii.portA.request.put(makeRequest(False,a, 0 ));
		for(Sizet i = 1; i < (sz); i = i+1) // wrt to lbuffer
		begin 
			BitSz cl = pack(col); 
			lbuffer[i].portA.request.put(makeRequest(False, cl, 0));
		end
	endrule

	rule update_lbuffer( (wait_time == 1) || (dont_wait == 1) );	// shifted values are written to all rows;
		let tmp = (col-1+c)%c;
		BitSz cl = pack(tmp);
		for(Sizet i = 0; i < (sz-1); i = i+1) // wrt to lbuffer
		begin 
			
			let t1 <- lbuffer[i+1].portA.response.get;

			lbuffer[i].portB.request.put(makeRequest(True, cl, t1));
			tempRegs[i] <= t1;
			let lol  = unpack(t1);
	//		$display("lol %d",lol);
		end
		let a <- ii.portA.response.get;
		lbuffer[sz-1].portB.request.put(makeRequest(True, cl, a));
		tempRegs[sz-1] <= a;
		let b = unpack(a);
	//	$display("lol %d",b);

		for(int i  =0;i<3;i = i+1)
		begin
			let x = tempRegs[i];
			let y = unpack(x);
		//	$write("%d ", y);
		end

	//	$display("");
		
		
	endrule

	rule shift_wbuffer ((wait_time == 1) || (dont_wait == 1));
		for(Sizet i = 0; i < (sz); i = i+1) // wrt to wbuffer
		begin 
			for(Sizet j = 0; j<(sz-1);j = j+1)
			begin
				wbuffer[i][j] <= wbuffer[i][j+1];
			end
		end

		for(Sizet i = 0;i<sz;i = i+1)
		begin
		
			wbuffer[i][sz-1] <= tempRegs[i];
		end
	endrule


	rule print;
		for(Sizet i = 0;i<3;i = i+1)
		begin
			for(Sizet j = 0;j<3;j = j+1)
			begin
				Bit#(16) a = wbuffer[i][j];
				let b = unpack(a);
				$write("%d ", b);
			end
			$display("");
		end

		$display("\n");
	endrule

	rule done(clk>52);
		$finish(0);
	endrule

endmodule

endpackage