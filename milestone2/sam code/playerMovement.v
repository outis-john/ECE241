module playerMove(
	// inputs
	CLOCK_50,
	tick,
	reset,
	rom_isWall,
	w_held, a_held, s_held, d_held,
   up_held, left_held, down_held, right_held,
	
	// outputs
	p1_x, p1_y, p1_facing,
	p2_x, p2_y, p2_facing,
	next_x, next_y,
	done
);

	input CLOCK_50, tick, reset;
	input [1:0] rom_isWall;
	input w_held, a_held, s_held, d_held;
	input up_held, left_held, down_held, right_held;

// position registers
	output reg [8:0] p1_x, p2_x; // x needs 9 bits for 0-304
	output reg [7:0] p1_y, p2_y; // y needs 8 bits for 0-208
	output reg [1:0] p1_facing, p2_facing; 
	output reg [8:0] next_x;
	output reg [7:0] next_y;
	output done;
	
// facing direction parameters
	parameter UP = 2'd0, LEFT = 2'd1, DOWN = 2'd2, RIGHT = 2'd3;
	
// Starting coordinates
	parameter [8:0] P1_SPAWN_X = 9'd16; // x = 16, y = 16 (top left tile)
	parameter [7:0] P1_SPAWN_Y = 8'd16; 

	parameter [8:0] P2_SPAWN_X = 9'd288; // x = 288, y = 208 (bottom right tile)
	parameter [7:0] P2_SPAWN_Y = 8'd208;
	
// player movement processing selection
	reg curPlayer; // p1 = WASD & curPlayer = 0, p2 = ARROWS & curPlayer = 1
	
// nextstate and curstate
	reg [2:0] y_Q, Y_D;	
	
// state codes
   parameter IDLE = 3'd0, NEXT = 3'd1, READ = 3'd2, CHECK = 3'd3, SWITCH = 3'd4;
	
	
//FSM
	//  NEXT STATES
	always @ (*) begin
		Y_D = y_Q;
		case (y_Q)
			IDLE:
				if (tick) Y_D = NEXT; // begin FSM cycle to update coords at every game clock tick
			NEXT: 
				if ((!curPlayer & (w_held | a_held| s_held| d_held)) |
					(curPlayer & (up_held | left_held| down_held | right_held)))
					Y_D = READ; // valid key held
				else 
					Y_D = SWITCH; // jump to next player
			READ:
				Y_D = CHECK; // rom takes next coordinates during READ
			CHECK:
				Y_D = SWITCH; // rom q output returns value here
			SWITCH:
				if (curPlayer == 1'b0) // check p2 after checking p1
					Y_D = NEXT;
				else if (curPlayer == 1'b1) // if just finished checking p2, go back to idle
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
			p1_facing <= RIGHT;
			p2_facing <= LEFT; 
		end
		else begin
			y_Q <= Y_D; // flipflop
			
			// outputs assignments (can only change on clock)
			case (y_Q)
			IDLE: curPlayer <= 1'b0;
			NEXT: begin
				// update facing and next position registers
				if (curPlayer == 1'b0) begin // if player 1
				// make sure both coordinates updated
				// if/else only updates one
					next_x <= p1_x;
					next_y <= p1_y;
			
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
					next_x <= p2_x;
					next_y <= p2_y;
				
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
			CHECK: 
				if (rom_isWall == 2'b00) begin // is floor
					if (curPlayer == 1'b0) begin
						p1_x <= next_x;
						p1_y <= next_y;
					end
					else if (curPlayer == 1'b1) begin
						p2_x <= next_x;
						p2_y <= next_y;
					end
				end
			SWITCH: curPlayer <= ~curPlayer; // swap to check next player
			default: ;
		endcase
		end 
	end
	assign done = (y_Q == SWITCH) && (curPlayer == 1'b1);
endmodule
	
