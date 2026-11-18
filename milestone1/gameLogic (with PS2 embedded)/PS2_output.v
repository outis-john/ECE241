
module PS2_output (
	// Inputs
	CLOCK_50,
	KEY,

	// Bidirectionals
	PS2_CLK,
	PS2_DAT,
	
	// Outputs
	LEDR, 
	w_held, a_held, s_held, d_held,
	up_held, left_held, down_held, right_held,
   lshift_held, rshift_held
);

// NOT OUR CODE START ********************************************************
// Inputs
input				CLOCK_50;
input		[3:0]	KEY;

// Bidirectionals
inout				PS2_CLK;
inout				PS2_DAT;

// Outputs
output [9:0] LEDR;

output w_held, a_held, s_held, d_held; // our code
output up_held, left_held, down_held, right_held; // our code
output lshift_held, rshift_held; // our code


/*****************************************************************************
 *                 Internal Wires and Registers Declarations                 *
 *****************************************************************************/

// Internal Wires
wire		[7:0]	ps2_key_data;
wire				ps2_key_pressed;

// Internal Registers
reg			[7:0]	last_data_received;


/*****************************************************************************
 *                             Sequential Logic                              *
 *****************************************************************************/

always @(posedge CLOCK_50)
begin
	if (KEY[0] == 1'b0)
		last_data_received <= 8'h00; // KEY0 active low sync reset
	else if (ps2_key_pressed == 1'b1) 
		last_data_received <= ps2_key_data; // store 8 bits in internal register
end

/*****************************************************************************
 *                              Internal Modules                             *
 *****************************************************************************/

PS2_Controller PS2 (
	// Inputs
	.CLOCK_50				(CLOCK_50),
	.reset				(~KEY[0]),

	// Bidirectionals
	.PS2_CLK			(PS2_CLK),
 	.PS2_DAT			(PS2_DAT),

	// Outputs
	.received_data		(ps2_key_data),
	.received_data_en	(ps2_key_pressed)
);

// NOT OUR CODE END ********************************************************

// OUR OWN CODE START ***************************************************

// instantiate
PS2_decoder decoder0 (
   // inputs
	.clock (CLOCK_50),
	.reset (~KEY[0]),
	.key_data (ps2_key_data),
	.bits_updated(ps2_key_pressed),
	.w (w_held), .a (a_held), .s (s_held), .d (d_held), 
	.up (up_held), .left (left_held), .down (down_held), .right (right_held), 
	.lshift (lshift_held), .rshift (rshift_held)
);


assign LEDR[9:6] = {w_held, a_held, s_held, d_held};
assign LEDR[5:2] = {up_held, left_held, down_held, right_held};
assign LEDR[1:0] = {lshift_held, rshift_held};

endmodule
