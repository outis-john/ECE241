module screenscanner (clk, resetn, x_out, y_out, color_out, write_out, done);
    input clk;
    input resetn;
    output reg [8:0] x_out;      // to VGA adapter x
    output reg [7:0] y_out;      // to VGA adapter y
    output     [8:0] color_out;  // to VGA adapter color
    output reg       write_out;  // to VGA adapter write
    output reg       done;

    reg  [8:0] x;                // counters (now internal)
    reg  [7:0] y;
    wire       scanning = ~done;

    always @(posedge clk) begin
        if (!resetn) begin
            x    <= 9'd0;
            y    <= 8'd0;
            done <= 1'b0;
        end
        else if (!done) begin
            if (x == 9'd319) begin
                x <= 9'd0;
                if (y == 8'd239)
                    done <= 1'b1;
                else
                    y <= y + 1'b1;
            end
            else
                x <= x + 1'b1;
        end
    end
	 
    wire [1:0] tile;                       // 00 = path, 01 = wall
    maze_rom rom (
        .address({y[7:4], x[8:4]}),        // tile = pixel / 16
        .clock(clk),
        .q(tile)                           // arrives ONE clock later
    );


    assign color_out = (tile == 2'b01) ? 9'b000_000_100    // wall: white
                                       : 9'b101_101_101;   // path: black


    always @(posedge clk) begin
        if (!resetn) begin
            x_out     <= 9'd0;
            y_out     <= 8'd0;
            write_out <= 1'b0;
        end
        else begin
            x_out     <= x;         // same clock the ROM reads (x, y),
            y_out     <= y;         // so all three line up with "tile"
            write_out <= scanning;
        end
    end
endmodule