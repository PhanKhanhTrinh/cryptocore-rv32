`timescale 1ns / 1ps

module chacha20_core (
    input wire         clk,
    input wire         rst_n,
    input wire         start,
    input wire [255:0] key,
    input wire [31:0]  counter,
    input wire [95:0]  nonce,
    output wire        ready,
    output reg         busy,
    output reg         done,
    output reg [511:0] keystream
);
    localparam PHASE_IDLE   = 2'd0;
    localparam PHASE_ROUNDS = 2'd1;
    localparam PHASE_FINAL  = 2'd2;

    reg [1:0] phase;
    reg [6:0] step;
    reg [31:0] x [0:15];
    reg [31:0] in_state [0:15];
    reg [3:0] qr_a_idx;
    reg [3:0] qr_b_idx;
    reg [3:0] qr_c_idx;
    reg [3:0] qr_d_idx;
    reg       start_d;
    integer i;

    assign ready = (phase == PHASE_IDLE) && !start_d;

    wire start_pulse = start & ~start_d;

    wire [127:0] qr_out = quarter_round_result(
        x[qr_a_idx],
        x[qr_b_idx],
        x[qr_c_idx],
        x[qr_d_idx]
    );

    function [31:0] rotl32;
        input [31:0] x_in;
        input integer n;
        begin
            rotl32 = (x_in << n) | (x_in >> (32-n));
        end
    endfunction

    function [127:0] quarter_round_result;
        input [31:0] a_in;
        input [31:0] b_in;
        input [31:0] c_in;
        input [31:0] d_in;
        reg [31:0] a;
        reg [31:0] b;
        reg [31:0] c;
        reg [31:0] d;
        begin
            a = a_in;
            b = b_in;
            c = c_in;
            d = d_in;

            a = a + b; d = rotl32(d ^ a, 16);
            c = c + d; b = rotl32(b ^ c, 12);
            a = a + b; d = rotl32(d ^ a, 8);
            c = c + d; b = rotl32(b ^ c, 7);

            quarter_round_result = {a, b, c, d};
        end
    endfunction

    always @(*) begin
        case (step[2:0])
            3'd0: begin qr_a_idx = 4'd0; qr_b_idx = 4'd4; qr_c_idx = 4'd8;  qr_d_idx = 4'd12; end
            3'd1: begin qr_a_idx = 4'd1; qr_b_idx = 4'd5; qr_c_idx = 4'd9;  qr_d_idx = 4'd13; end
            3'd2: begin qr_a_idx = 4'd2; qr_b_idx = 4'd6; qr_c_idx = 4'd10; qr_d_idx = 4'd14; end
            3'd3: begin qr_a_idx = 4'd3; qr_b_idx = 4'd7; qr_c_idx = 4'd11; qr_d_idx = 4'd15; end
            3'd4: begin qr_a_idx = 4'd0; qr_b_idx = 4'd5; qr_c_idx = 4'd10; qr_d_idx = 4'd15; end
            3'd5: begin qr_a_idx = 4'd1; qr_b_idx = 4'd6; qr_c_idx = 4'd11; qr_d_idx = 4'd12; end
            3'd6: begin qr_a_idx = 4'd2; qr_b_idx = 4'd7; qr_c_idx = 4'd8;  qr_d_idx = 4'd13; end
            default: begin qr_a_idx = 4'd3; qr_b_idx = 4'd4; qr_c_idx = 4'd9;  qr_d_idx = 4'd14; end
        endcase
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            busy <= 1'b0;
            done <= 1'b0;
            phase <= PHASE_IDLE;
            step <= 7'd0;
            start_d <= 1'b0;
            keystream <= 512'd0;
            for (i = 0; i < 16; i = i + 1) begin
                x[i] <= 32'd0;
                in_state[i] <= 32'd0;
            end
        end else begin
            done <= 1'b0;
            start_d <= start;

            case (phase)
                PHASE_IDLE: begin
                    if (start_pulse) begin
                        in_state[0]  <= 32'h61707865;
                        in_state[1]  <= 32'h3320646e;
                        in_state[2]  <= 32'h79622d32;
                        in_state[3]  <= 32'h6b206574;
                        in_state[4]  <= key[31:0];
                        in_state[5]  <= key[63:32];
                        in_state[6]  <= key[95:64];
                        in_state[7]  <= key[127:96];
                        in_state[8]  <= key[159:128];
                        in_state[9]  <= key[191:160];
                        in_state[10] <= key[223:192];
                        in_state[11] <= key[255:224];
                        in_state[12] <= counter;
                        in_state[13] <= nonce[31:0];
                        in_state[14] <= nonce[63:32];
                        in_state[15] <= nonce[95:64];

                        x[0]  <= 32'h61707865;
                        x[1]  <= 32'h3320646e;
                        x[2]  <= 32'h79622d32;
                        x[3]  <= 32'h6b206574;
                        x[4]  <= key[31:0];
                        x[5]  <= key[63:32];
                        x[6]  <= key[95:64];
                        x[7]  <= key[127:96];
                        x[8]  <= key[159:128];
                        x[9]  <= key[191:160];
                        x[10] <= key[223:192];
                        x[11] <= key[255:224];
                        x[12] <= counter;
                        x[13] <= nonce[31:0];
                        x[14] <= nonce[63:32];
                        x[15] <= nonce[95:64];

                        step <= 7'd0;
                        busy <= 1'b1;
                        phase <= PHASE_ROUNDS;
                    end
                end

                PHASE_ROUNDS: begin
                    x[qr_a_idx] <= qr_out[127:96];
                    x[qr_b_idx] <= qr_out[95:64];
                    x[qr_c_idx] <= qr_out[63:32];
                    x[qr_d_idx] <= qr_out[31:0];

                    if (step == 7'd79) begin
                        phase <= PHASE_FINAL;
                    end else begin
                        step <= step + 7'd1;
                    end
                end

                PHASE_FINAL: begin
                    keystream <= {
                        x[15] + in_state[15],
                        x[14] + in_state[14],
                        x[13] + in_state[13],
                        x[12] + in_state[12],
                        x[11] + in_state[11],
                        x[10] + in_state[10],
                        x[9]  + in_state[9],
                        x[8]  + in_state[8],
                        x[7]  + in_state[7],
                        x[6]  + in_state[6],
                        x[5]  + in_state[5],
                        x[4]  + in_state[4],
                        x[3]  + in_state[3],
                        x[2]  + in_state[2],
                        x[1]  + in_state[1],
                        x[0]  + in_state[0]
                    };
                    busy <= 1'b0;
                    done <= 1'b1;
                    phase <= PHASE_IDLE;
                end

                default: begin
                    busy <= 1'b0;
                    phase <= PHASE_IDLE;
                end
            endcase
        end
    end
endmodule
