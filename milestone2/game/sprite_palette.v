// sprite_palette.v - turns a 4-bit sprite colour code (from player_sprites.mif) into a
// 9-bit {RRR,GGG,BBB} colour. Code 0 is the background: drawn in the path colour.
// team = 0 for P1 (red shirt), 1 for P2 (blue shirt). Everything else is shared.
`include "params.vh"

module sprite_palette (code, team, color);
    input      [3:0] code;
    input            team;
    output reg [8:0] color;
    always @(*) begin
        case (code)
            4'd0 : color = `COLOR_PATH;          // background
            4'd1 : color = 9'b000_000_000;   // K
            4'd2 : color = 9'b001_001_001;   // D
            4'd3 : color = 9'b001_001_001;   // k
            4'd4 : color = 9'b010_001_001;   // b
            4'd5 : color = 9'b001_001_001;   // g
            4'd6 : color = 9'b010_010_001;   // n
            4'd7 : color = 9'b011_010_001;   // o
            4'd8 : color = 9'b010_010_010;   // G
            4'd9 : color = team ? 9'b010_010_100    // U shirt: P2 blue
                             : 9'b100_001_001;   //    P1 red
            4'd10: color = 9'b011_011_011;   // h
            4'd11: color = 9'b100_100_100;   // H
            4'd12: color = team ? 9'b010_011_101    // B shirt: P2 blue
                             : 9'b110_010_010;   //    P1 red
            4'd13: color = 9'b101_100_100;   // s
            4'd14: color = 9'b110_101_100;   // S
            default: color = `COLOR_PATH;
        endcase
    end
endmodule
