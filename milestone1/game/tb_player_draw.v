// tb_player_draw.v - self-checking ModelSim testbench for player_draw + tile_painter.
// It pretends to be the screen scanner (maze_done) and Sam's gameLogic (player
// positions), lets player_draw + tile_painter run, and checks every tile they paint.
// At the end the transcript prints  "ALL 12 PAINTS CORRECT - PASS"  or the errors.
//
//   0.1 us: maze is done          -> draw P1 red at (1,1), P2 blue at (18,13)
//   12 us : P1 moves right (2,1)  -> erase (1,1), draw P1 (2,1), draw P2 (18,13)
//   30 us : P2 moves up (18,12)   -> erase (18,13), draw P1 (2,1), draw P2 (18,12)
//   48 us : both move at once     -> erase (2,1), erase (18,12), draw (3,1), draw (18,11)
`timescale 1ns / 1ns
module tb_player_draw;
    reg        clk = 1'b0;
    reg        resetn = 1'b0;
    reg        maze_done = 1'b0;
    reg  [8:0] p1_x = 9'd16,  p2_x = 9'd288;
    reg  [7:0] p1_y = 8'd16,  p2_y = 8'd208;

    wire       paint_start, paint_done, paint_busy;
    wire [4:0] paint_tx;
    wire [3:0] paint_ty;
    wire [8:0] paint_color;
    wire [8:0] x_out, color_out;
    wire [7:0] y_out;
    wire       write_out;

    always #10 clk = ~clk;                 // 50 MHz clock (20 ns period)

    player_draw dut (
        .clk(clk), .resetn(resetn), .maze_done(maze_done),
        .p1_x(p1_x), .p1_y(p1_y), .p2_x(p2_x), .p2_y(p2_y),
        .paint_done(paint_done),
        .paint_start(paint_start), .paint_tx(paint_tx), .paint_ty(paint_ty),
        .paint_color(paint_color)
    );

    tile_painter painter (
        .clk(clk), .resetn(resetn), .start(paint_start),
        .tx(paint_tx), .ty(paint_ty), .color_in(paint_color),
        .x_out(x_out), .y_out(y_out), .color_out(color_out),
        .write_out(write_out), .busy(paint_busy), .done(paint_done)
    );

    // ---------------- expected paints, in order ----------------
    localparam RED  = 9'b111_000_000, BLUE = 9'b000_000_111, PATH = 9'b101_101_101;
    reg [4:0] exp_tx  [0:11];
    reg [3:0] exp_ty  [0:11];
    reg [8:0] exp_col [0:11];
    initial begin
        exp_tx[0]=1;  exp_ty[0]=1;  exp_col[0]=RED;     // first draw
        exp_tx[1]=18; exp_ty[1]=13; exp_col[1]=BLUE;
        exp_tx[2]=1;  exp_ty[2]=1;  exp_col[2]=PATH;    // P1 moved
        exp_tx[3]=2;  exp_ty[3]=1;  exp_col[3]=RED;
        exp_tx[4]=18; exp_ty[4]=13; exp_col[4]=BLUE;
        exp_tx[5]=18; exp_ty[5]=13; exp_col[5]=PATH;    // P2 moved
        exp_tx[6]=2;  exp_ty[6]=1;  exp_col[6]=RED;
        exp_tx[7]=18; exp_ty[7]=12; exp_col[7]=BLUE;
        exp_tx[8]=2;  exp_ty[8]=1;  exp_col[8]=PATH;    // both moved
        exp_tx[9]=18; exp_ty[9]=12; exp_col[9]=PATH;
        exp_tx[10]=3; exp_ty[10]=1; exp_col[10]=RED;
        exp_tx[11]=18;exp_ty[11]=11;exp_col[11]=BLUE;
    end

    integer n = 0;          // number of paints seen
    integer errors = 0;
    integer writes = 0;     // pixels written by tile_painter

    // check each paint request as it happens
    always @(posedge clk) begin
        if (paint_start) begin
            if (n < 12 && paint_tx == exp_tx[n] && paint_ty == exp_ty[n] && paint_color == exp_col[n])
                $display("%t ns  paint %0d: tile (%0d,%0d) colour %b   OK",
                         $time, n, paint_tx, paint_ty, paint_color);
            else begin
                $display("%t ns  paint %0d: tile (%0d,%0d) colour %b   WRONG",
                         $time, n, paint_tx, paint_ty, paint_color);
                errors = errors + 1;
            end
            n = n + 1;
        end
        if (write_out) writes = writes + 1;
    end

    // stimulus: what the scanner and gameLogic would do
    initial begin
        #40    resetn = 1'b1;
        #60    maze_done = 1'b1;
        #11900 p1_x = 9'd32;                              // P1 right
        #18000 p2_y = 8'd192;                             // P2 up
        #18000 begin p1_x = 9'd48; p2_y = 8'd176; end     // both move
        #25000;
        if (n != 12) begin
            $display("Expected 12 paints, saw %0d", n);
            errors = errors + 1;
        end
        if (writes != 12*256) begin
            $display("Expected %0d pixel writes, saw %0d", 12*256, writes);
            errors = errors + 1;
        end
        if (errors == 0) $display("ALL 12 PAINTS CORRECT - PASS");
        else             $display("FAIL: %0d problem(s)", errors);
        $stop;
    end
endmodule
