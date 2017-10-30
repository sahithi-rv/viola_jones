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
Integer hf = valueof(HF);
(*synthesize*)
module mkVJmain(Empty);
	Reg#(Int#(16)) clk <- mkReg(0);
	Reg#(Int#(16)) wait_time <- mkReg(0);
	Reg#(Int#(16)) dont_wait <- mkReg(0);

	Reg#(Int#(16)) row <- mkReg(0);
	Reg#(Int#(16)) col <- mkReg(0);

	Reg#(Bool) init <- mkReg(True);

	BRAM_Configure cfg_ii = defaultValue;
	cfg_ii.memorySize = 5*5;
	cfg_ii.loadFormat = tagged Binary "../mem_files/temp.mem";

	BRAM2Port#(BitSz, Pixels) ii <- mkBRAM2Server(cfg_ii);
	BRAM_Configure cfg_lbuffer = defaultValue;
	cfg_lbuffer.memorySize = 5;

	Vector#(WSZ,  BRAM2Port#(BitSz, Pixels) ) lbuffer <- replicateM(mkBRAM2Server(cfg_lbuffer)) ; // size = 20*240
	Vector#(WSZ, Vector#(WSZ, Reg#(Pixels) )) wbuffer <- replicateM(replicateM(mkReg(0))); // size = 20*20
	Vector#(WSZ,  Reg#(Pixels)) tempRegs <- replicateM(mkReg(0));
	Vector#( STAGES, Reg#(Pixels)) stages_array <- replicateM(mkReg(0));
	Vector#( STAGES, Reg#(Pixels)) stage_thresh  <- replicateM(mkReg(0));

	// initialize registers

	rule init_regs(init);
		stages_array[0] <= 9;
		stages_array[1] <= 16;
		stages_array[2] <= 27;
		stages_array[3] <= 32;
		stages_array[4] <= 52;
		stages_array[5] <= 53;
		stages_array[6] <= 62;
		stages_array[7] <= 72;
		stages_array[8] <= 83;
		stages_array[9] <= 91;
		stages_array[10] <= 99;
		stages_array[11] <= 115;
		stages_array[12] <= 127;
		stages_array[13] <= 135;
		stages_array[14] <= 136;
		stages_array[15] <= 137;
		stages_array[16] <= 159;
		stages_array[17] <= 155;
		stages_array[18] <= 169;
		stages_array[19] <= 196;
		stages_array[20] <= 197;
		stages_array[21] <= 181;
		stages_array[22] <= 199;
		stages_array[23] <= 211;
		stages_array[24] <= 200;

		stage_thresh[0] <= -1290;
		stage_thresh[1] <= -1275;
		stage_thresh[2] <= -1191;
		stage_thresh[3] <= -1140;
		stage_thresh[4] <= -1122;
		stage_thresh[5] <= -1057;
		stage_thresh[6] <= -1029;
		stage_thresh[7] <= -994;
		stage_thresh[8] <= -983;
		stage_thresh[9] <= -933;
		stage_thresh[10] <=-990;
		stage_thresh[11] <=-951;
		stage_thresh[12] <=-912;
		stage_thresh[13] <=-947;
		stage_thresh[14] <=-877;
		stage_thresh[15] <=-899;
		stage_thresh[16] <=-920;
		stage_thresh[17] <=-868;
		stage_thresh[18] <=-829;
		stage_thresh[19] <=-821;
		stage_thresh[20] <=-839;
		stage_thresh[21] <=-849;
		stage_thresh[22] <=-833;
		stage_thresh[23] <=-862;
		stage_thresh[24] <=-766;
		

		init <= False;
	endrule

	BRAM_Configure cfg_weights_array0 = defaultValue;
	cfg_weights_array0.memorySize = hf;
	cfg_weights_array0.loadFormat = tagged Binary "../mem_files/weights_array0.txt.mem";
	BRAM2Port#(BitSz, Pixels) weights_array0 <- mkBRAM2Server(cfg_weights_array0);

	BRAM_Configure cfg_weights_array1 = defaultValue;
	cfg_weights_array1.memorySize = hf;
	cfg_weights_array1.loadFormat = tagged Binary "../mem_files/weights_array1.txt.mem";
	BRAM2Port#(BitSz, Pixels) weights_array1 <- mkBRAM2Server(cfg_weights_array1);

	BRAM_Configure cfg_weights_array2 = defaultValue;
	cfg_weights_array2.memorySize = hf;
	cfg_weights_array2.loadFormat = tagged Binary "../mem_files/weights_array2.txt.mem";
	BRAM2Port#(BitSz, Pixels) weights_array2 <- mkBRAM2Server(cfg_weights_array2);

	BRAM_Configure cfg_tree_thresh_array = defaultValue;
	cfg_tree_thresh_array.memorySize = hf;
	cfg_tree_thresh_array.loadFormat = tagged Binary "../mem_files/tree_thresh_array.txt.mem";
	BRAM2Port#(BitSz, Pixels) tree_thresh_array <- mkBRAM2Server(cfg_tree_thresh_array);

	BRAM_Configure cfg_alpha1 = defaultValue;
	cfg_alpha1.memorySize = hf;
	cfg_alpha1.loadFormat = tagged Binary "../mem_files/alpha1_array.txt.mem";
	BRAM2Port#(BitSz, Pixels) alpha1 <- mkBRAM2Server(cfg_alpha1);

	BRAM_Configure cfg_alpha2 = defaultValue;
	cfg_alpha2.memorySize = hf;
	cfg_alpha2.loadFormat = tagged Binary "../mem_files/alpha2_array.txt.mem";
	BRAM2Port#(BitSz, Pixels) alpha2 <- mkBRAM2Server(cfg_alpha2);

	BRAM_Configure cfg_rectangles0 = defaultValue;
	cfg_rectangles0.memorySize = hf;
	cfg_rectangles0.loadFormat = tagged Binary "../mem_files/rectangles_array0.txt.mem";
	BRAM2Port#(BitSz, Pixels) rectangles0 <- mkBRAM2Server(cfg_rectangles0);

	BRAM_Configure cfg_rectangles1 = defaultValue;
	cfg_rectangles1.memorySize = hf;
	cfg_rectangles1.loadFormat = tagged Binary "../mem_files/rectangles_array1.txt.mem";
	BRAM2Port#(BitSz, Pixels) rectangles1 <- mkBRAM2Server(cfg_rectangles1);

	BRAM_Configure cfg_rectangles2 = defaultValue;
	cfg_rectangles2.memorySize = hf;
	cfg_rectangles2.loadFormat = tagged Binary "../mem_files/rectangles_array2.txt.mem";
	BRAM2Port#(BitSz, Pixels) rectangles2 <- mkBRAM2Server(cfg_rectangles2);

	BRAM_Configure cfg_rectangles3 = defaultValue;
	cfg_rectangles3.memorySize = hf;
	cfg_rectangles3.loadFormat = tagged Binary "../mem_files/rectangles_array3.txt.mem";
	BRAM2Port#(BitSz, Pixels) rectangles3 <- mkBRAM2Server(cfg_rectangles3);

	BRAM_Configure cfg_rectangles4 = defaultValue;
	cfg_rectangles4.memorySize = hf;
	cfg_rectangles4.loadFormat = tagged Binary "../mem_files/rectangles_array4.txt.mem";
	BRAM2Port#(BitSz, Pixels) rectangles4 <- mkBRAM2Server(cfg_rectangles4);

	BRAM_Configure cfg_rectangles5 = defaultValue;
	cfg_rectangles5.memorySize = hf;
	cfg_rectangles5.loadFormat = tagged Binary "../mem_files/rectangles_array5.txt.mem";
	BRAM2Port#(BitSz, Pixels) rectangles5 <- mkBRAM2Server(cfg_rectangles5);

	BRAM_Configure cfg_rectangles6 = defaultValue;
	cfg_rectangles6.memorySize = hf;
	cfg_rectangles6.loadFormat = tagged Binary "../mem_files/rectangles_array6.txt.mem";	
	BRAM2Port#(BitSz, Pixels) rectangles6 <- mkBRAM2Server(cfg_rectangles6);

	BRAM_Configure cfg_rectangles7 = defaultValue;
	cfg_rectangles7.memorySize = hf;
	cfg_rectangles7.loadFormat = tagged Binary "../mem_files/rectangles_array7.txt.mem";			
	BRAM2Port#(BitSz, Pixels) rectangles7 <- mkBRAM2Server(cfg_rectangles7);

	BRAM_Configure cfg_rectangles8 = defaultValue;
	cfg_rectangles8.memorySize = hf;
	cfg_rectangles8.loadFormat = tagged Binary "../mem_files/rectangles_array8.txt.mem";
	BRAM2Port#(BitSz, Pixels) rectangles8 <- mkBRAM2Server(cfg_rectangles8);

	BRAM_Configure cfg_rectangles9 = defaultValue;
	cfg_rectangles9.memorySize = hf;
	cfg_rectangles9.loadFormat = tagged Binary "../mem_files/rectangles_array9.txt.mem";
	BRAM2Port#(BitSz, Pixels) rectangles9 <- mkBRAM2Server(cfg_rectangles9);

	BRAM_Configure cfg_rectangles10 = defaultValue;
	cfg_rectangles10.memorySize = hf;
	cfg_rectangles10.loadFormat = tagged Binary "../mem_files/rectangles_array10.txt.mem";
	BRAM2Port#(BitSz, Pixels) rectangles10 <- mkBRAM2Server(cfg_rectangles10);

	BRAM_Configure cfg_rectangles11 = defaultValue;
	cfg_rectangles11.memorySize = hf;
	cfg_rectangles11.loadFormat = tagged Binary "../mem_files/rectangles_array11.txt.mem";
	BRAM2Port#(BitSz, Pixels) rectangles11 <- mkBRAM2Server(cfg_rectangles11);

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
		end
		let a <- ii.portA.response.get;
		lbuffer[sz-1].portB.request.put(makeRequest(True, cl, a));
		tempRegs[sz-1] <= a;
		let b = unpack(a);
	
		
		
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