module bulletMove(
	// inputs
	CLOCK_50,
	reset,
	start,
	lshift_held, rshift_held,
	p1_x, p1_y, p1_facing,
	p2_x, p2_y, p2_facing,
	rom_isWall,
	b1_hit, b2_hit,
	
	// outputs
	next_x, next_y,
	b1_x, b1_y, b1_active,
	b2_x, b2_y, b2_active,
	b1_dir, b2_dir,
	busy
);

	input CLOCK_50, reset, start;
	input lshift_held, rshift_held;
	
	input [8:0] p1_x, p2_x;
	input [7:0] p1_y, p2_y;
	input [1:0] p1_facing, p2_facing; 
	input [1:0] rom_isWall;
	input b1_hit, b2_hit;
	
	output reg [8:0] b1_x, b2_x, next_x;
	output reg [7:0] b1_y, b2_y, next_y;
	
	output reg [1:0] b1_dir, b2_dir;
	reg [1:0] cur_dir;
	reg [8:0] cur_x;
	reg [7:0] cur_y;
	
	reg curBullet;
	output reg b1_active, b2_active;
	
	reg [2:0] y_Q, Y_D;	
	parameter IDLE = 3'd0, NEXT = 3'd1, READ = 3'd2, CHECK = 3'd3, SWITCH = 3'd4;
	output busy;
	assign busy = (y_Q != IDLE);
	
	parameter UP = 2'd0, LEFT = 2'd1, DOWN = 2'd2, RIGHT = 2'd3;

	// set bullet positions for each cycle
	always @ (*) begin
		if (!curBullet) begin
		
			if (b1_active) begin 
				cur_x = b1_x; 
				cur_y = b1_y; 
				cur_dir = b1_dir; 
			end
			
			else if (!b1_active) begin 
				cur_x = p1_x; 
				cur_y = p1_y; 
				cur_dir = p1_facing; 
			end
			
		end 
		else begin
		
			if (b2_active) begin 
				cur_x = b2_x; 
				cur_y = b2_y; 
				cur_dir = b2_dir; 
			end
			
			else begin 
				cur_x = p2_x; 
				cur_y = p2_y; 
				cur_dir = p2_facing; 
			end
			
		end   
	end			
	
	
	//  NEXT STATES
	always @ (*) begin
		Y_D = y_Q;
		case (y_Q)
			IDLE:
				if (start) Y_D = NEXT;
			NEXT: 
				if ((~curBullet & (lshift_held | b1_active)) | 
					  (curBullet & (rshift_held | b2_active)))
					Y_D = READ;
				else
					Y_D = SWITCH;
			READ:
				Y_D = CHECK;
			CHECK:
				Y_D = SWITCH;
			SWITCH:
				if (!curBullet)
					Y_D = NEXT;
				else
					Y_D = IDLE;
			default: Y_D = IDLE;
		endcase
	end
	
	
	// flip flops
	always @ (posedge CLOCK_50) begin
		if (reset) begin
			y_Q <= IDLE;
			curBullet <= 1'b0;
			next_x <= 9'd0; next_y <= 8'd0;
			b1_active <= 1'b0; b2_active <= 1'b0;
			b1_x <= 9'b0; b1_y <= 8'b0; b1_dir <= RIGHT;
		   b2_x <= 9'b0; b2_y <= 8'b0; b2_dir <= LEFT;
		end
		else begin
			y_Q <= Y_D;
			
	      // outputs assignments
			case (y_Q)
				IDLE:
					curBullet <= 1'b0;
					
				NEXT: begin
					next_x <= cur_x;
					next_y <= cur_y;
					
					case (cur_dir)
						UP:    next_y <= cur_y - 16;
						LEFT:  next_x <= cur_x - 16;
						DOWN:  next_y <= cur_y + 16;
						RIGHT: next_x <= cur_x + 16;
					endcase
					
					if (!curBullet && !b1_active) b1_dir <= p1_facing;
					if  (curBullet && !b2_active) b2_dir <= p2_facing;
				end
				
				CHECK:
					if (rom_isWall == 2'b00) begin
						if (!curBullet) begin 
							b1_active <= 1'b1;
							b1_x <= next_x; 
							b1_y <= next_y; 
						end
						else if (curBullet) begin 
							b2_active <= 1'b1;
							b2_x <= next_x; 
							b2_y <= next_y; 
						end
					end
					else if (rom_isWall == 2'b01) begin
						if (!curBullet) b1_active <= 1'b0;
						else            b2_active <= 1'b0;
					end
					
				SWITCH: curBullet <= ~curBullet;
				default: ;
			endcase
			if (b1_hit) b1_active <= 1'b0;
			if (b2_hit) b2_active <= 1'b0;
		end
	end
endmodule