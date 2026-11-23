// box_painter.v  (Milestone 2)
// Draws one solid 8x8 box whose top-left pixel is (x0, y0) - any pixel, not just
// tile boundaries. Same handshake as tile_painter: pulse 'start', wait for 'done'.
//
// Exclusion boxes (for flicker-free erasing): when excl_en = 1, pixels that fall
// inside the 8x8 box at (e1x, e1y) or (e2x, e2y) are skipped (not written).
// player_draw uses this to erase a player's old box WITHOUT touching the new boxes,
// so the players on screen are never painted over, even for a moment.
module box_painter (clk, resetn, start, x0, y0, color_in,
                    excl_en, e1x, e1y, e2x, e2y,
                    x_out, y_out, color_out, write_out, busy, done);
    input        clk, resetn, start;
    input  [8:0] x0;            // top-left pixel of the box
    input  [7:0] y0;
    input  [8:0] color_in;      // {RRR, GGG, BBB}
    input        excl_en;
    input  [8:0] e1x, e2x;      // boxes NOT to write over (when excl_en = 1)
    input  [7:0] e1y, e2y;
    output [8:0] x_out;         // to VGA adapter
    output [7:0] y_out;
    output [8:0] color_out;
    output       write_out;
    output       busy;
    output reg   done;

    localparam IDLE = 2'd0, DRAW = 2'd1, FIN = 2'd2;
    reg [1:0] state;

    reg [8:0] x0_r, e1x_r, e2x_r;    // saved request
    reg [7:0] y0_r, e1y_r, e2y_r;
    reg [8:0] col_r;
    reg       excl_r;
    reg [2:0] px, py;                // pixel offset inside the box, 0..7

    always @(posedge clk) begin
        if (!resetn) begin
            state <= IDLE;
            done  <= 1'b0;
            x0_r  <= 9'd0;  y0_r  <= 8'd0;  col_r <= 9'd0;  excl_r <= 1'b0;
            e1x_r <= 9'd0;  e1y_r <= 8'd0;  e2x_r <= 9'd0;  e2y_r  <= 8'd0;
            px    <= 3'd0;  py    <= 3'd0;
        end
        else begin
            done <= 1'b0;
            case (state)
                IDLE: if (start) begin
                          x0_r  <= x0;   y0_r  <= y0;   col_r <= color_in;
                          excl_r <= excl_en;
                          e1x_r <= e1x;  e1y_r <= e1y;
                          e2x_r <= e2x;  e2y_r <= e2y;
                          px <= 3'd0;    py <= 3'd0;
                          state <= DRAW;
                      end
                DRAW: begin
                          if (px == 3'd7) begin
                              px <= 3'd0;
                              if (py == 3'd7) state <= FIN;
                              else            py <= py + 1'b1;
                          end
                          else px <= px + 1'b1;
                      end
                FIN:  begin
                          done  <= 1'b1;
                          state <= IDLE;
                      end
                default: state <= IDLE;
            endcase
        end
    end

    assign x_out     = x0_r + px;
    assign y_out     = y0_r + py;
    assign color_out = col_r;

    // is the current pixel inside one of the protected boxes?
    wire in1 = (x_out >= e1x_r) && (x_out < e1x_r + 9'd8) &&
               (y_out >= e1y_r) && (y_out < e1y_r + 8'd8);
    wire in2 = (x_out >= e2x_r) && (x_out < e2x_r + 9'd8) &&
               (y_out >= e2y_r) && (y_out < e2y_r + 8'd8);

    assign write_out = (state == DRAW) && !(excl_r && (in1 || in2));
    assign busy      = (state != IDLE);
endmodule
