// tb_screenscanner.v - ModelSim testbench for screenscanner (with the real maze_rom).
// It plays the role of the VGA adapter: every pixel the scanner writes is stored,
// checked against the maze, and at the end the whole screen is saved as an image
// file "screen.bmp" that you can open in any image viewer.
//
// Checks:
//   - every write has the right colour for its tile (wall / path)  -> catches ROM-delay bugs
//   - exactly 320 x 240 = 76800 pixels are written, each one once
//   - done goes high at the end and writing stops
// Needs in the simulation folder: maze.mif (for maze_rom) and maze_tiles.txt (expected tiles).
`timescale 1ns / 1ns
`include "params.vh"

module tb_screenscanner;
    reg        clk = 1'b0;
    reg        resetn = 1'b0;
    wire [8:0] x_out;
    wire [7:0] y_out;
    wire [8:0] color_out;
    wire       write_out;
    wire       done;

    always #10 clk = ~clk;             // 50 MHz

    screenscanner dut (
        .clk(clk), .resetn(resetn),
        .x_out(x_out), .y_out(y_out),
        .color_out(color_out), .write_out(write_out),
        .done(done)
    );

    // ---------- expected maze and the "screen" ----------
    reg [1:0] tiles  [0:511];          // same data as maze.mif, address = {ty, tx}
    reg [8:0] screen [0:76799];        // what the scanner wrote, address = y*320 + x
    reg       hit    [0:76799];        // has this pixel been written?
    integer   writes = 0, errors = 0, repeats = 0, i;
    reg [8:0] expected;

    initial begin
        $readmemb("maze_tiles.txt", tiles);
        for (i = 0; i < 76800; i = i + 1) begin
            screen[i] = 9'd0;
            hit[i]    = 1'b0;
        end
    end

    // act like the VGA adapter: record and check every write
    always @(posedge clk) begin
        if (resetn && write_out) begin
            expected = (tiles[{y_out[7:4], x_out[8:4]}] == 2'b01) ? `COLOR_WALL : `COLOR_PATH;
            if (color_out !== expected) begin
                if (errors < 10)
                    $display("WRONG colour at (%0d,%0d): got %b, expected %b",
                             x_out, y_out, color_out, expected);
                errors = errors + 1;
            end
            if (hit[y_out*320 + x_out]) repeats = repeats + 1;
            hit[y_out*320 + x_out]    = 1'b1;
            screen[y_out*320 + x_out] = color_out;
            writes = writes + 1;
        end
    end

    // ---------- save the screen as a 320x240 24-bit BMP ----------
    integer f, r, c;
    reg [8:0] px;
    task put16(input [15:0] v); begin $fwrite(f, "%c%c", v[7:0], v[15:8]); end endtask
    task put32(input [31:0] v); begin $fwrite(f, "%c%c%c%c", v[7:0], v[15:8], v[23:16], v[31:24]); end endtask

    task save_bmp;
        begin
            f = $fopen("screen.bmp", "wb");
            $fwrite(f, "BM");
            put32(54 + 320*240*3); put32(0); put32(54);       // file header
            put32(40); put32(320); put32(240);                 // info header
            put16(1); put16(24); put32(0); put32(320*240*3);
            put32(2835); put32(2835); put32(0); put32(0);
            for (r = 239; r >= 0; r = r - 1)                   // BMP rows go bottom-up
                for (c = 0; c < 320; c = c + 1) begin
                    px = screen[r*320 + c];                    // {RRR,GGG,BBB} -> 0..252
                    $fwrite(f, "%c%c%c", px[2:0]*8'd36, px[5:3]*8'd36, px[8:6]*8'd36); // B,G,R
                end
            $fclose(f);
        end
    endtask

    // ---------- run ----------
    initial begin
        #40 resetn = 1'b1;
        wait (done == 1'b1);
        @(posedge clk); @(posedge clk); @(posedge clk);       // let the last delayed write finish
        $display("done went high at %0t ns", $time);
        if (writes != 76800) begin
            $display("Expected 76800 pixel writes, got %0d", writes);
            errors = errors + 1;
        end
        if (repeats != 0) begin
            $display("%0d pixels were written more than once", repeats);
            errors = errors + 1;
        end
        if (write_out !== 1'b0) begin
            $display("write_out is still high after done");
            errors = errors + 1;
        end
        save_bmp;
        $display("Screen saved to screen.bmp (open it to see the maze)");
        if (errors == 0) $display("SCREENSCANNER PASS: 76800 pixels, all colours correct");
        else             $display("SCREENSCANNER FAIL: %0d problem(s)", errors);
        $stop;
    end
endmodule
