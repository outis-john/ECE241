// game_top.v - Milestone 2: maze + two 8x8 players moving smoothly (1 pixel per tick).
//   KEY[0]          : reset (game restarts, maze is redrawn)
//   WASD            : player 1 (red)     arrow keys : player 2 (blue)
//   LEDR[9:0]       : keys held (from gameLogic)
module game_top (
    input        CLOCK_50,
    input  [3:0] KEY,
    inout        PS2_CLK,
    inout        PS2_DAT,
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

    // ---------------- game logic (Sam): keyboard, movement, walls ----------------
    wire [8:0] p1_x, p2_x;          // player positions in pixels
    wire [7:0] p1_y, p2_y;
    wire [1:0] p1_facing, p2_facing;
    wire       tick;

    gameLogic GL0 (
        .CLOCK_50(CLOCK_50),
        .KEY(KEY),
        .PS2_CLK(PS2_CLK),
        .PS2_DAT(PS2_DAT),
        .LEDR(LEDR),
        .p1_x(p1_x), .p1_y(p1_y),
        .p2_x(p2_x), .p2_y(p2_y),
        .p1_facing(p1_facing), .p2_facing(p2_facing),
        .tick(tick)
    );

    // ---------------- screen scanner (John): draws the maze once ----------------
    wire [8:0] sx;
    wire [7:0] sy;
    wire [8:0] scolor;
    wire       swrite;
    wire       maze_done;

    screenscanner scan (
        .clk(CLOCK_50),
        .resetn(resetn),
        .x_out(sx), .y_out(sy),
        .color_out(scolor),
        .write_out(swrite),
        .done(maze_done)
    );

    // ---------------- player drawing (John): erase / redraw 8x8 players ----------------
    wire       paint_start, paint_done, paint_busy;
    wire [8:0] paint_x;
    wire [7:0] paint_y;
    wire [8:0] paint_color;
    wire       excl_en;
    wire [8:0] e1x, e2x;
    wire [7:0] e1y, e2y;

    player_draw pdraw (
        .clk(CLOCK_50),
        .resetn(resetn),
        .maze_done(maze_done),
        .p1_x(p1_x), .p1_y(p1_y),
        .p2_x(p2_x), .p2_y(p2_y),
        .paint_done(paint_done),
        .paint_start(paint_start),
        .paint_x(paint_x), .paint_y(paint_y),
        .paint_color(paint_color),
        .excl_en(excl_en),
        .e1x(e1x), .e1y(e1y), .e2x(e2x), .e2y(e2y)
    );

    // ---------------- box painter (John): draws one 8x8 box at any pixel ----------------
    wire [8:0] tpx;
    wire [7:0] tpy;
    wire [8:0] tpcolor;
    wire       tpwrite;

    box_painter painter (
        .clk(CLOCK_50),
        .resetn(resetn),
        .start(paint_start),
        .x0(paint_x), .y0(paint_y),
        .color_in(paint_color),
        .excl_en(excl_en),
        .e1x(e1x), .e1y(e1y), .e2x(e2x), .e2y(e2y),
        .x_out(tpx), .y_out(tpy),
        .color_out(tpcolor),
        .write_out(tpwrite),
        .busy(paint_busy),
        .done(paint_done)
    );

    // ---------------- mux: who drives the VGA adapter ----------------
    // The scanner owns the screen until the maze is done. Its last pixel is
    // written one clock after 'done' rises (because of the ROM delay), so it
    // keeps control while swrite is still high.
    wire use_scanner = ~maze_done | swrite;
    wire [8:0] vx     = use_scanner ? sx     : tpx;
    wire [7:0] vy     = use_scanner ? sy     : tpy;
    wire [8:0] vcolor = use_scanner ? scolor : tpcolor;
    wire       vwrite = use_scanner ? swrite : tpwrite;

    vga_adapter VGA (
        .resetn(resetn),
        .clock(CLOCK_50),
        .color(vcolor),
        .x(vx), .y(vy),
        .write(vwrite),
        .VGA_R(VGA_R), .VGA_G(VGA_G), .VGA_B(VGA_B),
        .VGA_HS(VGA_HS), .VGA_VS(VGA_VS),
        .VGA_BLANK_N(VGA_BLANK_N), .VGA_SYNC_N(VGA_SYNC_N),
        .VGA_CLK(VGA_CLK)
    );
    defparam VGA.RESOLUTION       = "320x240";
    defparam VGA.COLOR_DEPTH      = 9;
    defparam VGA.BACKGROUND_IMAGE = "black_320_9.mif";
endmodule
