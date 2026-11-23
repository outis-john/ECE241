// tb_player_draw.v (Milestone 2) - self-checking testbench for player_draw + box_painter.
// Plays the VGA adapter: keeps a 320x240 "screen" (starting all path colour, like the
// maze corridors) and applies every pixel write. Checks:
//   - NO FLICKER: a path-colour write never lands on a player's current box
//   - after every update the screen shows exactly the two 8x8 boxes (P2 on top)
//     and path colour everywhere else (no leftover trails)
// Moves: P1 slides right 1 px at a time, P2 slides up, then both move together,
// then P2 moves onto P1 (overlap), then they separate again.
`timescale 1ns / 1ns
`include "params.vh"

module tb_player_draw;
    reg        clk = 1'b0, resetn = 1'b0, maze_done = 1'b0;
    reg  [8:0] p1_x = 9'd16,  p2_x = 9'd288;
    reg  [7:0] p1_y = 8'd16,  p2_y = 8'd208;

    wire       paint_start, paint_done, paint_busy, excl_en, write_out;
    wire [8:0] paint_x, paint_color, e1x, e2x, x_out, color_out;
    wire [7:0] paint_y, e1y, e2y, y_out;

    always #10 clk = ~clk;

    player_draw dut (
        .clk(clk), .resetn(resetn), .maze_done(maze_done),
        .p1_x(p1_x), .p1_y(p1_y), .p2_x(p2_x), .p2_y(p2_y),
        .paint_done(paint_done), .paint_start(paint_start),
        .paint_x(paint_x), .paint_y(paint_y), .paint_color(paint_color),
        .excl_en(excl_en), .e1x(e1x), .e1y(e1y), .e2x(e2x), .e2y(e2y)
    );

    box_painter painter (
        .clk(clk), .resetn(resetn), .start(paint_start),
        .x0(paint_x), .y0(paint_y), .color_in(paint_color),
        .excl_en(excl_en), .e1x(e1x), .e1y(e1y), .e2x(e2x), .e2y(e2y),
        .x_out(x_out), .y_out(y_out), .color_out(color_out),
        .write_out(write_out), .busy(paint_busy), .done(paint_done)
    );

    // ---------------- the "screen" ----------------
    reg [8:0] screen [0:76799];
    integer i, errors = 0, flicker = 0, updates = 0;

    initial for (i = 0; i < 76800; i = i + 1) screen[i] = `COLOR_PATH;

    // is pixel (x,y) inside a player's box? (box = cell + 4, size 8)
    function inbox(input [8:0] x, input [7:0] y, input [8:0] cx, input [7:0] cy);
        inbox = (x >= cx + 9'd4) && (x < cx + 9'd12) && (y >= cy + 8'd4) && (y < cy + 8'd12);
    endfunction

    always @(posedge clk) begin
        if (resetn && write_out) begin
            if (color_out == `COLOR_PATH &&
                (inbox(x_out, y_out, p1_x, p1_y) || inbox(x_out, y_out, p2_x, p2_y))) begin
                if (flicker < 5)
                    $display("%t  FLICKER: path written at (%0d,%0d) inside a player box", $time, x_out, y_out);
                flicker = flicker + 1;
            end
            screen[y_out*320 + x_out] = color_out;
        end
    end

    // wait until player_draw is idle again, then compare the whole screen
    task settle_and_check;
        integer x, y, bad;
        reg [8:0] want;
        begin
            repeat (5) @(posedge clk);
            wait (dut.state == 2'd1);            // IDLE
            @(posedge clk);
            bad = 0;
            for (y = 0; y < 240; y = y + 1)
                for (x = 0; x < 320; x = x + 1) begin
                    if      (inbox(x, y, p2_x, p2_y)) want = `COLOR_P2;
                    else if (inbox(x, y, p1_x, p1_y)) want = `COLOR_P1;
                    else                              want = `COLOR_PATH;
                    if (screen[y*320 + x] !== want) bad = bad + 1;
                end
            if (bad != 0) begin
                $display("%t  WRONG screen: %0d pixels wrong (P1 at %0d,%0d  P2 at %0d,%0d)",
                         $time, bad, p1_x, p1_y, p2_x, p2_y);
                errors = errors + 1;
            end
            updates = updates + 1;
        end
    endtask

    integer k;
    initial begin
        #40 resetn = 1'b1;
        #40 maze_done = 1'b1;
        settle_and_check;                                   // first draw

        for (k = 0; k < 20; k = k + 1) begin               // P1 right, 1 px at a time
            p1_x = p1_x + 1;  settle_and_check;
        end
        for (k = 0; k < 20; k = k + 1) begin               // P2 up
            p2_y = p2_y - 1;  settle_and_check;
        end
        for (k = 0; k < 10; k = k + 1) begin               // both at once
            p1_y = p1_y + 1;  p2_x = p2_x - 1;  settle_and_check;
        end
        p2_x = p1_x + 3;  p2_y = p1_y + 2;  settle_and_check;   // P2 jumps onto P1 (overlap)
        for (k = 0; k < 6; k = k + 1) begin                // P2 slides away again
            p2_x = p2_x + 1;  settle_and_check;
        end

        $display("%0d updates checked", updates);
        if (flicker != 0) $display("FLICKER: %0d path writes landed on a player", flicker);
        if (errors == 0 && flicker == 0) $display("PLAYER_DRAW PASS: no flicker, no trails");
        else                             $display("PLAYER_DRAW FAIL");
        $stop;
    end
endmodule
