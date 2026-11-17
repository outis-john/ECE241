// tile_painter.v
// Draws one solid 16x16 tile on the 320x240 VGA screen.
//   - Pulse 'start' for one clock with the tile position (tx, ty) and colour.
//   - The painter saves the request, then writes 256 pixels, one per clock.
//   - 'busy' is 1 while drawing; 'done' pulses for one clock at the end.
// Pixel position = tile position * 16 + offset inside the tile, which is the
// same as joining the bits: x = {tx, px}, y = {ty, py}.
module tile_painter (clk, resetn, start, tx, ty, color_in,
                     x_out, y_out, color_out, write_out, busy, done);
    input        clk, resetn, start;
    input  [4:0] tx;           // tile column 0..19
    input  [3:0] ty;           // tile row    0..14
    input  [8:0] color_in;     // {RRR, GGG, BBB}
    output [8:0] x_out;        // to VGA adapter x
    output [7:0] y_out;        // to VGA adapter y
    output [8:0] color_out;    // to VGA adapter color
    output       write_out;    // to VGA adapter write
    output       busy;
    output reg   done;

    localparam IDLE = 2'd0, DRAW = 2'd1, FIN = 2'd2;
    reg [1:0] state;

    reg [4:0] tx_r;            // saved request, so inputs may change while drawing
    reg [3:0] ty_r;
    reg [8:0] col_r;
    reg [3:0] px, py;          // pixel offset inside the tile, 0..15

    always @(posedge clk) begin
        if (!resetn) begin
            state <= IDLE;
            done  <= 1'b0;
            tx_r  <= 5'd0;
            ty_r  <= 4'd0;
            col_r <= 9'd0;
            px    <= 4'd0;
            py    <= 4'd0;
        end
        else begin
            done <= 1'b0;                        // default: done is a 1-clock pulse
            case (state)
                IDLE: if (start) begin
                          tx_r  <= tx;           // save the request
                          ty_r  <= ty;
                          col_r <= color_in;
                          px    <= 4'd0;
                          py    <= 4'd0;
                          state <= DRAW;
                      end
                DRAW: begin                      // one pixel written per clock
                          if (px == 4'd15) begin
                              px <= 4'd0;
                              if (py == 4'd15)
                                  state <= FIN;  // last pixel of the tile
                              else
                                  py <= py + 1'b1;   // next row
                          end
                          else
                              px <= px + 1'b1;       // next pixel in the row
                      end
                FIN:  begin
                          done  <= 1'b1;
                          state <= IDLE;
                      end
                default: state <= IDLE;
            endcase
        end
    end

    assign x_out     = {tx_r, px};     // tx*16 + px
    assign y_out     = {ty_r, py};     // ty*16 + py
    assign color_out = col_r;
    assign write_out = (state == DRAW);
    assign busy      = (state != IDLE);
endmodule
