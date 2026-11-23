// player_draw.v  (Milestone 2: smooth movement, 8x8 players)
// Keeps both players drawn as 8x8 boxes centred in their 16-pixel corridor.
// Positions from gameLogic are the top-left pixel of the player's 16x16 cell and can
// now change by 1 pixel at a time, so the box is drawn at (x + 4, y + 4).
//
// Each update (whenever a position changes):
//   step 0: erase P1's old box (path colour) - skipping pixels of BOTH new boxes
//   step 1: erase P2's old box (path colour) - skipping pixels of BOTH new boxes
//   step 2: draw P1's new box (red)
//   step 3: draw P2's new box (blue, on top if they overlap)
// Because erasing never writes over a new box, the players never flicker, even
// though the old and new boxes overlap by 7 of their 8 pixels after a 1-pixel move.
`include "params.vh"

module player_draw (clk, resetn, maze_done,
                    p1_x, p1_y, p2_x, p2_y,
                    paint_done,
                    paint_start, paint_x, paint_y, paint_color,
                    excl_en, e1x, e1y, e2x, e2y);
    input        clk, resetn;
    input        maze_done;               // from screenscanner
    input  [8:0] p1_x, p2_x;              // from gameLogic (cell top-left, pixels)
    input  [7:0] p1_y, p2_y;
    input        paint_done;              // from box_painter
    output       paint_start;             // to box_painter
    output reg [8:0] paint_x;             // box top-left
    output reg [7:0] paint_y;
    output reg [8:0] paint_color;
    output reg   excl_en;                 // protect the new boxes while erasing
    output [8:0] e1x, e2x;
    output [7:0] e1y, e2y;

    // box top-left = cell top-left + 4 (centred), packed as {y, x}
    wire [16:0] cur1 = {p1_y + 8'd4, p1_x + 9'd4};
    wire [16:0] cur2 = {p2_y + 8'd4, p2_x + 9'd4};

    reg [16:0] drawn1, drawn2;   // boxes currently on screen
    reg [16:0] new1,   new2;     // boxes being drawn in this update
    reg        first;            // first draw after the maze: nothing to erase
    reg [1:0]  step;

    localparam WAIT_MAZE = 2'd0, IDLE = 2'd1, STEP = 2'd2, WAIT = 2'd3;
    reg [1:0] state;

    // the new boxes are protected while erasing
    assign e1x = new1[8:0];  assign e1y = new1[16:9];
    assign e2x = new2[8:0];  assign e2y = new2[16:9];

    // what to paint in the current step
    reg [16:0] step_pos;
    reg        step_needed;
    always @(*) begin
        case (step)
            2'd0: begin step_pos = drawn1; paint_color = `COLOR_PATH; excl_en = 1'b1;
                        step_needed = !first && (drawn1 != new1); end
            2'd1: begin step_pos = drawn2; paint_color = `COLOR_PATH; excl_en = 1'b1;
                        step_needed = !first && (drawn2 != new2); end
            2'd2: begin step_pos = new1;   paint_color = `COLOR_P1;   excl_en = 1'b0;
                        step_needed = 1'b1; end
            default: begin step_pos = new2; paint_color = `COLOR_P2;  excl_en = 1'b0;
                        step_needed = 1'b1; end
        endcase
        paint_y = step_pos[16:9];
        paint_x = step_pos[8:0];
    end

    assign paint_start = (state == STEP) && step_needed;

    always @(posedge clk) begin
        if (!resetn) begin
            state  <= WAIT_MAZE;
            step   <= 2'd0;
            first  <= 1'b1;
            drawn1 <= 17'd0;  drawn2 <= 17'd0;
            new1   <= 17'd0;  new2   <= 17'd0;
        end
        else begin
            case (state)
                WAIT_MAZE: if (maze_done) begin
                               new1  <= cur1;
                               new2  <= cur2;
                               first <= 1'b1;
                               step  <= 2'd0;
                               state <= STEP;
                           end
                IDLE:      if (cur1 != drawn1 || cur2 != drawn2) begin
                               new1  <= cur1;
                               new2  <= cur2;
                               first <= 1'b0;
                               step  <= 2'd0;
                               state <= STEP;
                           end
                STEP:      if (step_needed)
                               state <= WAIT;
                           else
                               step <= step + 1'b1;
                WAIT:      if (paint_done) begin
                               if (step == 2'd3) begin
                                   drawn1 <= new1;
                                   drawn2 <= new2;
                                   state  <= IDLE;
                               end
                               else begin
                                   step  <= step + 1'b1;
                                   state <= STEP;
                               end
                           end
            endcase
        end
    end
endmodule
