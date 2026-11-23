// maze_rom_sim.v - SIMULATION-ONLY copy of maze_rom (do NOT add to Quartus).
// Use it in ModelSim instead of maze_rom.v only if the altera_mf library is missing.
// Same ports and timing as the Quartus ROM: data comes out one clock after the address.
module maze_rom (address, clock, q);
    input  [8:0] address;
    input        clock;
    output reg [1:0] q;
    reg [1:0] mem [0:511];
    initial $readmemb("maze_tiles.txt", mem);
    always @(posedge clock)
        q <= mem[address];
endmodule
