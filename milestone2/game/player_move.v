// player_move.v  (Milestone 2: smooth movement)
// Moves both players ONE PIXEL per game tick instead of jumping a whole tile.
//
// Rules (Pac-Man style):
//   - Decisions are made only when a player is lined up with a tile
//     (x and y are multiples of 16). Then:
//        1. if the wanted direction's next tile is a path -> turn / start moving that way
//        2. else if still moving and that key is still held, and the tile ahead is
//           a path -> keep going straight
//        3. else -> stop
//   - Between tiles the player just slides 1 pixel per tick until it lines up again,
//     so it can never get stuck on a wall corner.
//   - The "wanted" direction is the most recently pressed key that is still held, so a
//     turn can be pressed early: the player takes the first opening it reaches.
//   - Pressing the opposite direction reverses immediately, even mid-slide.
//
// Positions are the top-left pixel of the player's 16x16 cell (multiples of 16 when
// lined up), exactly like Milestone 1, so the wall check is the same ROM lookup.
// Directions: UP = 0, LEFT = 1, DOWN = 2, RIGHT = 3 (opposite = dir ^ 2'b10).
module player_move (
    input            clk,
    input            reset,          // active high
    input            tick,           // one pulse per movement step (1 pixel)
    input            w, a, s, d,     // player 1 keys held
    input            up, left, down, right,   // player 2 keys held
    output reg [8:0] p1_x, p2_x,
    output reg [7:0] p1_y, p2_y,
    output reg [1:0] p1_facing, p2_facing
);
    localparam UP = 2'd0, LEFT = 2'd1, DOWN = 2'd2, RIGHT = 2'd3;

    parameter [8:0] P1_SPAWN_X = 9'd16;    // tile (1,1)
    parameter [7:0] P1_SPAWN_Y = 8'd16;
    parameter [8:0] P2_SPAWN_X = 9'd288;   // tile (18,13)
    parameter [7:0] P2_SPAWN_Y = 8'd208;

    // keys as a 4-bit vector indexed by direction: keys[UP], keys[LEFT], ...
    wire [3:0] k1 = {d, s, a, w};
    wire [3:0] k2 = {right, down, left, up};

    // ---------------- wanted direction (most recently pressed, still held) ----------------
    reg [3:0] k1_prev, k2_prev;
    reg [1:0] want1, want2;
    reg       want1_v, want2_v;

    // lowest-numbered held key (fallback when the newest key was released)
    function [1:0] first_key;
        input [3:0] k;
        begin
            if      (k[0]) first_key = 2'd0;
            else if (k[1]) first_key = 2'd1;
            else if (k[2]) first_key = 2'd2;
            else           first_key = 2'd3;
        end
    endfunction

    wire [3:0] new1 = k1 & ~k1_prev;     // keys pressed this clock
    wire [3:0] new2 = k2 & ~k2_prev;

    always @(posedge clk) begin
        if (reset) begin
            k1_prev <= 4'b0;  k2_prev <= 4'b0;
            want1   <= RIGHT; want2   <= LEFT;
            want1_v <= 1'b0;  want2_v <= 1'b0;
        end
        else begin
            k1_prev <= k1;
            k2_prev <= k2;
            if (|new1)                          begin want1 <= first_key(new1); want1_v <= 1'b1; end
            else if (want1_v && !k1[want1])     want1_v <= 1'b0;
            if (|new2)                          begin want2 <= first_key(new2); want2_v <= 1'b1; end
            else if (want2_v && !k2[want2])     want2_v <= 1'b0;
        end
    end

    // desired direction right now (valid = some direction key is held)
    wire       des1_v = |k1;
    wire [1:0] des1   = (want1_v && k1[want1]) ? want1 : first_key(k1);
    wire       des2_v = |k2;
    wire [1:0] des2   = (want2_v && k2[want2]) ? want2 : first_key(k2);

    // ---------------- maze ROM (same file and address as Milestone 1) ----------------
    reg  [8:0] chk_x;                    // tile being checked (pixel position)
    reg  [7:0] chk_y;
    wire [1:0] rom_tile;                 // 00 = path, 01 = wall
    maze_rom rom0 (.address({chk_y[7:4], chk_x[8:4]}), .clock(clk), .q(rom_tile));

    // ---------------- movement state of each player ----------------
    reg [1:0] cur1, cur2;                // direction of motion
    reg       mov1, mov2;                // 1 while moving
    reg [1:0] chk_dir;                   // direction being checked
    reg       cp;                        // current player: 0 = P1, 1 = P2

    // values of the player being processed
    wire [8:0] sx    = cp ? p2_x  : p1_x;
    wire [7:0] sy    = cp ? p2_y  : p1_y;
    wire [1:0] scur  = cp ? cur2  : cur1;
    wire       smov  = cp ? mov2  : mov1;
    wire [3:0] skeys = cp ? k2    : k1;
    wire       sdes_v = cp ? des2_v : des1_v;
    wire [1:0] sdes   = cp ? des2   : des1;
    wire       aligned = (sx[3:0] == 4'd0) && (sy[3:0] == 4'd0);

    localparam S_IDLE = 3'd0, S_DECIDE = 3'd1, S_READ1 = 3'd2, S_CHECK1 = 3'd3,
               S_READ2 = 3'd4, S_CHECK2 = 3'd5, S_MOVE = 3'd6, S_SWITCH = 3'd7;
    reg [2:0] state;

    always @(posedge clk) begin
        if (reset) begin
            state <= S_IDLE;
            cp    <= 1'b0;
            p1_x  <= P1_SPAWN_X;  p1_y <= P1_SPAWN_Y;
            p2_x  <= P2_SPAWN_X;  p2_y <= P2_SPAWN_Y;
            cur1  <= RIGHT;       cur2 <= LEFT;
            mov1  <= 1'b0;        mov2 <= 1'b0;
            p1_facing <= RIGHT;   p2_facing <= LEFT;
            chk_x <= 9'd0;  chk_y <= 8'd0;  chk_dir <= UP;
        end
        else begin
            case (state)
                S_IDLE: begin
                    cp <= 1'b0;
                    if (tick) state <= S_DECIDE;
                end

                S_DECIDE: begin
                    if (!aligned) begin
                        // between tiles: keep sliding; allow an instant reverse
                        if (sdes_v && sdes == (scur ^ 2'b10)) begin
                            if (cp) begin cur2 <= sdes; p2_facing <= sdes; end
                            else    begin cur1 <= sdes; p1_facing <= sdes; end
                        end
                        state <= smov ? S_MOVE : S_SWITCH;
                    end
                    else if (sdes_v) begin
                        // lined up with a tile and a key is held: check the wanted tile
                        chk_dir <= sdes;
                        chk_x <= (sdes == LEFT)  ? sx - 9'd16 :
                                 (sdes == RIGHT) ? sx + 9'd16 : sx;
                        chk_y <= (sdes == UP)    ? sy - 8'd16 :
                                 (sdes == DOWN)  ? sy + 8'd16 : sy;
                        state <= S_READ1;
                    end
                    else begin
                        // lined up and no key held: stop here
                        if (cp) mov2 <= 1'b0; else mov1 <= 1'b0;
                        state <= S_SWITCH;
                    end
                end

                S_READ1: state <= S_CHECK1;          // ROM reads the address this clock

                S_CHECK1: begin
                    if (rom_tile == 2'b00) begin     // wanted tile is a path: go that way
                        if (cp) begin cur2 <= chk_dir; mov2 <= 1'b1; p2_facing <= chk_dir; end
                        else    begin cur1 <= chk_dir; mov1 <= 1'b1; p1_facing <= chk_dir; end
                        state <= S_MOVE;
                    end
                    else if (smov && skeys[scur] && scur != chk_dir) begin
                        // wanted tile is a wall: try to keep going straight
                        chk_x <= (scur == LEFT)  ? sx - 9'd16 :
                                 (scur == RIGHT) ? sx + 9'd16 : sx;
                        chk_y <= (scur == UP)    ? sy - 8'd16 :
                                 (scur == DOWN)  ? sy + 8'd16 : sy;
                        state <= S_READ2;
                    end
                    else begin                       // blocked: stop, but face the wall (to aim)
                        if (cp) begin mov2 <= 1'b0; p2_facing <= chk_dir; end
                        else    begin mov1 <= 1'b0; p1_facing <= chk_dir; end
                        state <= S_SWITCH;
                    end
                end

                S_READ2: state <= S_CHECK2;

                S_CHECK2: begin
                    if (rom_tile == 2'b00)
                        state <= S_MOVE;             // straight ahead is open: keep going
                    else begin
                        if (cp) mov2 <= 1'b0; else mov1 <= 1'b0;
                        state <= S_SWITCH;
                    end
                end

                S_MOVE: begin                        // one pixel in the current direction
                    if (cp) begin
                        case (cur2)
                            UP:    p2_y <= p2_y - 8'd1;
                            DOWN:  p2_y <= p2_y + 8'd1;
                            LEFT:  p2_x <= p2_x - 9'd1;
                            RIGHT: p2_x <= p2_x + 9'd1;
                        endcase
                    end
                    else begin
                        case (cur1)
                            UP:    p1_y <= p1_y - 8'd1;
                            DOWN:  p1_y <= p1_y + 8'd1;
                            LEFT:  p1_x <= p1_x - 9'd1;
                            RIGHT: p1_x <= p1_x + 9'd1;
                        endcase
                    end
                    state <= S_SWITCH;
                end

                S_SWITCH: begin
                    if (cp == 1'b0) begin cp <= 1'b1; state <= S_DECIDE; end
                    else            begin cp <= 1'b0; state <= S_IDLE;   end
                end

                default: state <= S_IDLE;
            endcase
        end
    end
endmodule
