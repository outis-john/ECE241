module hitDetect(
	//inputs
	CLOCK_50,
	reset,
	
	// target positions
	p1_tX, p1_tY,
	p2_tX, p2_tY,
	
	// bullet states
	b1_x, b1_y,
	b2_x, b2_y,
	b1_active, b2_active,
	
	//outputs
	
	// target alive states
	p1_t_alive, p2_t_alive,
	
	// score
	p1_score, p2_score,
	
	// bullet collision flag
	b1_hit, b2_hit
);
	
	input CLOCK_50, reset;
	
	// concatenated x and y coord registers
	input [17:0] p1_tX;
	input [15:0] p1_tY; 
	input [17:0] p2_tX;
	input [15:0] p2_tY;
	
	// bullet states
	input [8:0] b1_x, b2_x;
   input [7:0] b1_y, b2_y;
	input b1_active, b2_active;
	
	

	output reg [1:0] p1_t_alive;
	output reg [1:0] p2_t_alive;
	output reg [2:0] p1_score;
	output reg [2:0] p2_score;
	
	// bullet collision with targets register
	// 2 bullets * 4 targets = 8 collision values
	// 2 bits per reg, one for target 1, one for target 2
	reg [1:0] b1_hit_p1t, b1_hit_p2t;
	reg [1:0] b2_hit_p1t, b2_hit_p2t;
	
	output b1_hit, b2_hit;
	assign b1_hit = b1_hit_p1t[0] | b1_hit_p1t[1] | b1_hit_p2t[0] | b1_hit_p2t[1];
	assign b2_hit = b2_hit_p1t[0] | b2_hit_p1t[1] | b2_hit_p2t[0] | b2_hit_p2t[1];
	 
	 
	always @ (*) begin
		b1_hit_p1t[0] = b1_active && p1_t_alive[0] && (p1_tX[8:0] == b1_x) && (p1_tY[7:0] == b1_y);
		b1_hit_p1t[1] = b1_active && p1_t_alive[1] && (p1_tX[17:9] == b1_x) && (p1_tY[15:8] == b1_y);
		
	
		b1_hit_p2t[0] = b1_active && p2_t_alive[0] && (p2_tX[8:0] == b1_x) && (p2_tY[7:0] == b1_y);
		b1_hit_p2t[1] = b1_active && p2_t_alive[1] && (p2_tX[17:9] == b1_x) && (p2_tY[15:8] == b1_y);
				  
		b2_hit_p1t[0] = b2_active && p1_t_alive[0] && (p1_tX[8:0] == b2_x) && (p1_tY[7:0] == b2_y);
		b2_hit_p1t[1] = b2_active && p1_t_alive[1] && (p1_tX[17:9] == b2_x) && (p1_tY[15:8] == b2_y);
								  
		b2_hit_p2t[0] = b2_active && p2_t_alive[0] && (p2_tX[8:0] == b2_x) && (p2_tY[7:0] == b2_y);
		b2_hit_p2t[1] = b2_active && p2_t_alive[1] && (p2_tX[17:9] == b2_x) && (p2_tY[15:8] == b2_y);
	end
	
	always @ (posedge CLOCK_50) begin
		if (reset) begin
			p1_t_alive <= 2'b11;
			p2_t_alive <= 2'b11;
			p1_score <= 3'd5;
			p2_score <= 3'd5;
		end
		else begin
			// update target alive flag	
			p1_t_alive[0] <= p1_t_alive[0] & ~(b1_hit_p1t[0] | b2_hit_p1t[0]);
			p1_t_alive[1] <= p1_t_alive[1] & ~(b1_hit_p1t[1] | b2_hit_p1t[1]);
			
			p2_t_alive[0] <= p2_t_alive[0] & ~(b1_hit_p2t[0] | b2_hit_p2t[0]);
			p2_t_alive[1] <= p2_t_alive[1] & ~(b1_hit_p2t[1] | b2_hit_p2t[1]);
			
			// player 1 score
			if (b1_hit_p1t[0] | b1_hit_p1t[1]) begin
				p1_score <= p1_score + 1;
			end
			else if (b1_hit_p2t[0] | b1_hit_p2t[1]) begin
				p1_score <= p1_score - 1;
			end
			// player 2 score
			if (b2_hit_p1t[0] | b2_hit_p1t[1]) begin
				p2_score <= p2_score - 1;
			end
				
			else if (b2_hit_p2t[0] | b2_hit_p2t[1]) begin
				p2_score <= p2_score + 1;
			end
		end
	end	
endmodule
	
	
	
