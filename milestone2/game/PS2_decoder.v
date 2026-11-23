// OUR OWN CODE*****
module PS2_decoder (
	input clock,
	input reset,
	input [7:0] key_data,
	input bits_updated,
	output reg w, a, s, d, 
	output reg up, left, down, right, 
	output reg lshift, rshift
);

	reg E0, F0; // flags for extension codes E0, and release code F0
	
	
	always @(posedge clock) begin
		if (reset) 
			{w, a, s, d, up, left, down, right, lshift, rshift, E0, F0} <= 12'b0;
		
		else if (bits_updated) begin // new hex code is received
			
			if (key_data == 8'hE0) // check if bit is extension code, set flag
				E0 <= 1'b1;
			else if (key_data == 8'hF0) // check if bit is release code, set flag
				F0 <= 1'b1;
			else begin // if not a special code, update value for key held/released
				if (!E0) begin // handling non arrow keys
					case (key_data)
						8'h1D: w <= ~F0; // key held value (1-held, 0-release)
						8'h1C: a <= ~F0; // is inverse of release flag
						8'h1B: s <= ~F0;
						8'h23: d <= ~F0;
						8'h12: lshift <= ~F0;
						8'h59: rshift <= ~F0;
						default: ;
					endcase				
				end
				else if (E0) begin // handing arrow keys
					case (key_data)
						8'h75: up <= ~F0; // key held value (1-held, 0-release)
						8'h6B: left <= ~F0; // is inverse of release flag
						8'h72: down <= ~F0;
						8'h74: right <= ~F0;
						default: ;
					endcase
				end
				// reset flags
				E0 <= 1'b0;
				F0 <= 1'b0;	
			end
		end
	end
endmodule

	