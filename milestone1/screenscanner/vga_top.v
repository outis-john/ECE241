// vga_top.v  -  Milestone 1 step: draw the maze with screenscanner.
module vga_top (
    input        CLOCK_50,
    input  [3:0] KEY,
    output [7:0] VGA_R,
    output [7:0] VGA_G,
    output [7:0] VGA_B,
    output       VGA_HS,
    output       VGA_VS,
    output       VGA_BLANK_N,
    output       VGA_SYNC_N,
    output       VGA_CLK
);
    // wires from the screen scanner to the VGA adapter
    wire [8:0] sx;
    wire [7:0] sy;
    wire [8:0] scolor;
    wire       swrite;
    wire       maze_done;

    screenscanner scan (
        .clk(CLOCK_50),
        .resetn(KEY[0]),
        .x_out(sx),
        .y_out(sy),
        .color_out(scolor),
        .write_out(swrite),
        .done(maze_done)
    );

    vga_adapter VGA (
        .resetn(KEY[0]),
        .clock(CLOCK_50),
        .color(scolor),
        .x(sx),
        .y(sy),
        .write(swrite),
        .VGA_R(VGA_R), .VGA_G(VGA_G), .VGA_B(VGA_B),
        .VGA_HS(VGA_HS), .VGA_VS(VGA_VS),
        .VGA_BLANK_N(VGA_BLANK_N), .VGA_SYNC_N(VGA_SYNC_N),
        .VGA_CLK(VGA_CLK)
    );
    defparam VGA.RESOLUTION       = "320x240";
    defparam VGA.COLOR_DEPTH      = 9;
    defparam VGA.BACKGROUND_IMAGE = "black_320_9.mif";
endmodule
