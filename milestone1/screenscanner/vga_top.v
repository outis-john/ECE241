// vga_top.v  -  Milestone 1: maze from screenscanner + test of tile_painter.
//   KEY[0]   : reset (redraws the maze)
//   KEY[1]   : press to paint one tile
//   SW[4:0]  : tile column tx (0..19)
//   SW[8:5]  : tile row    ty (0..14)
//   SW[9]    : colour  (0 = red, 1 = blue)
//   LEDR[0]  : maze finished, LEDR[1] : painter busy
module vga_top (
    input        CLOCK_50,
    input  [3:0] KEY,
    input  [9:0] SW,
    output [9:0] LEDR,
    output [7:0] VGA_R,
    output [7:0] VGA_G,
    output [7:0] VGA_B,
    output       VGA_HS,
    output       VGA_VS,
    output       VGA_BLANK_N,
    output       VGA_SYNC_N,
    output       VGA_CLK
);
    wire resetn = KEY[0];

    // ---------------- screen scanner (draws the maze once) ----------------
    wire [8:0] sx;
    wire [7:0] sy;
    wire [8:0] scolor;
    wire       swrite;
    wire       maze_done;

    screenscanner scan (
        .clk(CLOCK_50),
        .resetn(resetn),
        .x_out(sx),
        .y_out(sy),
        .color_out(scolor),
        .write_out(swrite),
        .done(maze_done)
    );

    // ---------------- KEY[1] -> one-clock start pulse ----------------
    // KEY is 0 while pressed. Remember last clock's value and fire only on
    // the clock where it changes from released to pressed.
    reg key1_prev;
    always @(posedge CLOCK_50) begin
        if (!resetn) key1_prev <= 1'b1;
        else         key1_prev <= KEY[1];
    end
    wire paint_start = key1_prev & ~KEY[1] & maze_done;

    // ---------------- tile painter (draws one 16x16 tile) ----------------
    wire [8:0] tpx;
    wire [7:0] tpy;
    wire [8:0] tpcolor;
    wire       tpwrite;
    wire       tp_busy, tp_done;

    tile_painter painter (
        .clk(CLOCK_50),
        .resetn(resetn),
        .start(paint_start),
        .tx(SW[4:0]),
        .ty(SW[8:5]),
        .color_in(SW[9] ? 9'b000_000_111 : 9'b111_000_000),   // blue : red
        .x_out(tpx),
        .y_out(tpy),
        .color_out(tpcolor),
        .write_out(tpwrite),
        .busy(tp_busy),
        .done(tp_done)
    );

    // ---------------- mux: who drives the VGA adapter ----------------
    // Before the maze is finished the screen scanner draws; afterwards the painter.
    wire [8:0] vx     = maze_done ? tpx     : sx;
    wire [7:0] vy     = maze_done ? tpy     : sy;
    wire [8:0] vcolor = maze_done ? tpcolor : scolor;
    wire       vwrite = maze_done ? tpwrite : swrite;

    vga_adapter VGA (
        .resetn(resetn),
        .clock(CLOCK_50),
        .color(vcolor),
        .x(vx),
        .y(vy),
        .write(vwrite),
        .VGA_R(VGA_R), .VGA_G(VGA_G), .VGA_B(VGA_B),
        .VGA_HS(VGA_HS), .VGA_VS(VGA_VS),
        .VGA_BLANK_N(VGA_BLANK_N), .VGA_SYNC_N(VGA_SYNC_N),
        .VGA_CLK(VGA_CLK)
    );
    defparam VGA.RESOLUTION       = "320x240";
    defparam VGA.COLOR_DEPTH      = 9;
    defparam VGA.BACKGROUND_IMAGE = "black_320_9.mif";

    assign LEDR[0]   = maze_done;
    assign LEDR[1]   = tp_busy;
    assign LEDR[9:2] = 8'd0;
endmodule
