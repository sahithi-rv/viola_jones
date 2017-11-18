package TrialFixedPoint;


typedef Int#(32) Data_32;


(* synthesize *)
module mkTrialFixedPoint( Empty );
	
	Reg#(Data_32) result_reg <- mkReg(0);
	Reg#(Data_32) stddev <- mkReg(0);
	Reg#(Data_32) reg_sq <- mkReg(0);
	Reg#(Data_32) reg_sqrt <- mkReg(0);
	Reg#(Data_32) reg_ans <- mkReg(0);
	Reg#(Data_32) reg_i <- mkReg(0);
	Reg#(Data_32) curr_state <- mkReg(5200);



	rule init_sqrt(curr_state == 5200);

		if( reg_sq == 0 )
		begin
			
			stddev <= 0;
			curr_state <= 4;
		end
		else
		begin
			if( reg_sq == 1 )
			begin
				stddev <= 1;
				curr_state <= 4;
			end
			else
			begin
				result_reg <= 1;
				reg_ans <= 0;
				reg_i <= 1;
				curr_state <= 5201;
			end
		end
	endrule

	rule while_sqrt( curr_state == 5201);
		let a = reg_i;
		reg_ans <= a;
		reg_i <= a + 1;
		result_reg <=  (a+1)*(a+1);
		curr_state <= 5202;

	endrule

	rule check_sqrt( curr_state == 5202 );
		if( result_reg < reg_sq )
		begin
			curr_state <= 5201;
		end
		else 
			if( result_reg == reg_sq)
			begin
				stddev <= reg_i;
				curr_state <= 4;
			end
			else
			begin
				stddev <= reg_ans;
				curr_state <= 4;
			end

	endrule

	rule done(curr_state == 4);
		$display("ddst %d ", stddev );
		$finish(0);
	endrule

endmodule

endpackage

/*

	rule one(x==0);
		 y <= pack(p);
		x <= 1;
	endrule

	rule two(x==1);
		
		Datat num = unpack(a);
		Datat q = 6;



		Datat quot = fdiv( num, q );

		fxptWrite(10,num);$write(" quot is "); fxptWrite(10,quot); $display("");

		Datat l = 9456.3456;
		Datat k = 78563.23;
		Pixels j = pack(l);
		Pixels h = pack(k);

		Pixels g = j+h;
		Datat f = unpack(g);
		fxptWrite(10,f);

		Datat d = l + k;
		fxptWrite(10,d);

		Pixels m = -94;
		DatatRead red = unpack(m);
		DatatTrunc trunc = fxptTruncate(red);
		Datat fin = fxptSignExtend(trunc);
		Pixels lol = pack(fin);
		Datat ku = unpack(lol);
		fxptWrite(6,fin);$display("");
		fxptWrite(6,ku);$display("");

		Datat kyun = unpack(m);
		fxptWrite(6,kyun);$display("");

		x<=2;
	endrule

	Datat kernel[3][3] = {{ 1, 1 ,1},
						  { 1, 1 , 1 },
						  { 1, 1, 1}};
	
	Vector#(3, Vector#(3, Reg#(Pixels) )) buffer <- replicateM(replicateM(mkReg(0)));

	rule three(x==2);

		for(Integer i = 0;i<3;i=i+1)
		begin 
			for(Integer j = 0;j<3;j=j+1)
			begin
				buffer[i][j] <= 1;
			end
		end
		x<=3;
	endrule

	rule four(x==3);

		Pixels lul;

		Datat add = 0;
		for(Integer i = 0;i<3;i=i+1)
		begin
			for(Integer j = 0;j<3;j = j+1)
			begin
				lul = fxptReadVal(buffer[i][j]);
				Datat a = unpack( lul);
				Datat b = kernel[i][j] ;
				Datat k = fmul(a,b);
				add = fadd( add, k );
				fxptWrite(1,add); $display(" ADD");
			end
		end

		$finish();
	endrule
*/

	/*rule open(file_open);
		String readfile = "tmp_inp1.txt";
		File lfh <- $fopen(readfile, "r");
		
	endrule

	rule lkgf;
		Pixels a= 2;
		//b = 6;
		Sizet b = unpack(a);
		$display("sizet %d",b);

		DatatRead red = unpack(a);
		fxptWrite(6,red);$display(" datatread");
		DatatTrunc trunc = fxptTruncate(red);
		fxptWrite(6,trunc);$display(" datattrunc");
		Datat fin = fxptZeroExtend(trunc);
		fxptWrite(6,fin);$display(" datat ext");
		Pixels lol = pack(fin);
		Datat val = unpack(lol);
		fxptWrite(6,val);$display(" datat");

		Datat alphasq = fmul(val,val);
		fxptWrite(6,alphasq);$display(" mul");	

		//let something = TAdd#(R,1);
		b = fromInteger(valueof(Something));
		$display("%d",b);

		$finish();
	endrule

*/