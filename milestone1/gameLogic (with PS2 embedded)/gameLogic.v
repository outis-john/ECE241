module gameLogic(
	// inputs
	CLOCK_50,
	KEY,
	// bidirectional;
	PS2_CLK,
	PS2_DAT,
	// outputs
	LEDR,
	p1_x, 
	p1_y,
	p2_x,
	p2_y,
	p1_facing,
	p2_facing,
	tick
);
	input CLOCK_50;
	input [3:0] KEY;
	inout PS2_CLK;
	inout PS2_DAT;
	output [9:0] LEDR;
	wire reset = ~KEY[0];
	
	
//*****PS2 Key decoder*********************************************************

	wire w_held, a_held, s_held, d_held;
	wire up_held, left_held, down_held, right_held;
	wire lshift_held, rshift_held;
	 
	 // held keys are 1'b1 when the respective key is held
	PS2_output keyHeldValues (
		.CLOCK_50 (CLOCK_50),
		.KEY (KEY),
		.PS2_CLK (PS2_CLK),
		.PS2_DAT (PS2_DAT),
		.LEDR (LEDR), 
		.w_held (w_held), 
		.a_held (a_held), 
		.s_held (s_held), 
		.d_held (d_held),
		.up_held (up_held), 
		.left_held (left_held), 
		.down_held (down_held), 
		.right_held (right_held),
		.lshift_held (lshift_held), 
		.rshift_held (rshift_held)
	);
	
// ****gameTick*******************************************************
	output tick;
	// currently at 8Hz
	gameTick tick0 (
		.clear (reset), 
		.CLOCK_50 (CLOCK_50), 
		.T (tick)
	);
	
//******** ROM*******************************************************
   reg [8:0] next_x;
	reg [7:0] next_y;
	wire [8:0] pixel_adr = {next_y[7:4], next_x[8:4]}; // address to check 
	wire [1:0] rom_isWall; // 00 is floor, 01 is wall
	maze_rom rom0 (.address(pixel_adr), .clock (CLOCK_50), .q (rom_isWall));
	
//******VARIABLES***************************************
 
// position registers
	output reg [8:0] p1_x, p2_x; // x needs 9 bits for 0-304
	output reg [7:0] p1_y, p2_y; // y needs 8 bits for 0-208
	output reg [1:0] p1_facing, p2_facing; 
	
// facing direction parameters
	parameter UP = 2'd0, LEFT = 2'd1, DOWN = 2'd2, RIGHT = 2'd3;
	
	
// Starting spawn coordinates
	parameter [8:0] P1_SPAWN_X = 9'd16; // x = 16, y = 16 (top left tile)
	parameter [7:0] P1_SPAWN_Y = 8'd16; 

	parameter [8:0] P2_SPAWN_X = 9'd288; // x = 288, y = 208 (bottom right tile)
	parameter [7:0] P2_SPAWN_Y = 8'd208;
	
// player movement processing selection
	reg curPlayer; // p1 = WASD & curPLAYER = 0, p2 = ARROWS & curPLAYER = 1
	
// nextstate and curstate
	reg [2:0] y_Q, Y_D;	
	
// state codes
   parameter IDLE = 3'd0, NEXT = 3'd1, READ = 3'd2, CHECK = 3'd3, SWITCH = 3'd4;
	
//*********FSM*******************************************************************

	//  NEXT STATES
	always @ (*) begin
		Y_D = y_Q;
		case (y_Q)
			IDLE:
				if (tick) Y_D = NEXT;
			NEXT: 
				if ((!curPlayer & (w_held | a_held| s_held| d_held)) |
					(curPlayer & (up_held | left_held| down_held | right_held)))
					Y_D = READ;
				else 
					Y_D = SWITCH;
			READ:
				Y_D = CHECK; // give one clock 
			CHECK:
				Y_D = SWITCH;
			SWITCH:
				if (curPlayer == 1'b0) 
					Y_D = NEXT;
				else if (curPlayer == 1'b1)
					Y_D = IDLE;
			default: Y_D = IDLE;
		endcase
	end
	
	
	// flip flops
	always @ (posedge CLOCK_50) begin
		if (reset) begin 
			y_Q <= IDLE; // return to IDLE STATE
			p1_x <= P1_SPAWN_X; 
			p1_y <= P1_SPAWN_Y;
			p2_x <= P2_SPAWN_X;
			p2_y <= P2_SPAWN_Y;
			curPlayer <= 1'b0;
			next_x <= P1_SPAWN_X;
			next_y <= P1_SPAWN_Y;
		end
		else begin
			y_Q <= Y_D; // flipflop
			
			// outputs assignments (can only change on clock)
			case (y_Q)
			IDLE: curPlayer = 1'b0;
			NEXT: begin
				// update facing and next position registers
				if (curPlayer == 1'b0) begin
					if (w_held) begin
						next_y <= p1_y - 16;
						p1_facing <= UP;
					end 
					
					else if (s_held) begin
						next_y <= p1_y + 16;
						p1_facing <= DOWN;
					end
					
					else if (d_held) begin
						next_x <= p1_x + 16;
						p1_facing <= RIGHT;
					end
					
					else if (a_held) begin
						next_x <= p1_x - 16;
						p1_facing <= LEFT;
					end
				end
				else if (curPlayer == 1'b1) begin 
					if (up_held) begin
						next_y <= p2_y - 16;
						p2_facing <= UP;
					end 
					
					else if (down_held) begin
						next_y <= p2_y + 16;
						p2_facing <= DOWN;
					end
					
					else if (right_held) begin
						next_x <= p2_x + 16;
						p2_facing <= RIGHT;
					end
					
					else if (left_held) begin
						next_x <= p2_x - 16;
						p2_facing <= LEFT;
					end
				end
			end
			//READ:
			CHECK: 
				if (rom_isWall == 2'b00) begin
					if (curPlayer == 1'b0) begin
						p1_x <= next_x;
						p1_y <= next_y;
					end
					else if (curPlayer == 1'b1) begin
						p2_x <= next_x;
						p2_y <= next_y;
					end
				end
			SWITCH: curPlayer = ~curPlayer;
			default: ;
		endcase
		end 
	end
	
	

endmodule


// EXTRA MODULES ******************************************************
module gameTick (clear, CLOCK_50, T);
	input clear;
	input CLOCK_50;
	output T;	
	reg [23:0] Q = 24'b0;
	parameter fastClock = 24'd6250000;
	
	always @ (posedge CLOCK_50)
	begin
			if (clear || T)
				Q <= 24'b0;
			else 
				Q <= Q + 1;
	end
   assign T = (Q == fastClock-1)?1'b1:1'b0;		
	//assign T = (Q == 2)?1'b1:1'b0;		
endmodule


////HOW TO instantiate gameLogic.v
	
// include (CLOCK_50, KEY, LEDR, PS2_CLK, PS2_DAT in header)	
/*
	input CLOCK_50;
	input [3:0] KEY;
	inout PS2_CLK;
	inout PS2_DAT;
	output [9:0] LEDR;
	
wire [8:0] p1_x, p2_x;
wire [7:0] p1_y, p2_y;
wire [1:0] p1_facing, p2_facing;
wire tick;
	
gameLogic GL0 (
	.CLOCK_50 (CLOCK_50),
	.KEY (KEY),
	.PS2_CLK (PS2_CLK),
	.PS2_DAT (PS2_DAT),
	.LEDR (LEDR),
	.p1_x (p1_x), 
	.p1_y (p1_y),
	.p2_x (p2_x),
	.p2_y (p2_y),
	.p1_facing (p1_facing),
	.p2_facing (p2_facing),
	.tick (tick)
);
