// player_draw.v
// Keeps the two players drawn on screen, using tile_painter.
//   - Waits until the maze is drawn (maze_done), then draws P1 and P2.
//   - Remembers where each player was last drawn. Whenever gameLogic moves
//     a player, it repaints:
//         step 0: erase P1's old tile (path colour)  - only if P1 moved
//         step 1: erase P2's old tile (path colour)  - only if P2 moved
//         step 2: draw P1 at its new tile (red)
//         step 3: draw P2 at its new tile (blue)
//     Both erases happen before both draws, so a player that steps onto the
//     tile the other one just left is never erased by mistake. If both players
//     stand on the same tile, P2 is drawn last and shows on top.
// Positions from gameLogic are in pixels (multiples of 16); the tile is the
// top bits: tx = x[8:4], ty = y[7:4].
`include "params.vh"

module player_draw (clk, resetn, maze_done,
                    p1_x, p1_y, p2_x, p2_y,
                    paint_done,
                    paint_start, paint_tx, paint_ty, paint_color);
    input        clk, resetn;
    input        maze_done;               // from screenscanner
    input  [8:0] p1_x, p2_x;              // from gameLogic (pixels)
    input  [7:0] p1_y, p2_y;
    input        paint_done;              // from tile_painter
    output       paint_start;             // to tile_painter
    output reg [4:0] paint_tx;
    output reg [3:0] paint_ty;
    output reg [8:0] paint_color;

    // current tile of each player, packed as {ty, tx}
    wire [8:0] cur1 = {p1_y[7:4], p1_x[8:4]};
    wire [8:0] cur2 = {p2_y[7:4], p2_x[8:4]};

    reg [8:0] drawn1, drawn2;   // where each player is currently drawn
    reg [8:0] new1,   new2;     // positions being drawn in this update
    reg       first;            // first draw after the maze: nothing to erase
    reg [1:0] step;             // 0..3, see table above

    localparam WAIT_MAZE = 2'd0, IDLE = 2'd1, STEP = 2'd2, WAIT = 2'd3;
    reg [1:0] state;

    // what to paint in the current step
    reg [8:0] step_pos;
    reg       step_needed;
    always @(*) begin
        case (step)
            2'd0: begin step_pos = drawn1; paint_color = `COLOR_PATH;
                        step_needed = !first && (drawn1 != new1); end
            2'd1: begin step_pos = drawn2; paint_color = `COLOR_PATH;
                        step_needed = !first && (drawn2 != new2); end
            2'd2: begin step_pos = new1;   paint_color = `COLOR_P1;
                        step_needed = 1'b1; end
            default: begin step_pos = new2; paint_color = `COLOR_P2;
                        step_needed = 1'b1; end
        endcase
        paint_ty = step_pos[8:5];
        paint_tx = step_pos[4:0];
    end

    // one-clock start pulse to tile_painter when this step needs painting
    assign paint_start = (state == STEP) && step_needed;

    always @(posedge clk) begin
        if (!resetn) begin
            state  <= WAIT_MAZE;
            step   <= 2'd0;
            first  <= 1'b1;
            drawn1 <= 9'd0;  drawn2 <= 9'd0;
            new1   <= 9'd0;  new2   <= 9'd0;
        end
        else begin
            case (state)
                WAIT_MAZE: if (maze_done) begin      // maze finished: draw both players
                               new1  <= cur1;
                               new2  <= cur2;
                               first <= 1'b1;
                               step  <= 2'd0;
                               state <= STEP;
                           end
                IDLE:      if (cur1 != drawn1 || cur2 != drawn2) begin
                               new1  <= cur1;          // snapshot the new positions
                               new2  <= cur2;
                               first <= 1'b0;
                               step  <= 2'd0;
                               state <= STEP;
                           end
                STEP:      if (step_needed)
                               state <= WAIT;          // paint_start is high this clock
                           else
                               step <= step + 1'b1;    // nothing to erase: skip
                WAIT:      if (paint_done) begin
                               if (step == 2'd3) begin // both players drawn
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
