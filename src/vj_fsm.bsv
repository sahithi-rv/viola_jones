package vj_fsm;
import BRAM::*;
import constants::*;
import Vector :: * ;
import StmtFSM :: *;


function BRAMRequest#(BitSz, Pixels) makeRequest(Bool write, Bit#(16) addr, Pixels data);
	return BRAMRequest{
		write: write,
		responseOnWrite:False,
		address: addr,
		datain: data
		};
endfunction

function BRAMRequest#(BitSz_20, Pixels) makeRequest20(Bool write, Bit#(20) addr, Pixels data);
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
Data_32 init_time = fromInteger(valueof(INIT_TIME));
Sizet wt = fromInteger(valueof(WT));
Data_32 n_stages=fromInteger(valueof(STAGES));

Integer hf = valueof(HF);
(*synthesize*)
module mkVJfsm(Empty);
	Reg#(Data_32) clk <- mkReg(0);

	Reg#(Sizet_20) row <- mkReg(0);
	Reg#(Sizet_20) col <- mkReg(0);
	Reg#(Bool) wbuffer_enable <- mkReg(False);
	Reg#(Bool) lbuffer_enable <- mkReg(False);
	Reg#(Bool) ii_enable <- mkReg(False);
	Reg#(Bool) enable_print <- mkReg(False);

	Reg#(Bool) cascade_enable <- mkReg(False);

	Reg#(Bool) init <- mkReg(True);


	Reg#(Bool) updateCl_enable <- mkReg(False);
	Reg#(Bool) getclassifier_enable <- mkReg(False);
	Reg#(Bool) classifier_enable <- mkReg(False);
	Reg#(Bool) compute_enable <- mkReg(False);
	Reg#(Bool) upd_stage_enable <- mkReg(False);

	Reg#(Data_32) stage_sum <- mkReg(0);
	Reg#(Data_32) classifier_sum <- mkReg(0);
	Reg#(BitSz) r_index <- mkReg(0);
	Reg#(Data_32) cur_stage <- mkReg(0);
	Reg#(Data_32) n_wc <- mkReg(9);
	Reg#(Data_32) wc_counter <- mkReg(0);

	BRAM_Configure cfg_ii = defaultValue;
	cfg_ii.memorySize = valueof(IMGR)*valueof(IMGC);
	cfg_ii.loadFormat = tagged Binary "../mem_files/img_scaled3_ii.mem";

	BRAM2Port#(BitSz_20, Pixels) ii <- mkBRAM2Server(cfg_ii);
	BRAM_Configure cfg_lbuffer = defaultValue;
	cfg_lbuffer.memorySize = valueof(IMGC);

	Vector#(WSZ,  BRAM2Port#(BitSz_20, Pixels) ) lbuffer <- replicateM(mkBRAM2Server(cfg_lbuffer)) ; // size = 20*240
	Vector#(WSZ, Vector#(WSZ, Reg#(Pixels) )) wbuffer <- replicateM(replicateM(mkReg(0))); // size = 20*20
	Vector#(WSZ,  Reg#(Pixels)) tempRegs <- replicateM(mkReg(0));
	Vector#( TAdd#(STAGES,1), Reg#(Data_32)) stages_array <- replicateM(mkReg(0));
	Vector#( STAGES, Reg#(Data_32)) stage_thresh  <- replicateM(mkReg(0));
	
	Vector#( 12, Reg#(Pixels)) reg_rectangle  <- replicateM(mkReg(0));
	Vector#( 3, Reg#(Pixels)) reg_weights  <- replicateM(mkReg(0));
	Vector#( 2, Reg#(Pixels)) reg_alpha  <- replicateM(mkReg(0));
	Reg#(Data_32) tree_thresh <- mkReg(0);

	Reg#(Sizet) iter1 <- mkReg(0);
	Reg#(Sizet) iter2 <- mkReg(0);
	Reg#(Sizet) iter3 <- mkReg(0);
	Reg#(Sizet) iter4 <- mkReg(0);
	Reg#(Sizet) iter5 <- mkReg(0);
	Reg#(Sizet) curr_state <- mkReg(0);

		// initialize registers

	rule init_regs(init);
	//	n_wc <= 9;
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

		stage_thresh[0] <= -516;
		stage_thresh[1] <= -510;
		stage_thresh[2] <= -477;
		stage_thresh[3] <= -456;
		stage_thresh[4] <= -449;
		stage_thresh[5] <= -423;
		stage_thresh[6] <= -412;
		stage_thresh[7] <= -398;
		stage_thresh[8] <= -394;
		stage_thresh[9] <= -374;
		stage_thresh[10] <=-396;
		stage_thresh[11] <=-381;
		stage_thresh[12] <=-365;
		stage_thresh[13] <=-379;
		stage_thresh[14] <=-351;
		stage_thresh[15] <=-360;
		stage_thresh[16] <=-368;
		stage_thresh[17] <=-348;
		stage_thresh[18] <=-332;
		stage_thresh[19] <=-329;
		stage_thresh[20] <=-336;
		stage_thresh[21] <=-340;
		stage_thresh[22] <=-334;
		stage_thresh[23] <=-345;
		stage_thresh[24] <= -307;
		

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

	rule state_S0 (curr_state == 0 && !(init));
	//	// $display("s0 %d", clk);
    	curr_state <= 1;
   		ii_enable<=True;
   		lbuffer_enable<=False;
   		wbuffer_enable<=False;
  		compute_enable<=False;
   		updateCl_enable<=False;
   		upd_stage_enable<=False;			
   		classifier_enable<=False;
   		getclassifier_enable<=False;		
   	endrule
     
   	rule state_S1 (curr_state == 1);
    	curr_state <= 2;
    //	// $display("s1 %d", clk);

   		ii_enable<=False;
   		lbuffer_enable<=True;
   		wbuffer_enable<=False;
  		compute_enable<=False;
   		updateCl_enable<=False;
   		upd_stage_enable<=False;			
   		classifier_enable<=False;
   		getclassifier_enable<=False;	
   	endrule
    
   	rule state_S2 (curr_state == 2); 
    //  	// $display("s2 %d", clk);

      	curr_state <= 3;
   		ii_enable<=False;
   		lbuffer_enable<=False;
   		wbuffer_enable<=True;
  		compute_enable<=False;
   		updateCl_enable<=False;
   		upd_stage_enable<=False;			
   		classifier_enable<=False;
   		getclassifier_enable<=False;	
   	endrule

   	rule state_S3 (curr_state == 3  );
   	//	// $display("s3 %d", clk);
   		ii_enable<=False;
   		lbuffer_enable<=False;
   		wbuffer_enable<=False;
   		compute_enable<=False;
   		updateCl_enable<=False;
   		upd_stage_enable<=False;			
   		classifier_enable<=False;
   		getclassifier_enable<=False;	
   		if(clk>=init_time)
   		begin
   			curr_state <= 4;
   		end
   		else
   		begin
   			curr_state<=0;
   		end
   	endrule

   	rule state_S4 (curr_state==4);
   		//enable_print<=True;
   	//	// $display("s4 %d", clk);
		ii_enable<=False;
   		lbuffer_enable<=False;
   		wbuffer_enable<=False;
   		compute_enable<=False;
   		updateCl_enable<=False;
   		upd_stage_enable<=False;			
   		classifier_enable<=True;
   		getclassifier_enable<=False;	
   		curr_state<=5;
   	endrule

   	rule state_S5 (curr_state==5);
   	//  	// $display("s5 %d", clk);
   		classifier_enable<=False;
   		getclassifier_enable<=True;
		ii_enable<=False;
   		lbuffer_enable<=False;
   		wbuffer_enable<=False;
   		compute_enable<=False;
   		updateCl_enable<=False;
   		upd_stage_enable<=False;			

   		curr_state<=6;	
   	endrule

   	rule state_S6(curr_state==6);
   	//	// $display("s6 %d", clk);
   		classifier_enable<=False;
   		getclassifier_enable<=False;
		ii_enable<=False;
   		lbuffer_enable<=False;
   		wbuffer_enable<=False;
   		compute_enable<=True;
   		updateCl_enable<=False;
   		upd_stage_enable<=False;			
   		curr_state<=100;	
   	endrule

   	rule state_Sk (curr_state == 100);
   		classifier_enable<=False;
   		getclassifier_enable<=False;
		ii_enable<=False;
   		lbuffer_enable<=False;
   		wbuffer_enable<=False;
   		compute_enable<=False;
   		updateCl_enable<=False;
   		upd_stage_enable<=False;
   		curr_state <= 7;
   	endrule

   	rule state_S7(curr_state==7);
   		// $display("s7 %d %d %d", clk, wc_counter, n_wc);
   					
		if( wc_counter == (n_wc-1) )
		begin
			wc_counter<=0;
   			curr_state<=101;
   			// $display("call update stage");
   		end
   		else begin
   			wc_counter<=wc_counter+1;
   			// $display("new HF");
   			curr_state<=4;
   		end	

   		r_index<=r_index+1;
   	endrule

  /* 	rule state_S8(curr_state==8);
   		// $display("s7 %d", clk);
   		classifier_enable<=False;
   		getclassifier_enable<=False;
		ii_enable<=False;
   		lbuffer_enable<=False;
   		wbuffer_enable<=False;
   		compute_enable<=False;
   		updateCl_enable<=True;
   		upd_stage_enable<=False;			
   		curr_state<=100;

   	endrule*/

 	rule state_Sk1 (curr_state == 101);
 	  	classifier_enable<=False;
   		getclassifier_enable<=False;
		ii_enable<=False;
   		lbuffer_enable<=False;
   		wbuffer_enable<=False;
   		compute_enable<=False;
   		updateCl_enable<=False;
   		upd_stage_enable<=False;
   		curr_state <= 10;
   	endrule

   	rule state_S10(curr_state==10);
		// $display("update stage %d", clk);
 			
   		// $display("s10 %d %d %d", clk, cur_stage, n_stages);
   		if(stage_sum>stage_thresh[cur_stage]) //continue
		begin
			if( cur_stage == (n_stages-1) )
			begin 
				curr_state<=0;

				n_wc<=stages_array[0];
				stage_sum<=0;
				cur_stage<=0;
				 $display("window at: %d %d",row,col);

				 $display("face detected, get new window");
			end
			else
			begin
				curr_state<=4;

				cur_stage<=cur_stage+1;
				n_wc<=stages_array[cur_stage+1];
				wc_counter<=0;
				stage_sum<=0;

				//$display("stage %d done, next stage", cur_stage);
			end
		end
		else
		begin
			curr_state<=0;

			wc_counter<=0;
			//$display(" stop and read new window");
			stage_sum<=0;
			cur_stage<=0;
			n_wc<=stages_array[0];

			//$display("no face detected, get new window");
		end

			
		
   	endrule

/*
   	rule state_S9(curr_state==9);
   		// $display("s9 %d", clk);
		classifier_enable<=False;
   		getclassifier_enable<=False;
		ii_enable<=False;
   		lbuffer_enable<=False;
   		wbuffer_enable<=False;
   		compute_enable<=False;
   		updateCl_enable<=False;  
   		upd_stage_enable<=True;	
   		curr_state<=101;
   	endrule
*/	
	rule request_ii(ii_enable); // read values of column in line buffers
		//$display("ii %d %d %d ", clk,row, col);
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
		//// $display("pos %d", b);
		ii.portA.request.put(makeRequest20(False,a, 0 ));
		for(Sizet_20 i = 1; i < (sz); i = i+1) // wrt to lbuffer
		begin 
			BitSz_20 cl = pack(col); 
			lbuffer[i].portA.request.put(makeRequest20(False, cl, 0));
		end
	endrule

	rule update_lbuffer(lbuffer_enable );
		//// $display("lbuffer %d", clk);
		let tmp = (col-1+c)%c;
		// $display("lbuffer clk %d %d",clk, tmp);

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

	rule shift_wbuffer (wbuffer_enable);
		// $display("wbuffer clk %d", clk);
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


	rule loadclassifiers (classifier_enable);
		let a=pack(r_index);
		// $display("loadclassifiers %d", clk);
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
	

	rule getclassifiers (getclassifier_enable);
		// $display("getclassifiers clk %d", clk);
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
		tree_thresh <=unpack(a18);
	endrule	

rule wc_compute(compute_enable  && !(curr_state == 10) );
		 let x1=unpack(reg_rectangle[0]);
		 // $display("wc_compute clk %d", clk);
		 let y1=unpack(reg_rectangle[1]);
		 let w1=unpack(reg_rectangle[2]);
		 let h1=unpack(reg_rectangle[3]);
		 let rect1=unpack(wbuffer[y1][x1])-unpack(wbuffer[y1+h1][x1])-unpack(wbuffer[y1][x1+w1])+unpack(wbuffer[y1+h1][x1+w1]);
		 let x2=unpack(reg_rectangle[4]);
		 let y2=unpack(reg_rectangle[5]);
		 let w2=unpack(reg_rectangle[6]);
		 let h2=unpack(reg_rectangle[7]);
		 let rect2=unpack(wbuffer[y2][x2])-unpack(wbuffer[y2+h2][x2])-unpack(wbuffer[y2][x2+w2])+unpack(wbuffer[y2+h2][x2+w2]);	  
		 let x3=unpack(reg_rectangle[8]);
		 let y3=unpack(reg_rectangle[9]);
		 let w3=unpack(reg_rectangle[10]);
		 let h3=unpack(reg_rectangle[11]);
		 let rect3=unpack(wbuffer[y3][x3])-unpack(wbuffer[y3+h3][x3])-unpack(wbuffer[y3][x3+w3])+unpack(wbuffer[y3+h3][x3+w3]);
		 let classifier_sum=rect1*unpack(reg_weights[0])+rect2*unpack(reg_weights[1])+rect3*unpack(reg_weights[2]);
		if(classifier_sum>=tree_thresh)
			begin
				stage_sum<=stage_sum+unpack(reg_alpha[1]);
			end
		else
			begin
				stage_sum<=stage_sum+unpack(reg_alpha[0]);
			end
	endrule


/*	rule update_classifier(updateCl_enable && !(curr_state == 8 || upd_stage_enable));
		// $display("update_classifier clk %d", clk);
		r_index<=r_index+1;

		if( wc_counter == (n_wc-1) )
		begin
			wc_counter<=0;
		end
		else
		begin 
			wc_counter<=wc_counter+1;
		end
	endrule
*/


/*	rule update_stage (upd_stage_enable && !(compute_enable || updateCl_enable) && !(curr_state == 8 || curr_state == 10) ); //continue
		// $display("update stage %d", clk);
		if(stage_sum>stage_thresh[cur_stage]) //continue
		begin
			if( cur_stage == (n_stages-1) )
			begin
				
			//	wc_counter<=0;
				n_wc<=stages_array[0];
				stage_sum<=0;
				cur_stage<=0;
				// $display("window at: %d %d",row,col);
			//	$finish(0);
			end
			else
			begin
				// $display(" go to next level ");
				cur_stage<=cur_stage+1;
				n_wc<=stages_array[cur_stage+1];
				wc_counter<=0;
				stage_sum<=0;
				
			end
		end
		else
		begin //stop and read new window
			wc_counter<=0;
			// $display(" stop and read new window");
			stage_sum<=0;
			cur_stage<=0;
			n_wc<=stages_array[0];
		//	$finish(0);
		end
	endrule*/

/*	rule print(classifier_enable);
		// $display("%d", clk);
		for(Sizet i = 0;i<24;i = i+1)
		begin
			for(Sizet j = 0;j<24;j = j+1)
			begin
				Bit#(32) a = wbuffer[i][j];
				let b = unpack(a);
				$write("%d ", b);
			end
			// $display("");
		end

		// $display("\n");
	endrule
*/
	rule done(row == r);
		$finish(0);
	endrule



endmodule

endpackage