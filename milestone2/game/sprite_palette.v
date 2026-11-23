// sprite_palette.v - turns a 4-bit sprite colour code (from player_sprites.mif)
// into a 9-bit {RRR,GGG,BBB} colour. Each character has its own palette.
//   player = 0: P1 wizard (red robe and hat)
//   player = 1: P2 old man (blue shirt)
// Code 0 is the background around the character: drawn in the path colour.
`include "params.vh"

module sprite_palette (code, player, color);
    input      [3:0] code;
    input            player;
    output reg [8:0] color;
    always @(*) begin
        if (code == 4'd0)
            color = `COLOR_PATH;
        else if (player == 1'b0) begin      // wizard
            case (code)
                4'd1 : color = 9'b000_000_000;   // K
                4'd2 : color = 9'b010_001_001;   // A
                4'd3 : color = 9'b100_001_001;   // B
                4'd4 : color = 9'b101_001_001;   // C
                4'd5 : color = 9'b110_010_010;   // E
                4'd6 : color = 9'b110_110_110;   // V
                4'd7 : color = 9'b111_111_111;   // W
                4'd8 : color = 9'b110_101_100;   // S
                4'd9 : color = 9'b111_110_101;   // T
                4'd10: color = 9'b011_011_011;   // U
                4'd11: color = 9'b010_010_001;   // P
                4'd12: color = 9'b010_010_010;   // Q
                4'd13: color = 9'b011_011_010;   // R
                default: color = `COLOR_PATH;
            endcase
        end else begin                      // old man
            case (code)
                4'd1 : color = 9'b000_000_000;   // K
                4'd2 : color = 9'b001_001_001;   // D
                4'd3 : color = 9'b001_001_001;   // k
                4'd4 : color = 9'b010_001_001;   // b
                4'd5 : color = 9'b001_001_001;   // g
                4'd6 : color = 9'b010_010_001;   // n
                4'd7 : color = 9'b011_010_001;   // o
                4'd8 : color = 9'b010_010_010;   // G
                4'd9 : color = 9'b010_010_100;   // U
                4'd10: color = 9'b011_011_011;   // h
                4'd11: color = 9'b100_100_100;   // H
                4'd12: color = 9'b010_011_101;   // B
                4'd13: color = 9'b101_100_100;   // s
                4'd14: color = 9'b110_101_100;   // S
                default: color = `COLOR_PATH;
            endcase
        end
    end
endmodule
