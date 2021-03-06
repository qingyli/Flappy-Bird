`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// VGA verilog template
// Author:  Da Cheng
//////////////////////////////////////////////////////////////////////////////////
module vga_demo(ClkPort, vga_h_sync, vga_v_sync, vga_r, vga_g, vga_b, Sw0, Sw1, btnU, btnD,btnL,btnR,btnC,
	St_ce_bar, St_rp_bar, Mt_ce_bar, Mt_St_oe_bar, Mt_St_we_bar,
	An0, An1, An2, An3, Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp,
	LD0, LD1, LD2, LD3, LD4, LD5, LD6, LD7,q_Init,q_Game,q_Die,q_Win);
	/*input ClkPort, Sw0, btnU, btnD, Sw0, Sw1;*/
	input ClkPort, Sw0, btnU, btnD, Sw0, Sw1,btnL,btnR,btnC;
	output St_ce_bar, St_rp_bar, Mt_ce_bar, Mt_St_oe_bar, Mt_St_we_bar;
	output vga_h_sync, vga_v_sync, vga_r, vga_g, vga_b;
	output An0, An1, An2, An3, Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp;
	output LD0, LD1, LD2, LD3, LD4, LD5, LD6, LD7;
	output q_Init,q_Game,q_Die,q_Win;
	reg vga_r, vga_g, vga_b;
	
	//////////////////////////////////////////////////////////////////////////////////////////
	
	/*  LOCAL SIGNALS */
	wire	reset, start, ClkPort, board_clk, clk, button_clk,ack;
	
	/*BUF BUF1 (board_clk, ClkPort); 	
	BUF BUF2 (reset, Sw0);
	BUF BUF3 (start, Sw1);*/
	
	BUF BUF1 (board_clk, ClkPort); 	
	BUF BUF2 (reset, btnC);
	BUF BUF3 (start, btnL);
	BUF BUF4 (ack, btnR);
	
	reg [27:0]	DIV_CLK;
	always @ (posedge board_clk, posedge reset)  
	begin : CLOCK_DIVIDER
      if (reset)
			DIV_CLK <= 0;
      else
			DIV_CLK <= DIV_CLK + 1'b1;
	end	

	assign	button_clk = DIV_CLK[18];
	assign	clk = DIV_CLK[1];
	assign 	{St_ce_bar, St_rp_bar, Mt_ce_bar, Mt_St_oe_bar, Mt_St_we_bar} = {5'b11111};
	
	wire inDisplayArea;
	wire [9:0] CounterX;
	wire [9:0] CounterY;

	hvsync_generator syncgen(.clk(clk), .reset(reset),.vga_h_sync(vga_h_sync), .vga_v_sync(vga_v_sync), .inDisplayArea(inDisplayArea), .CounterX(CounterX), .CounterY(CounterY));
	
	/////////////////////////////////////////////////////////////////
	///////////////		VGA control starts here		/////////////////
	/////////////////////////////////////////////////////////////////
	
	
	reg [9:0] position;
	reg [9:0] positionX;
	
	reg [3:0] state;
	reg [9:0] g;
	assign {q_Init,q_Game,q_Die,q_Win} = state;
	localparam
	I = 4'b1000, Game = 4'b0100, Die = 4'b0010, Win = 4'b0001, UNK = 4'bXXXX;
	reg dead;

				wire		R = (q_Win&&(CounterY>=(position) && CounterY<=(position+20) && CounterX>=positionX && CounterX<=(positionX+20)))|(q_Die&&DIV_CLK[23]);
	  //(CounterX>=(position-20) && CounterX<=(position+20) && CounterY[8:4]==29)|(CounterX>=(position-10) && CounterX<=(position+10) && CounterY[8:4]==28)|(CounterX>=(position-5) && CounterX<=(position+5) && CounterY[8:4]==27)|(CounterX>=(position-2) && CounterX<=(position+2) && CounterY[8:4]==26);
				wire		G = ((CounterX[9:5]==5'b00001)&&((CounterY<128)|(CounterY>180)))|((CounterX[9:5]==5'b00101)&&((CounterY<180)|(CounterY>210)))|((CounterX[9:5]==5'b01001)&&((CounterY<240)|(CounterY>300)))|((CounterX[9:5]==5'b01101)&&((CounterY<220)|(CounterY>250)))|((CounterX[9:5]==5'b10001)&&((CounterY<300)|(CounterY>370)));
				wire		B = (CounterY>=(position) && CounterY<=(position+20) && CounterX>=positionX && CounterX<=(positionX+20));
		
	
	always @(posedge DIV_CLK[21],posedge reset)
		begin
			if(reset)
				begin
				position<=150;
				positionX <=0;
				g<=0;
				end
			else if(ack)
				begin
								
				g<=0;
				if(~q_Die)
				begin
				position<=position-2;
				end
				if(q_Game)
				begin
				positionX<=positionX+1;
				end
				
				end
			else if(~ack)
				begin
				if(q_Game)
				begin
			   position<=position+g;
				positionX<=positionX+1;
				g<=g+1;
			   	end
				end
		end
				
		always@(posedge clk,posedge reset)		
		begin
		
		if(reset)
			begin
			
			state<=I;
			
			end
		else
			begin
		
		case(state)
					I:
					begin
                 
						if(start) 
						begin
						state<=Game;
							
						end


					end
					Game:
					begin
					if(positionX>=620)
					state<=Win;
					if((positionX>12&&positionX<63&&(position<128|position>160))|positionX>140&&(positionX<191&&(position<180|position>190))|(positionX>268&&positionX<319&&(position<240|position>280))|(positionX>396&&positionX<447&&(position<220|position>230))|(positionX>524&&positionX<575&&(position<300|position>350)))
					state<=Die;
					end
				   
					Die:
					begin
					
				
					end
			
				   Win:
					begin
					
					end
				endcase
				
				
				
			end
				

		end

	always @(posedge clk)
	begin
		vga_r <= R & inDisplayArea;
		vga_g <= G & inDisplayArea;
		vga_b <= B & inDisplayArea;
	end
	
	//CounterY[9:8]==1
	/////////////////////////////////////////////////////////////////
	//////////////  	  VGA control ends here 	 ///////////////////
	/////////////////////////////////////////////////////////////////
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  LD control starts here 	 ///////////////////
	/////////////////////////////////////////////////////////////////
	/*`define QI 			2'b00
	`define QGAME_1 	2'b01
	`define QGAME_2 	2'b10
	`define QDONE 		2'b11*/
	
	
	
	reg [3:0] p2_score;
	reg [3:0] p1_score;
	
	wire LD0, LD1, LD2, LD3, LD4, LD5, LD6, LD7;
	
	assign LD0 = (p1_score == 4'b1010);
	assign LD1 = (p2_score == 4'b1010);
	
	assign LD2 = start;
	assign LD4 = reset;
	
	assign LD3 = (state == I);
	assign LD5 = (state == Game);	
	assign LD6 = (state == Die);
	assign LD7 = (state == Win);
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  LD control ends here 	 	////////////////////
	/////////////////////////////////////////////////////////////////
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  SSD control starts here 	 ///////////////////
	/////////////////////////////////////////////////////////////////
	reg 	[3:0]	SSD;
	wire 	[3:0]	SSD0, SSD1, SSD2, SSD3;
	wire 	[1:0] ssdscan_clk;
	
	
	assign SSD3 = 4'b1111;
	assign SSD2 = 4'b1111;
	assign SSD1 = 4'b1111;
	assign SSD0 = position[3:0];
	
	
	// need a scan clk for the seven segment display 
	// 191Hz (50MHz / 2^18) works well
	assign ssdscan_clk = DIV_CLK[19:18];	
	assign An0	= !(~(ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 00
	assign An1	= !(~(ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 01
	assign An2	= !( (ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 10
	assign An3	= !( (ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 11
	
	always @ (ssdscan_clk, SSD0, SSD1, SSD2, SSD3)
	begin : SSD_SCAN_OUT
		case (ssdscan_clk) 
			2'b00:
					SSD = SSD0;
			2'b01:
					SSD = SSD1;
			2'b10:
					SSD = SSD2;
			2'b11:
					SSD = SSD3;
		endcase 
	end	

	// and finally convert SSD_num to ssd
	reg [6:0]  SSD_CATHODES;
	assign {Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp} = {SSD_CATHODES, 1'b1};
	// Following is Hex-to-SSD conversion
	always @ (SSD) 
	begin : HEX_TO_SSD
		case (SSD)		
			4'b1111: SSD_CATHODES = 7'b1111111 ; //Nothing 
			4'b0000: SSD_CATHODES = 7'b0000001 ; //0
			4'b0001: SSD_CATHODES = 7'b1001111 ; //1
			4'b0010: SSD_CATHODES = 7'b0010010 ; //2
			4'b0011: SSD_CATHODES = 7'b0000110 ; //3
			4'b0100: SSD_CATHODES = 7'b1001100 ; //4
			4'b0101: SSD_CATHODES = 7'b0100100 ; //5
			4'b0110: SSD_CATHODES = 7'b0100000 ; //6
			4'b0111: SSD_CATHODES = 7'b0001111 ; //7
			4'b1000: SSD_CATHODES = 7'b0000000 ; //8
			4'b1001: SSD_CATHODES = 7'b0000100 ; //9
			4'b1010: SSD_CATHODES = 7'b0001000 ; //10 or A
			default: SSD_CATHODES = 7'bXXXXXXX ; // default is not needed as we covered all cases
		endcase
	end
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  SSD control ends here 	 ///////////////////
	/////////////////////////////////////////////////////////////////
endmodule
