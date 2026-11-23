// tb_player_move.v - self-checking ModelSim testbench for player_move (smooth movement).
// Drives the keys and the tick directly (no keyboard needed) and checks positions.
// Compile with maze_rom_sim.v (reads maze_tiles.txt) - see player_move.do.
//
// P1 starts at (16,16) = tile (1,1); P2 at (288,208) = tile (18,13). Each tick = 1 pixel.
//  1. hold D 16 ticks                      -> P1 slides right to (32,16)
//  2. also press S (newest) 16 ticks       -> down is a wall at (2,2): keeps going right -> (48,16)
//  3. 16 ticks                             -> (3,2) is a wall too: keeps going right -> (64,16)
//  4. 16 ticks                             -> (4,2) is open: turns down -> (64,32)
//  5. hold only S 8 ticks                  -> mid-slide (64,40)
//  6. release all keys, 8 ticks            -> finishes the tile and stops at (64,48)
//  7. 8 more ticks, no keys                -> stays at (64,48)
//  8. hold S 16 ticks (tile below is wall) -> no move, facing DOWN
//  9. hold D 8 ticks                       -> (72,48), mid-slide
// 10. release D, hold A 8 ticks            -> reverses at once, back to (64,48)
// 11. hold A 16 ticks                      -> (48,48)
// 12. P2 never moved; hold UP arrow 16 ticks -> P2 (288,192)
`timescale 1ns / 1ns
module tb_player_move;
    reg clk = 1'b0, reset = 1'b1, tick = 1'b0;
    reg w = 0, a = 0, s = 0, d = 0, up = 0, left = 0, down = 0, right = 0;
    wire [8:0] p1_x, p2_x;
    wire [7:0] p1_y, p2_y;
    wire [1:0] p1_facing, p2_facing;

    always #10 clk = ~clk;

    player_move dut (
        .clk(clk), .reset(reset), .tick(tick),
        .w(w), .a(a), .s(s), .d(d),
        .up(up), .left(left), .down(down), .right(right),
        .p1_x(p1_x), .p1_y(p1_y), .p2_x(p2_x), .p2_y(p2_y),
        .p1_facing(p1_facing), .p2_facing(p2_facing)
    );

    integer errors = 0;

    // n game ticks: one-clock tick pulse, then enough clocks for the FSM to finish
    task ticks(input integer n);
        integer i;
        begin
            for (i = 0; i < n; i = i + 1) begin
                @(negedge clk) tick = 1'b1;
                @(negedge clk) tick = 1'b0;
                repeat (30) @(negedge clk);
            end
        end
    endtask

    task check(input [8:0] ex, input [7:0] ey, input [8:0] gx, input [7:0] gy,
               input [8*24-1:0] what);
        begin
            if (gx == ex && gy == ey)
                $display("%t  OK    %0s: (%0d,%0d)", $time, what, gx, gy);
            else begin
                $display("%t  WRONG %0s: got (%0d,%0d), expected (%0d,%0d)",
                         $time, what, gx, gy, ex, ey);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        repeat (3) @(negedge clk);
        reset = 1'b0;
        repeat (3) @(negedge clk);
        check(16, 16, p1_x, p1_y, "P1 spawn");
        check(288, 208, p2_x, p2_y, "P2 spawn");

        d = 1;          ticks(16);  check(32, 16, p1_x, p1_y, "1 slide right");
        s = 1;          ticks(16);  check(48, 16, p1_x, p1_y, "2 down blocked, go on");
                        ticks(16);  check(64, 16, p1_x, p1_y, "3 down blocked, go on");
                        ticks(16);  check(64, 32, p1_x, p1_y, "4 turned down");
        d = 0;          ticks(8);   check(64, 40, p1_x, p1_y, "5 mid-slide");
        s = 0;          ticks(8);   check(64, 48, p1_x, p1_y, "6 finished tile");
                        ticks(8);   check(64, 48, p1_x, p1_y, "7 stopped");
        s = 1;          ticks(16);  check(64, 48, p1_x, p1_y, "8 wall below");
        if (p1_facing !== 2'd2) begin
            $display("WRONG facing after pushing into wall: %0d (expected 2 = DOWN)", p1_facing);
            errors = errors + 1;
        end
        s = 0; d = 1;   ticks(8);   check(72, 48, p1_x, p1_y, "9 mid-slide right");
        d = 0; a = 1;   ticks(8);   check(64, 48, p1_x, p1_y, "10 reversed");
                        ticks(16);  check(48, 48, p1_x, p1_y, "11 slide left");
        a = 0;
        check(288, 208, p2_x, p2_y, "P2 did not move");
        up = 1;         ticks(16);  check(288, 192, p2_x, p2_y, "12 P2 up");
        up = 0;

        if (errors == 0) $display("PLAYER_MOVE PASS");
        else             $display("PLAYER_MOVE FAIL: %0d problem(s)", errors);
        $stop;
    end
endmodule
