// gameLogic.v  (Milestone 2)
// Same ports as Milestone 1, so game_top does not need to change.
// Inside: PS/2 keyboard (PS2_output) + game tick + smooth movement (player_move).
// Milestone 1's tile-jump FSM was replaced by player_move, which moves the players
// one pixel per tick and only makes decisions when a player is lined up with a tile.
module gameLogic(
	// inputs
	CLOCK_50,
	KEY,
	// bidirectional
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
	output [8:0] p1_x, p2_x;     // top-left pixel of each player's 16x16 cell
	output [7:0] p1_y, p2_y;
	output [1:0] p1_facing, p2_facing;
	output tick;

	wire reset = ~KEY[0];

//*****PS2 Key decoder (unchanged)********************************************
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

//*****Game tick: one pulse per pixel of movement******************************
	// 128 Hz -> 128 pixels/s = 8 tiles per second (same speed as Milestone 1).
	// Speed = 50,000,000 / fastClock pixels per second:
	//   781250 -> 64 px/s (4 tiles/s), 390625 -> 128 px/s, 195313 -> 256 px/s
	gameTick #(.fastClock(24'd390625)) tick0 (
		.clear (reset),
		.CLOCK_50 (CLOCK_50),
		.T (tick)
	);

//*****Smooth movement**********************************************************
	player_move mover (
		.clk (CLOCK_50),
		.reset (reset),
		.tick (tick),
		.w (w_held), .a (a_held), .s (s_held), .d (d_held),
		.up (up_held), .left (left_held), .down (down_held), .right (right_held),
		.p1_x (p1_x), .p1_y (p1_y),
		.p2_x (p2_x), .p2_y (p2_y),
		.p1_facing (p1_facing), .p2_facing (p2_facing)
	);

endmodule


// EXTRA MODULES ******************************************************
module gameTick (clear, CLOCK_50, T);
	input clear;
	input CLOCK_50;
	output T;
	reg [23:0] Q = 24'b0;
	parameter fastClock = 24'd390625;

	always @ (posedge CLOCK_50)
	begin
		if (clear || T)
			Q <= 24'b0;
		else
			Q <= Q + 1;
	end
	assign T = (Q == fastClock-1) ? 1'b1 : 1'b0;
endmodule
