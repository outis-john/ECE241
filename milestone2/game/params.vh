// params.vh - colours shared by the drawing modules (COLOR_DEPTH = 9: {RRR,GGG,BBB})
`ifndef PARAMS_VH
`define PARAMS_VH
`define COLOR_WALL  9'b010_010_010   // dark grey
`define COLOR_PATH  9'b101_101_101   // light grey (also used to erase players)
`define COLOR_P1    9'b111_000_000   // red
`define COLOR_P2    9'b000_000_111   // blue
`endif
