// screenscanner.v
// After reset, sweeps all 320x240 pixels once and draws the maze:
// each pixel looks up its 16x16 tile in maze_rom (00 = path, 01 = wall).
// The ROM answers one clock after the address, so x, y and write are
// delayed by one clock to line up with the colour.
`include "params.vh"

module screenscanner (clk, resetn, x_out, y_out, color_out, write_out, done);
    input clk;
    input resetn;
    output reg [8:0] x_out;      // to VGA adapter x
    output reg [7:0] y_out;      // to VGA adapter y
    output     [8:0] color_out;  // to VGA adapter color
    output reg       write_out;  // to VGA adapter write
    output reg       done;       // 1 once the whole maze is drawn

    reg  [8:0] x;                // pixel counters
    reg  [7:0] y;
    wire       scanning = ~done;

    // counters: x 0..319 along a row, then the next row; stop after (319, 239)
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

    // maze ROM lookup: tile = pixel / 16, address = {ty, tx}
    wire [1:0] tile;                       // 00 = path, 01 = wall
    maze_rom rom (
        .address({y[7:4], x[8:4]}),
        .clock(clk),
        .q(tile)                           // arrives one clock later
    );

    assign color_out = (tile == 2'b01) ? `COLOR_WALL : `COLOR_PATH;

    // delay x, y, write by one clock to match the ROM output
    always @(posedge clk) begin
        if (!resetn) begin
            x_out     <= 9'd0;
            y_out     <= 8'd0;
            write_out <= 1'b0;
        end
        else begin
            x_out     <= x;
            y_out     <= y;
            write_out <= scanning;
        end
    end
endmodule
