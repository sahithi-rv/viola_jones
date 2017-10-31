package vj_fsm;
import BRAM::*;
import constants::*;
import Vector :: * ;
import StmtFSM :: *;


function BRAMRequest#(Bit#(16), Bit#(16)) makeRequest(Bool write, Bit#(16) addr, Bit#(16) data);
	return BRAMRequest{
		write: write,
		responseOnWrite:False,
		address: addr,
		datain: data
		};
endfunction

function BRAMRequest#(Bit#(20), Bit#(16)) makeRequest20(Bool write, Bit#(20) addr, Bit#(16) data);
	return BRAMRequest{
		write: write,
		responseOnWrite:False,
		address: addr,
		datain: data
		};
endfunction

Sizet_20 r = fromInteger(valueof(IMGR));
Sizet_20 c = fromInteger(valueof(IMGC));
Sizet_20 sz = fromInteger(valueof(WSZ));
Sizet init_time = fromInteger(valueof(INIT_TIME));
Sizet wt = fromInteger(valueof(WT));
Sizet n_stages=fromInteger(valueof(STAGES));

Integer hf = valueof(HF);
(*synthesize*)
module mkVJfsm(Empty);
	Reg#(Int#(16)) clk <- mkReg(0);

	Reg#(Sizet_20) row <- mkReg(0);
	Reg#(Sizet_20) col <- mkReg(0);
	Reg#(Bool) wbuffer_enable <- mkReg(False);
	Reg#(Bool) lbuffer_enable <- mkReg(False);
	Reg#(Bool) ii_enable <- mkReg(False);

	Reg#(Bool) cascade_enable <- mkReg(False);

	Reg#(Bool) init <- mkReg(True);


	Reg#(Bool) buffer_enable <- mkReg(True);
	Reg#(Bool) sd_enable <- mkReg(False);
	Reg#(Bool) readData_enable <- mkReg(False);
	Reg#(Bool) classifier_enable <- mkReg(True);
	Reg#(Bool) updateCl_enable <- mkReg(False);
	Reg#(Bool) upd_stage_enable <- mkReg(False);

	Reg#(Pixels) stage_sum <- mkReg(0);
	Reg#(Int#(16)) classifier_sum <- mkReg(0);
	Reg#(Int#(16)) r_index <- mkReg(0);
	Reg#(Int#(16)) cur_stage <- mkReg(0);
	Reg#(Pixels) n_wc <- mkReg(0);
	Reg#(Pixels) wc_counter <- mkReg(0);

	BRAM_Configure cfg_ii = defaultValue;
	cfg_ii.memorySize = valueof(IMGR)*valueof(IMGC);
	cfg_ii.loadFormat = tagged Binary "../mem_files/oldfaces_320_240.mem";

	BRAM2Port#(BitSz_20, Pixels) ii <- mkBRAM2Server(cfg_ii);
	BRAM_Configure cfg_lbuffer = defaultValue;
	cfg_lbuffer.memorySize = valueof(IMGC);

	Vector#(WSZ,  BRAM2Port#(BitSz_20, Pixels) ) lbuffer <- replicateM(mkBRAM2Server(cfg_lbuffer)) ; // size = 20*240
	Vector#(WSZ, Vector#(WSZ, Reg#(Pixels) )) wbuffer <- replicateM(replicateM(mkReg(0))); // size = 20*20
	Vector#(WSZ,  Reg#(Pixels)) tempRegs <- replicateM(mkReg(0));
	Vector#( STAGES, Reg#(Pixels)) stages_array <- replicateM(mkReg(0));
	Vector#( STAGES, Reg#(Pixels)) stage_thresh  <- replicateM(mkReg(0));
	
	Vector#( 12, Reg#(Pixels)) reg_rectangle  <- replicateM(mkReg(0));
	Vector#( 3, Reg#(Pixels)) reg_weights  <- replicateM(mkReg(0));
	Vector#( 2, Reg#(Pixels)) reg_alpha  <- replicateM(mkReg(0));
	Reg#(Pixels) tree_thresh <- mkReg(0);

	Reg#(Sizet) iter1 <- mkReg(0);
	Reg#(Sizet) iter2 <- mkReg(0);
	Reg#(Sizet) iter3 <- mkReg(0);
	Reg#(Sizet) iter4 <- mkReg(0);
	Reg#(Sizet) iter5 <- mkReg(0);
	Reg#(Sizet) curr_state <- mkReg(0);

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
	endrule

	rule state_S0 ((curr_state == 0)&&(buffer_enable));
    	curr_state <= 1;
   		ii_enable<=True;
   	endrule
     
   	rule state_S1 (curr_state == 1);
    	curr_state <= 2;
      	lbuffer_enable<=True;
   	endrule
    
   	rule state_S2 (curr_state == 2); 
      	curr_state <= 3;
		wbuffer_enable<=True;
   	endrule

   	rule state_S3 (curr_state == 3 && (clk>init_time ) );
   		curr_state <= 4;
   		buffer_enable <= False;
   		ii_enable <= False;
   		lbuffer_enable <= False;
   		wbuffer_enable <= False;
   		cascade_enable <= True;
   	endrule

   	rule state_S4 (curr_state == 4 && (cascade_enable && wc_counter < n_wc) );
   		curr_state <= 5;
   		sd_enable <= True;
   	endrule

   	rule state_S5 (curr_state == 5 );
   		curr_state <= 6;
   		readData_enable <= True;
   	endrule

   	rule state_S6 (curr_state == 6);
   		curr_state <= 7;
   		classifier_enable <= True;
   	endrule

   	rule state_S7 (curr_state == 7 );
   		curr_state <= 8;
   		updateCl_enable <= True;
   	endrule

   	rule state_S8 (curr_state == 8);

   		if( wc_counter == (n_wc-1) )
		begin
			curr_state <= 9;
			cascade_enable <= False;
			sd_enable <= False;
			readData_enable <= False;
			classifier_enable <= False;
			updateCl_enable <= False;
		end
		else
		begin 
			curr_state <= 4;
			wc_counter<=wc_counter+1;
		end
   	endrule

	rule state_S9 (curr_state == 9);
		//upd_stage_enable <=True;
		//cascade_enable<=False;

		if(stage_sum>stage_thresh[cur_stage]) //continue
		begin

			if( cur_stage == (n_stages-1) )
			begin
				cascade_enable <=False;
				buffer_enable <=True;
				wc_counter<=0;
				n_wc<=stages_array[0];
				stage_sum<=0;
				cur_stage<=0;
				$display("window at: %d %d",row,col);
				curr_state <= 0;
			end
			else
			begin
				cur_stage<=cur_stage+1;
				n_wc<=stages_array[cur_stage+1];
				wc_counter<=0;
				stage_sum<=0;
				curr_state <= 4;
				cascade_enable <= True;
			end
		end
		else
		begin 
			cascade_enable <=False;
			buffer_enable <= True;
			wc_counter<=0;
			stage_sum<=0;
			cur_stage<=0;
			n_wc<=stages_array[0];
			curr_state <= 0;
		end
	endrule

	rule request_ii(ii_enable && (buffer_enable)); // read values of column in line buffers
	//	$display("ii %d", clk);
		if( col == (c-1) )
		begin
			col <= 0;
			row <= row +1;
		end
		else
		begin 
			col <= col + 1;
		end

		BitSz_20 a = pack(c*row + col);
		let b = unpack(a);
		//$display("pos %d", b);
		ii.portA.request.put(makeRequest20(False,a, 0 ));
		for(Sizet_20 i = 1; i < (sz); i = i+1) // wrt to lbuffer
		begin 
			BitSz_20 cl = pack(col); 
			lbuffer[i].portA.request.put(makeRequest20(False, cl, 0));
		end
	endrule

	rule update_lbuffer(lbuffer_enable && (buffer_enable));
	//	$display("lbuffer %d", clk);
		let tmp = (col-1+c)%c;
		BitSz_20 cl = pack(tmp);
		for(Sizet_20 i = 0; i < (sz-1); i = i+1) // wrt to lbuffer
		begin 
			let t1 <- lbuffer[i+1].portA.response.get;
			lbuffer[i].portB.request.put(makeRequest20(True, cl, t1));
			tempRegs[i] <= t1;
		end
		let a <- ii.portA.response.get;
		lbuffer[sz-1].portB.request.put(makeRequest20(True, cl, a));
		tempRegs[sz-1] <= a;
		let b = unpack(a);		
	endrule

	rule shift_wbuffer (wbuffer_enable && (buffer_enable));
	//	$display("wbuffer %d", clk);
		for(Sizet_20 i = 0; i < (sz); i = i+1) // wrt to wbuffer
		begin 
			for(Sizet_20 j = 0; j<(sz-1);j = j+1)
			begin
				wbuffer[i][j] <= wbuffer[i][j+1];
			end
		end

		for(Sizet_20 i = 0;i<sz;i = i+1)
		begin
		
			wbuffer[i][sz-1] <= tempRegs[i];
		end
	endrule

	rule loadclassifiers (sd_enable && (cascade_enable) );
		let a=pack(r_index);
		weights_array0.portA.request.put(makeRequest(False, a, 0));
		weights_array1.portA.request.put(makeRequest(False, a, 0));
		weights_array2.portA.request.put(makeRequest(False, a, 0));
		rectangles0.portA.request.put(makeRequest(False, a, 0));
		rectangles1.portA.request.put(makeRequest(False, a, 0));
		rectangles2.portA.request.put(makeRequest(False, a, 0));
		rectangles3.portA.request.put(makeRequest(False, a, 0));
		rectangles4.portA.request.put(makeRequest(False, a, 0));
		rectangles5.portA.request.put(makeRequest(False, a, 0));
		rectangles6.portA.request.put(makeRequest(False, a, 0));
		rectangles7.portA.request.put(makeRequest(False, a, 0));
		rectangles8.portA.request.put(makeRequest(False, a, 0));
		rectangles9.portA.request.put(makeRequest(False, a, 0));
		rectangles10.portA.request.put(makeRequest(False, a, 0));
		rectangles11.portA.request.put(makeRequest(False, a, 0));
		alpha1.portA.request.put(makeRequest(False, a, 0));
		alpha2.portA.request.put(makeRequest(False, a, 0));
		tree_thresh_array.portA.request.put(makeRequest(False, a, 0));
	endrule
	   
	rule getclassifiers( readData_enable && (cascade_enable) );
		
		let a1<- weights_array0.portA.response.get;
		reg_weights[0]<=a1;
		let a2<- weights_array1.portA.response.get;
		reg_weights[1]<=a2;
		let a3<- weights_array2.portA.response.get;
		reg_weights[2]<=a3;		
		let a4<-rectangles0.portA.response.get;
		reg_rectangle[0]<=a4;
		let a5<-rectangles1.portA.response.get;
		reg_rectangle[1]<=a5;
		let a6<-rectangles2.portA.response.get;
		reg_rectangle[2]<=a6;
		let a7<-rectangles3.portA.response.get;
		reg_rectangle[3]<=a7;
		let a8<-rectangles4.portA.response.get;
		reg_rectangle[4]<=a8;
		let a9<-rectangles5.portA.response.get;
		reg_rectangle[5]<=a9;
		let a10<-rectangles6.portA.response.get;
		reg_rectangle[6]<=a10;
		let a11<-rectangles7.portA.response.get;
		reg_rectangle[7]<=a11;
		let a12<-rectangles8.portA.response.get;
		reg_rectangle[8]<=a12;
		let a13<-rectangles9.portA.response.get;
		reg_rectangle[9]<=a13;
		let a14<-rectangles10.portA.response.get;
		reg_rectangle[10]<=a14;																		
		let a15<-rectangles11.portA.response.get;
		reg_rectangle[11]<=a15;	
		let a16<- alpha1.portA.response.get;
		reg_alpha[0] <=a16;
		let a17<- alpha2.portA.response.get;
		reg_alpha[1] <=a17;
		let a18 <- tree_thresh_array.portA.response.get;
		tree_thresh <=a18;
	endrule	

	rule wc_compute( classifier_enable && (cascade_enable) );
		 let x1=reg_rectangle[0];
		 let y1=reg_rectangle[1];
		 let w1=reg_rectangle[2];
		 let h1=reg_rectangle[3];
		 let rect1=wbuffer[y1][x1]-wbuffer[y1+h1][x1]-wbuffer[y1][x1+w1]+wbuffer[y1+h1][x1+w1];
		 let x2=reg_rectangle[4];
		 let y2=reg_rectangle[5];
		 let w2=reg_rectangle[6];
		 let h2=reg_rectangle[7];
		 let rect2=wbuffer[y2][x2]-wbuffer[y2+h2][x2]-wbuffer[y2][x2+w2]+wbuffer[y2+h2][x2+w2];	  
		 let x3=reg_rectangle[8];
		 let y3=reg_rectangle[9];
		 let w3=reg_rectangle[10];
		 let h3=reg_rectangle[11];
		 let rect3=wbuffer[y3][x3]-wbuffer[y3+h3][x3]-wbuffer[y3][x3+w3]+wbuffer[y3+h3][x3+w3];
		 let classifier_sum=rect1*reg_weights[0]+rect2*reg_weights[1]+rect3*reg_weights[2];
		if(classifier_sum>=tree_thresh)
			begin
				stage_sum<=stage_sum+reg_alpha[1];
			end
		else
			begin
				stage_sum<=stage_sum+reg_alpha[0];
			end
	endrule

	rule update_classifier(updateCl_enable && (cascade_enable) );
		r_index<=r_index+1;
	endrule

/*	rule print;
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
*/
	rule done(row == r );
		$finish(0);
	endrule



endmodule

endpackage