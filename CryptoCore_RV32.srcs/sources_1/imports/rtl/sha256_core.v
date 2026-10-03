`timescale 1ns / 1ps

module sha256_core (
    input wire         clk,
    input wire         rst_n,
    input wire         start,
    input wire         init,
    input wire [255:0] state_in,
    input wire [511:0] block,
    output wire        ready,
    output reg         busy,
    output reg         done,
    output reg [255:0] digest
);
    localparam PHASE_IDLE     = 1'b0;
    localparam PHASE_COMPRESS = 1'b1;

    localparam H0 = 32'h6a09e667;
    localparam H1 = 32'hbb67ae85;
    localparam H2 = 32'h3c6ef372;
    localparam H3 = 32'ha54ff53a;
    localparam H4 = 32'h510e527f;
    localparam H5 = 32'h9b05688c;
    localparam H6 = 32'h1f83d9ab;
    localparam H7 = 32'h5be0cd19;

    // init=1 starts from the SHA-256 IV; init=0 uses state_in as {H0,H1,...,H7}.
    reg phase;
    reg [6:0] round;
    reg [31:0] w [0:15];
    reg [31:0] a;
    reg [31:0] b;
    reg [31:0] c;
    reg [31:0] d;
    reg [31:0] e;
    reg [31:0] f;
    reg [31:0] g;
    reg [31:0] h;
    reg [31:0] state0;
    reg [31:0] state1;
    reg [31:0] state2;
    reg [31:0] state3;
    reg [31:0] state4;
    reg [31:0] state5;
    reg [31:0] state6;
    reg [31:0] state7;
    reg        start_d;
    integer i;

    assign ready = (phase == PHASE_IDLE) && !start_d;

    wire start_pulse = start & ~start_d;
    wire [31:0] init_h0 = init ? H0 : state_in[255:224];
    wire [31:0] init_h1 = init ? H1 : state_in[223:192];
    wire [31:0] init_h2 = init ? H2 : state_in[191:160];
    wire [31:0] init_h3 = init ? H3 : state_in[159:128];
    wire [31:0] init_h4 = init ? H4 : state_in[127:96];
    wire [31:0] init_h5 = init ? H5 : state_in[95:64];
    wire [31:0] init_h6 = init ? H6 : state_in[63:32];
    wire [31:0] init_h7 = init ? H7 : state_in[31:0];

    wire [3:0] w_idx     = round[3:0];
    wire [3:0] w_idx_m2  = round[3:0] - 4'd2;
    wire [3:0] w_idx_m7  = round[3:0] - 4'd7;
    wire [3:0] w_idx_m15 = round[3:0] - 4'd15;
    wire [31:0] sched_word = (round < 7'd16) ? w[w_idx] :
        small_sigma1(w[w_idx_m2]) + w[w_idx_m7] +
        small_sigma0(w[w_idx_m15]) + w[w_idx];
    wire [31:0] t1 = h + big_sigma1(e) + ch(e, f, g) + k256(round) + sched_word;
    wire [31:0] t2 = big_sigma0(a) + maj(a, b, c);
    wire [31:0] next_a = t1 + t2;
    wire [31:0] next_b = a;
    wire [31:0] next_c = b;
    wire [31:0] next_d = c;
    wire [31:0] next_e = d + t1;
    wire [31:0] next_f = e;
    wire [31:0] next_g = f;
    wire [31:0] next_h = g;

    function [31:0] rotr;
        input [31:0] x;
        input integer n;
        begin
            rotr = (x >> n) | (x << (32-n));
        end
    endfunction

    function [31:0] ch;
        input [31:0] x;
        input [31:0] y;
        input [31:0] z;
        begin
            ch = (x & y) ^ ((~x) & z);
        end
    endfunction

    function [31:0] maj;
        input [31:0] x;
        input [31:0] y;
        input [31:0] z;
        begin
            maj = (x & y) ^ (x & z) ^ (y & z);
        end
    endfunction

    function [31:0] big_sigma0;
        input [31:0] x;
        begin
            big_sigma0 = rotr(x, 2) ^ rotr(x, 13) ^ rotr(x, 22);
        end
    endfunction

    function [31:0] big_sigma1;
        input [31:0] x;
        begin
            big_sigma1 = rotr(x, 6) ^ rotr(x, 11) ^ rotr(x, 25);
        end
    endfunction

    function [31:0] small_sigma0;
        input [31:0] x;
        begin
            small_sigma0 = rotr(x, 7) ^ rotr(x, 18) ^ (x >> 3);
        end
    endfunction

    function [31:0] small_sigma1;
        input [31:0] x;
        begin
            small_sigma1 = rotr(x, 17) ^ rotr(x, 19) ^ (x >> 10);
        end
    endfunction

    function [31:0] k256;
        input [6:0] idx;
        begin
            case (idx)
                7'd0:  k256 = 32'h428a2f98;  7'd1:  k256 = 32'h71374491;
                7'd2:  k256 = 32'hb5c0fbcf;  7'd3:  k256 = 32'he9b5dba5;
                7'd4:  k256 = 32'h3956c25b;  7'd5:  k256 = 32'h59f111f1;
                7'd6:  k256 = 32'h923f82a4;  7'd7:  k256 = 32'hab1c5ed5;
                7'd8:  k256 = 32'hd807aa98;  7'd9:  k256 = 32'h12835b01;
                7'd10: k256 = 32'h243185be;  7'd11: k256 = 32'h550c7dc3;
                7'd12: k256 = 32'h72be5d74;  7'd13: k256 = 32'h80deb1fe;
                7'd14: k256 = 32'h9bdc06a7;  7'd15: k256 = 32'hc19bf174;
                7'd16: k256 = 32'he49b69c1;  7'd17: k256 = 32'hefbe4786;
                7'd18: k256 = 32'h0fc19dc6;  7'd19: k256 = 32'h240ca1cc;
                7'd20: k256 = 32'h2de92c6f;  7'd21: k256 = 32'h4a7484aa;
                7'd22: k256 = 32'h5cb0a9dc;  7'd23: k256 = 32'h76f988da;
                7'd24: k256 = 32'h983e5152;  7'd25: k256 = 32'ha831c66d;
                7'd26: k256 = 32'hb00327c8;  7'd27: k256 = 32'hbf597fc7;
                7'd28: k256 = 32'hc6e00bf3;  7'd29: k256 = 32'hd5a79147;
                7'd30: k256 = 32'h06ca6351;  7'd31: k256 = 32'h14292967;
                7'd32: k256 = 32'h27b70a85;  7'd33: k256 = 32'h2e1b2138;
                7'd34: k256 = 32'h4d2c6dfc;  7'd35: k256 = 32'h53380d13;
                7'd36: k256 = 32'h650a7354;  7'd37: k256 = 32'h766a0abb;
                7'd38: k256 = 32'h81c2c92e;  7'd39: k256 = 32'h92722c85;
                7'd40: k256 = 32'ha2bfe8a1;  7'd41: k256 = 32'ha81a664b;
                7'd42: k256 = 32'hc24b8b70;  7'd43: k256 = 32'hc76c51a3;
                7'd44: k256 = 32'hd192e819;  7'd45: k256 = 32'hd6990624;
                7'd46: k256 = 32'hf40e3585;  7'd47: k256 = 32'h106aa070;
                7'd48: k256 = 32'h19a4c116;  7'd49: k256 = 32'h1e376c08;
                7'd50: k256 = 32'h2748774c;  7'd51: k256 = 32'h34b0bcb5;
                7'd52: k256 = 32'h391c0cb3;  7'd53: k256 = 32'h4ed8aa4a;
                7'd54: k256 = 32'h5b9cca4f;  7'd55: k256 = 32'h682e6ff3;
                7'd56: k256 = 32'h748f82ee;  7'd57: k256 = 32'h78a5636f;
                7'd58: k256 = 32'h84c87814;  7'd59: k256 = 32'h8cc70208;
                7'd60: k256 = 32'h90befffa;  7'd61: k256 = 32'ha4506ceb;
                7'd62: k256 = 32'hbef9a3f7;  7'd63: k256 = 32'hc67178f2;
                default: k256 = 32'h00000000;
            endcase
        end
    endfunction

    always @(posedge clk) begin
        if (!rst_n) begin
            busy <= 1'b0;
            done <= 1'b0;
            digest <= 256'd0;
            phase <= PHASE_IDLE;
            round <= 7'd0;
            start_d <= 1'b0;
            a <= 32'd0;
            b <= 32'd0;
            c <= 32'd0;
            d <= 32'd0;
            e <= 32'd0;
            f <= 32'd0;
            g <= 32'd0;
            h <= 32'd0;
            state0 <= 32'd0;
            state1 <= 32'd0;
            state2 <= 32'd0;
            state3 <= 32'd0;
            state4 <= 32'd0;
            state5 <= 32'd0;
            state6 <= 32'd0;
            state7 <= 32'd0;
            for (i = 0; i < 16; i = i + 1)
                w[i] <= 32'd0;
        end else begin
            done <= 1'b0;
            start_d <= start;

            case (phase)
                PHASE_IDLE: begin
                    if (start_pulse) begin
                        busy <= 1'b1;
                        phase <= PHASE_COMPRESS;
                        round <= 7'd0;
                        state0 <= init_h0;
                        state1 <= init_h1;
                        state2 <= init_h2;
                        state3 <= init_h3;
                        state4 <= init_h4;
                        state5 <= init_h5;
                        state6 <= init_h6;
                        state7 <= init_h7;
                        a <= init_h0;
                        b <= init_h1;
                        c <= init_h2;
                        d <= init_h3;
                        e <= init_h4;
                        f <= init_h5;
                        g <= init_h6;
                        h <= init_h7;
                        for (i = 0; i < 16; i = i + 1)
                            w[i] <= block[511 - i*32 -: 32];
                    end
                end

                PHASE_COMPRESS: begin
                    if (round >= 7'd16)
                        w[w_idx] <= sched_word;

                    a <= next_a;
                    b <= next_b;
                    c <= next_c;
                    d <= next_d;
                    e <= next_e;
                    f <= next_f;
                    g <= next_g;
                    h <= next_h;

                    if (round == 7'd63) begin
                        digest <= {
                            next_a + state0,
                            next_b + state1,
                            next_c + state2,
                            next_d + state3,
                            next_e + state4,
                            next_f + state5,
                            next_g + state6,
                            next_h + state7
                        };
                        busy <= 1'b0;
                        done <= 1'b1;
                        phase <= PHASE_IDLE;
                    end else begin
                        round <= round + 7'd1;
                    end
                end
            endcase
        end
    end
endmodule
