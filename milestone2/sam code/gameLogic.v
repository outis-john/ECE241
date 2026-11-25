module gameLogic(
	// inputs
	CLOCK_50,
	KEY,
	// bidirectional;
	PS2_CLK,
	PS2_DAT,
	// outputs
	tick,
	LEDR,
	p1_x, 
	p1_y,
	p2_x,
	p2_y,
	p1_facing,
	p2_facing,
	b1_x, b2_x,	
	b1_y, b2_y,
	b1_active, b2_active,
	b1_dir, b2_dir,
	p1_t_alive, p2_t_alive,
	HEX0, HEX5
);


	input CLOCK_50;
	input [3:0] KEY;
	
	inout PS2_CLK;
	inout PS2_DAT;
	
	output [9:0] LEDR;
	output [6:0] HEX5, HEX0;
	wire reset = ~KEY[0];
	
	// playerMove FSM outputs
	output [8:0] p1_x, p2_x;
	output [7:0] p1_y, p2_y; 
	output [1:0] p1_facing, p2_facing; 
	wire [8:0] pnext_x;
	wire [7:0] pnext_y;
	wire done; // high when player FSM done running
	
	
	// bulletMove FSM outputs
	output [8:0] b1_x, b2_x;	
	output [7:0] b1_y, b2_y;
	output [1:0] b1_dir, b2_dir;
	wire [8:0] bnext_x;
	wire [7:0] bnext_y;
	
	
	output b1_active, b2_active;

	
	wire busy; // high when bullet FSM is running
	
	// collision and scoring outputs
	wire [8:0] p1_t1_x = 9'd96;
	wire [7:0] p1_t1_y = 8'd112;
	wire [8:0] p1_t2_x = 9'd256;
	wire [7:0] p1_t2_y = 8'd64;
	wire [8:0] p2_t1_x = 9'd208;
	wire [7:0] p2_t1_y = 8'd112;
	wire [8:0] p2_t2_x = 9'd48;
	wire [7:0] p2_t2_y = 8'd160;
	
	//concatenated target positions
	wire [17:0] p1_tX = {p1_t2_x, p1_t1_x};
	wire [15:0] p1_tY = {p1_t2_y, p1_t1_y};
	wire [17:0] p2_tX = {p2_t2_x, p2_t1_x};
	wire [15:0] p2_tY = {p2_t2_y, p2_t1_y};
	
	//alive state of targets
	output [1:0] p1_t_alive;
	output [1:0] p2_t_alive;
	
	// hit state of bullet
	wire b1_hit, b2_hit;

	
	//player scores
	wire [2:0] p1_score;
	wire [2:0] p2_score;

	
	
// game clock (8 Hz)
	output tick;
	gameTick tick0 (
		.clear (reset), 
		.CLOCK_50 (CLOCK_50), 
		.T (tick)
	);
	
	
// PS2 Key decoder
	wire w_held, a_held, s_held, d_held;
	wire up_held, left_held, down_held, right_held;
	wire lshift_held, rshift_held;
	 
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
	
	
// ROM
	wire [1:0] rom_isWall;
	reg [8:0] pixel_adr;
	
	always @ (*) begin
		if (busy) pixel_adr = {bnext_y[7:4], bnext_x[8:4]};
		else      pixel_adr = {pnext_y[7:4], pnext_x[8:4]};
	end
	
	maze_rom rom0 (.address(pixel_adr), .clock (CLOCK_50), .q (rom_isWall));
	
// playerMove FSM	
	playerMove M0 (
	.CLOCK_50 (CLOCK_50),
	.tick (tick),
	.reset (reset),
	.rom_isWall (rom_isWall),
   .w_held (w_held), 
	.a_held (a_held), 
	.s_held (s_held), 
	.d_held (d_held),
	.up_held (up_held), 
	.left_held (left_held), 
	.down_held (down_held), 
	.right_held (right_held),
	.p1_x (p1_x), 
	.p1_y (p1_y), 
	.p1_facing (p1_facing),
	.p2_x (p2_x), 
	.p2_y (p2_y), 
	.p2_facing (p2_facing),
	.next_x (pnext_x), 
	.next_y (pnext_y),
	.done (done)
);


// bulletMove FSM

	bulletMove M1 (
		.CLOCK_50 (CLOCK_50),
		.reset (reset),
		.start (done),
		.lshift_held (lshift_held), 
		.rshift_held (rshift_held),
		.p1_x (p1_x), 
		.p1_y (p1_y), 
		.p1_facing (p1_facing),
		.p2_x (p2_x), 
		.p2_y (p2_y), 
		.p2_facing (p2_facing),
		.rom_isWall (rom_isWall),
		.b1_hit (b1_hit),
		.b2_hit (b2_hit),
		.next_x (bnext_x), 
		.next_y (bnext_y),
		.b1_x (b1_x), 
		.b1_y (b1_y), 
		.b1_active (b1_active),
		.b2_x (b2_x), 
		.b2_y (b2_y), 
		.b2_active (b2_active),
		.busy (busy),
		.b1_dir (b1_dir), 
		.b2_dir (b2_dir)
	);


// collision and scoring for bullets and targets
	hitDetect H0 (
		.CLOCK_50 (CLOCK_50),
		.reset (reset),
		.p1_tX (p1_tX), 
		.p1_tY (p1_tY),
		.p2_tX (p2_tX), 
		.p2_tY (p2_tY),
		.b1_x (b1_x), 
		.b1_y (b1_y), 
		.b1_active (b1_active),
		.b2_x (b2_x), 
		.b2_y (b2_y), 
		.b2_active (b2_active),
		.p1_t_alive (p1_t_alive), 
		.p2_t_alive (p2_t_alive),
		.p1_score (p1_score), 
		.p2_score (p2_score),
		.b1_hit (b1_hit), 
		.b2_hit (b2_hit)	
	);
	
// scoring on hex
	char_7seg_BCD D0 (p1_score, HEX5);
	char_7seg_BCD D1 (p2_score, HEX0);
	
	
	
endmodule


// EXTRA MODULES
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


// Displays 3 bit binary as decimal
module char_7seg_BCD (C, Display);
	input [2:0] C;
	output [6:0] Display;
	wire [6:0] h;
	assign h[6] = (C[1] & ~C[2]) | (C[2] & (~C[1]|~C[0]));
	assign h[5] = (~C[1] & ~C[0]) | (C[2] & (~C[1]|~C[0]));
	assign h[4] = ~C[0] & (C[1] | ~C[2]);
	assign h[3] = (C[1] & (~C[0] | ~C[2])) | (~C[1] & ((C[0] & C[2]) | (~C[0] & ~C[2])));
	assign h[2] = C[2] | ~C[1] | C[0];
	assign h[1] = ~C[2] | (~C[1] & ~C[0]) | (C[1] & C[0]);
	assign h[0] = C[1] | (C[0] & C[2]) | (~C[2] & ~C[1] & ~C[0]); 
	assign Display = ~h;
endmodule


