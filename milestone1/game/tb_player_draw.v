// tb_player_draw.v - ModelSim testbench for player_draw + tile_painter.
// Fakes the screen scanner (maze_done) and Sam's gameLogic (player positions),
// then checks what gets painted.
//   0 us  : reset. P1 at pixel (16,16) = tile (1,1), P2 at (288,208) = tile (18,13)
//   0.1 us: maze_done = 1           -> draw P1 red at (1,1), P2 blue at (18,13)
//   12 us : P1 moves right to (2,1) -> erase (1,1), draw P1 (2,1), draw P2 (18,13)
//   30 us : P2 moves up to (18,12)  -> erase (18,13), draw P1 (2,1), draw P2 (18,12)
//   48 us : both move at once       -> erase (2,1), erase (18,12), draw (3,1), draw (18,11)
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

    // print every tile paint request in the transcript
    always @(posedge clk)
        if (paint_start)
            $display("%t ns  paint tile (%0d,%0d) colour %b", $time, paint_tx, paint_ty, paint_color);

    initial begin
        #40    resetn = 1'b1;
        #60    maze_done = 1'b1;
        #11900 p1_x = 9'd32;                      // P1 right: tile (2,1)
        #18000 p2_y = 8'd192;                     // P2 up:    tile (18,12)
        #18000 begin p1_x = 9'd48; p2_y = 8'd176; end   // both move
        #25000 $display("Test finished");
        $stop;
    end
endmodule
