`timescale 1ns / 1ps

module crypto_coprocessor_axi #(
    parameter ENABLE_AES_GCM = 1'b0
) (
    input wire         clk,
    input wire         rst_n,
    input wire         s_axi_awvalid,
    output wire        s_axi_awready,
    input wire [31:0]  s_axi_awaddr,
    input wire         s_axi_wvalid,
    output wire        s_axi_wready,
    input wire [31:0]  s_axi_wdata,
    input wire [3:0]   s_axi_wstrb,
    output reg         s_axi_bvalid,
    input wire         s_axi_bready,
    input wire         s_axi_arvalid,
    output wire        s_axi_arready,
    input wire [31:0]  s_axi_araddr,
    output reg         s_axi_rvalid,
    input wire         s_axi_rready,
    output reg [31:0]  s_axi_rdata
);
    localparam REG_CTRL     = 32'h0000_0000;
    localparam REG_STATUS   = 32'h0000_0004;
    localparam REG_ALGO_SEL = 32'h0000_0008;
    localparam REG_BUF_BASE = 32'h0000_0010;

    localparam ALGO_AES128_ENC        = 32'd0;
    localparam ALGO_SHA256_1BLOCK     = 32'd1;
    localparam ALGO_CHACHA20_BLOCK    = 32'd2;
    localparam ALGO_AES128_DEC        = 32'd3;
    localparam ALGO_AES128_CBC_ENC_2B = 32'd4;
    localparam ALGO_AES128_CBC_DEC_2B = 32'd5;
    localparam ALGO_AES128_CTR_2B     = 32'd6;
    localparam ALGO_AES128_GCM_1B     = 32'd7;
    localparam ALGO_SHA256_2BLOCK     = 32'd8;

    localparam OP_IDLE     = 3'd0;
    localparam OP_DISPATCH = 3'd1;
    localparam OP_AES_WAIT = 3'd2;
    localparam OP_SHA_WAIT = 3'd3;
    localparam OP_CHA_WAIT = 3'd4;
    localparam OP_GHASH_WAIT = 3'd5;

    reg [31:0] ctrl_reg;
    reg [31:0] algo_sel_reg;
    reg [31:0] buf_reg [0:31];
    reg [31:0] awaddr_hold;
    reg [31:0] araddr_hold;
    reg [31:0] wdata_hold;
    reg [3:0]  wstrb_hold;
    reg        aw_pending;
    reg        w_pending;
    reg        op_busy;
    reg        op_done;
    reg        op_error;
    reg [2:0]  op_state;
    reg [31:0] op_algo;
    reg [3:0]  op_step;
    reg        aes_start;
    reg        aes_decrypt;
    reg        sha_start;
    reg        sha_init;
    reg        cha_start;
    reg [127:0] aes_block_in;
    reg [127:0] aes_key_in;
    reg [127:0] aes_save0;
    reg [127:0] aes_save1;
    reg [127:0] aes_feedback;
    reg [127:0] aes_j0;
    reg [127:0] aes_h;
    reg [127:0] aes_tagmask;
    reg [127:0] gcm_cipher_calc;
    reg [127:0] gcm_tag_calc;
    reg [127:0] gf_x;
    reg [127:0] gf_v;
    reg [127:0] gf_z;
    reg [6:0]   gf_count;
    reg         gf_busy;
    reg [511:0] sha_block_in;
    reg [255:0] sha_state_in;
    reg [255:0] cha_key_in;
    reg [31:0]  cha_counter_in;
    reg [95:0]  cha_nonce_in;
    integer    i;

    wire [127:0] buf_0_3   = {buf_reg[3],  buf_reg[2],  buf_reg[1],  buf_reg[0]};
    wire [127:0] buf_4_7   = {buf_reg[7],  buf_reg[6],  buf_reg[5],  buf_reg[4]};
    wire [127:0] buf_8_11  = {buf_reg[11], buf_reg[10], buf_reg[9],  buf_reg[8]};
    wire [127:0] buf_12_15 = {buf_reg[15], buf_reg[14], buf_reg[13], buf_reg[12]};
    wire [511:0] sha_block0 = {buf_reg[0],  buf_reg[1],  buf_reg[2],  buf_reg[3],  buf_reg[4],  buf_reg[5],  buf_reg[6],  buf_reg[7],
                               buf_reg[8],  buf_reg[9],  buf_reg[10], buf_reg[11], buf_reg[12], buf_reg[13], buf_reg[14], buf_reg[15]};
    wire [511:0] sha_block1 = {buf_reg[16], buf_reg[17], buf_reg[18], buf_reg[19], buf_reg[20], buf_reg[21], buf_reg[22], buf_reg[23],
                               buf_reg[24], buf_reg[25], buf_reg[26], buf_reg[27], buf_reg[28], buf_reg[29], buf_reg[30], buf_reg[31]};

    wire aes_busy;
    wire aes_done;
    wire aes_ready;
    wire [127:0] aes_ciphertext;
    wire [127:0] gcm_tag_now = aes_tagmask ^ gf_z;
    wire sha_busy;
    wire sha_done;
    wire sha_ready;
    wire [255:0] sha_digest;
    wire cha_busy;
    wire cha_done;
    wire cha_ready;
    wire [511:0] cha_keystream;
    wire [127:0] cbc_dec_p1_now = aes_ciphertext ^ aes_feedback;
    wire [127:0] ctr_block1_now = buf_4_7 ^ aes_ciphertext;

    assign s_axi_awready = !aw_pending;
    assign s_axi_wready  = !w_pending;
    assign s_axi_arready = !s_axi_rvalid;

    aes128_core u_aes (
        .clk(clk),
        .rst_n(rst_n),
        .start(aes_start),
        .decrypt(aes_decrypt),
        .plaintext(aes_block_in),
        .key(aes_key_in),
        .ready(aes_ready),
        .busy(aes_busy),
        .done(aes_done),
        .ciphertext(aes_ciphertext)
    );

    sha256_core u_sha256 (
        .clk(clk),
        .rst_n(rst_n),
        .start(sha_start),
        .init(sha_init),
        .state_in(sha_state_in),
        .block(sha_block_in),
        .ready(sha_ready),
        .busy(sha_busy),
        .done(sha_done),
        .digest(sha_digest)
    );

    chacha20_core u_chacha20 (
        .clk(clk),
        .rst_n(rst_n),
        .start(cha_start),
        .key(cha_key_in),
        .counter(cha_counter_in),
        .nonce(cha_nonce_in),
        .ready(cha_ready),
        .busy(cha_busy),
        .done(cha_done),
        .keystream(cha_keystream)
    );

    function [31:0] merge_wstrb;
        input [31:0] old_data;
        input [31:0] new_data;
        input [3:0]  strb;
        begin
            merge_wstrb = old_data;
            if (strb[0]) merge_wstrb[7:0]   = new_data[7:0];
            if (strb[1]) merge_wstrb[15:8]  = new_data[15:8];
            if (strb[2]) merge_wstrb[23:16] = new_data[23:16];
            if (strb[3]) merge_wstrb[31:24] = new_data[31:24];
        end
    endfunction

    function algo_supported;
        input [31:0] algo;
        begin
            case (algo)
                ALGO_AES128_ENC,
                ALGO_SHA256_1BLOCK,
                ALGO_CHACHA20_BLOCK,
                ALGO_AES128_DEC,
                ALGO_AES128_CBC_ENC_2B,
                ALGO_AES128_CBC_DEC_2B,
                ALGO_AES128_CTR_2B,
                ALGO_SHA256_2BLOCK:    algo_supported = 1'b1;
                ALGO_AES128_GCM_1B:    algo_supported = ENABLE_AES_GCM;
                default:               algo_supported = 1'b0;
            endcase
        end
    endfunction

    function [127:0] inc32;
        input [127:0] x;
        begin
            inc32 = {x[127:32], x[31:0] + 32'd1};
        end
    endfunction

    function [31:0] read_reg;
        input [31:0] addr;
        integer idx;
        begin
            if (addr == REG_CTRL)
                read_reg = ctrl_reg;
            else if (addr == REG_STATUS)
                read_reg = {29'd0, op_error, op_done, op_busy};
            else if (addr == REG_ALGO_SEL)
                read_reg = algo_sel_reg;
            else if ((addr >= REG_BUF_BASE) && (addr < (REG_BUF_BASE + 32*4))) begin
                idx = (addr - REG_BUF_BASE) >> 2;
                read_reg = buf_reg[idx];
            end else
                read_reg = 32'hdead_beef;
        end
    endfunction

    task write_reg;
        input [31:0] addr;
        input [31:0] data;
        input [3:0]  strb;
        integer idx;
        reg [31:0] merged;
        begin
            if (addr == REG_CTRL) begin
                merged = merge_wstrb(ctrl_reg, data, strb);
                ctrl_reg <= merged & 32'hffff_fffe;
                if (strb[0] && data[0]) begin
                    op_done <= 1'b0;
                    op_error <= 1'b0;
                    if (!op_busy && (op_state == OP_IDLE) && algo_supported(algo_sel_reg)) begin
                        op_algo <= algo_sel_reg;
                        op_step <= 4'd0;
                        op_state <= OP_DISPATCH;
                        op_busy <= 1'b1;
                    end else begin
                        op_error <= 1'b1;
                    end
                end
            end else if (addr == REG_STATUS) begin
                if (strb[0] && data[1]) op_done <= 1'b0;
                if (strb[0] && data[2]) op_error <= 1'b0;
            end else if (addr == REG_ALGO_SEL) begin
                algo_sel_reg <= merge_wstrb(algo_sel_reg, data, strb);
            end else if ((addr >= REG_BUF_BASE) && (addr < (REG_BUF_BASE + 32*4))) begin
                idx = (addr - REG_BUF_BASE) >> 2;
                buf_reg[idx] <= merge_wstrb(buf_reg[idx], data, strb);
            end
        end
    endtask

    always @(posedge clk) begin
        if (!rst_n) begin
            ctrl_reg <= 32'd0;
            algo_sel_reg <= 32'd0;
            awaddr_hold <= 32'd0;
            araddr_hold <= 32'd0;
            wdata_hold <= 32'd0;
            wstrb_hold <= 4'd0;
            aw_pending <= 1'b0;
            w_pending <= 1'b0;
            s_axi_bvalid <= 1'b0;
            s_axi_rvalid <= 1'b0;
            s_axi_rdata <= 32'd0;
            op_busy <= 1'b0;
            op_done <= 1'b0;
            op_error <= 1'b0;
            op_state <= OP_IDLE;
            op_algo <= 32'd0;
            op_step <= 4'd0;
            aes_start <= 1'b0;
            aes_decrypt <= 1'b0;
            sha_start <= 1'b0;
            sha_init <= 1'b1;
            cha_start <= 1'b0;
            aes_block_in <= 128'd0;
            aes_key_in <= 128'd0;
            aes_save0 <= 128'd0;
            aes_save1 <= 128'd0;
            aes_feedback <= 128'd0;
            aes_j0 <= 128'd0;
            aes_h <= 128'd0;
            aes_tagmask <= 128'd0;
            gcm_cipher_calc <= 128'd0;
            gcm_tag_calc <= 128'd0;
            gf_x <= 128'd0;
            gf_v <= 128'd0;
            gf_z <= 128'd0;
            gf_count <= 7'd0;
            gf_busy <= 1'b0;
            sha_block_in <= 512'd0;
            sha_state_in <= 256'd0;
            cha_key_in <= 256'd0;
            cha_counter_in <= 32'd0;
            cha_nonce_in <= 96'd0;
            for (i = 0; i < 32; i = i + 1)
                buf_reg[i] <= 32'd0;
        end else begin
            aes_start <= 1'b0;
            sha_start <= 1'b0;
            cha_start <= 1'b0;

            if (gf_busy) begin
                if (gf_x[127])
                    gf_z <= gf_z ^ gf_v;
                gf_x <= {gf_x[126:0], 1'b0};
                if (gf_v[0])
                    gf_v <= (gf_v >> 1) ^ 128'he1000000000000000000000000000000;
                else
                    gf_v <= gf_v >> 1;
                gf_count <= gf_count + 7'd1;
                if (gf_count == 7'd127)
                    gf_busy <= 1'b0;
            end

            if (s_axi_awvalid && s_axi_awready) begin
                awaddr_hold <= s_axi_awaddr;
                aw_pending <= 1'b1;
            end
            if (s_axi_wvalid && s_axi_wready) begin
                wdata_hold <= s_axi_wdata;
                wstrb_hold <= s_axi_wstrb;
                w_pending <= 1'b1;
            end
            if (aw_pending && w_pending && !s_axi_bvalid) begin
                write_reg(awaddr_hold[7:0], wdata_hold, wstrb_hold);
                aw_pending <= 1'b0;
                w_pending <= 1'b0;
                s_axi_bvalid <= 1'b1;
            end
            if (s_axi_bvalid && s_axi_bready)
                s_axi_bvalid <= 1'b0;

            if (s_axi_arvalid && s_axi_arready) begin
                araddr_hold <= s_axi_araddr;
                s_axi_rdata <= read_reg(s_axi_araddr[7:0]);
                s_axi_rvalid <= 1'b1;
            end
            if (s_axi_rvalid && s_axi_rready)
                s_axi_rvalid <= 1'b0;

            case (op_state)
                OP_IDLE: begin
                end

                OP_DISPATCH: begin
                    case (op_algo)
                        ALGO_AES128_ENC: begin
                            aes_block_in <= buf_0_3;
                            aes_key_in <= buf_4_7;
                            aes_decrypt <= 1'b0;
                            aes_start <= 1'b1;
                            op_state <= OP_AES_WAIT;
                        end
                        ALGO_AES128_DEC: begin
                            aes_block_in <= buf_0_3;
                            aes_key_in <= buf_4_7;
                            aes_decrypt <= 1'b1;
                            aes_start <= 1'b1;
                            op_state <= OP_AES_WAIT;
                        end
                        ALGO_AES128_CBC_ENC_2B: begin
                            aes_block_in <= buf_0_3 ^ buf_12_15;
                            aes_key_in <= buf_8_11;
                            aes_decrypt <= 1'b0;
                            aes_start <= 1'b1;
                            op_state <= OP_AES_WAIT;
                        end
                        ALGO_AES128_CBC_DEC_2B: begin
                            aes_block_in <= buf_0_3;
                            aes_key_in <= buf_8_11;
                            aes_decrypt <= 1'b1;
                            aes_start <= 1'b1;
                            op_state <= OP_AES_WAIT;
                        end
                        ALGO_AES128_CTR_2B: begin
                            aes_block_in <= buf_12_15;
                            aes_key_in <= buf_8_11;
                            aes_decrypt <= 1'b0;
                            aes_start <= 1'b1;
                            op_state <= OP_AES_WAIT;
                        end
                        ALGO_AES128_GCM_1B: begin
                            if (ENABLE_AES_GCM) begin
                                aes_block_in <= 128'd0;
                                aes_key_in <= buf_8_11;
                                aes_decrypt <= 1'b0;
                                aes_j0 <= {buf_reg[14], buf_reg[13], buf_reg[12], 32'h0000_0001};
                                aes_start <= 1'b1;
                                op_state <= OP_AES_WAIT;
                            end else begin
                                op_busy <= 1'b0;
                                op_error <= 1'b1;
                                op_state <= OP_IDLE;
                            end
                        end
                        ALGO_SHA256_1BLOCK,
                        ALGO_SHA256_2BLOCK: begin
                            sha_block_in <= sha_block0;
                            sha_state_in <= 256'd0;
                            sha_init <= 1'b1;
                            sha_start <= 1'b1;
                            op_state <= OP_SHA_WAIT;
                        end
                        ALGO_CHACHA20_BLOCK: begin
                            cha_key_in <= {buf_reg[15], buf_reg[14], buf_reg[13], buf_reg[12], buf_reg[11], buf_reg[10], buf_reg[9], buf_reg[8]};
                            cha_counter_in <= buf_reg[16];
                            cha_nonce_in <= {buf_reg[19], buf_reg[18], buf_reg[17]};
                            cha_start <= 1'b1;
                            op_state <= OP_CHA_WAIT;
                        end
                        default: begin
                            op_busy <= 1'b0;
                            op_error <= 1'b1;
                            op_state <= OP_IDLE;
                        end
                    endcase
                end

                OP_AES_WAIT: begin
                    if (aes_done) begin
                        case (op_algo)
                            ALGO_AES128_ENC,
                            ALGO_AES128_DEC: begin
                                buf_reg[20] <= aes_ciphertext[31:0];
                                buf_reg[21] <= aes_ciphertext[63:32];
                                buf_reg[22] <= aes_ciphertext[95:64];
                                buf_reg[23] <= aes_ciphertext[127:96];
                                op_busy <= 1'b0;
                                op_done <= 1'b1;
                                op_state <= OP_IDLE;
                            end
                            ALGO_AES128_CBC_ENC_2B: begin
                                if (op_step == 4'd0) begin
                                    aes_save0 <= aes_ciphertext;
                                    aes_block_in <= buf_4_7 ^ aes_ciphertext;
                                    aes_decrypt <= 1'b0;
                                    aes_start <= 1'b1;
                                    op_step <= 4'd1;
                                end else begin
                                    buf_reg[20] <= aes_save0[31:0];
                                    buf_reg[21] <= aes_save0[63:32];
                                    buf_reg[22] <= aes_save0[95:64];
                                    buf_reg[23] <= aes_save0[127:96];
                                    buf_reg[24] <= aes_ciphertext[31:0];
                                    buf_reg[25] <= aes_ciphertext[63:32];
                                    buf_reg[26] <= aes_ciphertext[95:64];
                                    buf_reg[27] <= aes_ciphertext[127:96];
                                    op_busy <= 1'b0;
                                    op_done <= 1'b1;
                                    op_state <= OP_IDLE;
                                end
                            end
                            ALGO_AES128_CBC_DEC_2B: begin
                                if (op_step == 4'd0) begin
                                    aes_save0 <= aes_ciphertext ^ buf_12_15;
                                    aes_feedback <= buf_0_3;
                                    aes_block_in <= buf_4_7;
                                    aes_decrypt <= 1'b1;
                                    aes_start <= 1'b1;
                                    op_step <= 4'd1;
                                end else begin
                                    aes_save1 <= cbc_dec_p1_now;
                                    buf_reg[20] <= aes_save0[31:0];
                                    buf_reg[21] <= aes_save0[63:32];
                                    buf_reg[22] <= aes_save0[95:64];
                                    buf_reg[23] <= aes_save0[127:96];
                                    buf_reg[24] <= cbc_dec_p1_now[31:0];
                                    buf_reg[25] <= cbc_dec_p1_now[63:32];
                                    buf_reg[26] <= cbc_dec_p1_now[95:64];
                                    buf_reg[27] <= cbc_dec_p1_now[127:96];
                                    op_busy <= 1'b0;
                                    op_done <= 1'b1;
                                    op_state <= OP_IDLE;
                                end
                            end
                            ALGO_AES128_CTR_2B: begin
                                if (op_step == 4'd0) begin
                                    aes_save0 <= buf_0_3 ^ aes_ciphertext;
                                    aes_block_in <= inc32(buf_12_15);
                                    aes_decrypt <= 1'b0;
                                    aes_start <= 1'b1;
                                    op_step <= 4'd1;
                                end else begin
                                    buf_reg[20] <= aes_save0[31:0];
                                    buf_reg[21] <= aes_save0[63:32];
                                    buf_reg[22] <= aes_save0[95:64];
                                    buf_reg[23] <= aes_save0[127:96];
                                    buf_reg[24] <= ctr_block1_now[31:0];
                                    buf_reg[25] <= ctr_block1_now[63:32];
                                    buf_reg[26] <= ctr_block1_now[95:64];
                                    buf_reg[27] <= ctr_block1_now[127:96];
                                    op_busy <= 1'b0;
                                    op_done <= 1'b1;
                                    op_state <= OP_IDLE;
                                end
                            end
                            ALGO_AES128_GCM_1B: begin
                                if (ENABLE_AES_GCM) begin
                                    if (op_step == 4'd0) begin
                                        aes_h <= aes_ciphertext;
                                        aes_block_in <= aes_j0;
                                        aes_decrypt <= 1'b0;
                                        aes_start <= 1'b1;
                                        op_step <= 4'd1;
                                    end else if (op_step == 4'd1) begin
                                        aes_tagmask <= aes_ciphertext;
                                        aes_block_in <= inc32(aes_j0);
                                        aes_decrypt <= 1'b0;
                                        aes_start <= 1'b1;
                                        op_step <= 4'd2;
                                    end else begin
                                        gcm_cipher_calc <= buf_0_3 ^ aes_ciphertext;
                                        gf_x <= buf_0_3 ^ aes_ciphertext;
                                        gf_v <= aes_h;
                                        gf_z <= 128'd0;
                                        gf_count <= 7'd0;
                                        gf_busy <= 1'b1;
                                        op_step <= 4'd0;
                                        op_state <= OP_GHASH_WAIT;
                                    end
                                end else begin
                                    op_busy <= 1'b0;
                                    op_error <= 1'b1;
                                    op_state <= OP_IDLE;
                                end
                            end
                            default: begin
                                op_busy <= 1'b0;
                                op_error <= 1'b1;
                                op_state <= OP_IDLE;
                            end
                        endcase
                    end
                end

                OP_GHASH_WAIT: begin
                    if (ENABLE_AES_GCM) begin
                        if (!gf_busy) begin
                            if (op_step == 4'd0) begin
                                gf_x <= gf_z ^ 128'h00000000000000000000000000000080;
                                gf_v <= aes_h;
                                gf_z <= 128'd0;
                                gf_count <= 7'd0;
                                gf_busy <= 1'b1;
                                op_step <= 4'd1;
                            end else begin
                                gcm_tag_calc <= gcm_tag_now;
                                buf_reg[20] <= gcm_cipher_calc[31:0];
                                buf_reg[21] <= gcm_cipher_calc[63:32];
                                buf_reg[22] <= gcm_cipher_calc[95:64];
                                buf_reg[23] <= gcm_cipher_calc[127:96];
                                buf_reg[24] <= gcm_tag_now[31:0];
                                buf_reg[25] <= gcm_tag_now[63:32];
                                buf_reg[26] <= gcm_tag_now[95:64];
                                buf_reg[27] <= gcm_tag_now[127:96];
                                op_busy <= 1'b0;
                                op_done <= 1'b1;
                                op_state <= OP_IDLE;
                            end
                        end
                    end else begin
                        op_busy <= 1'b0;
                        op_error <= 1'b1;
                        op_state <= OP_IDLE;
                    end
                end

                OP_SHA_WAIT: begin
                    if (sha_done) begin
                        if ((op_algo == ALGO_SHA256_2BLOCK) && (op_step == 4'd0)) begin
                            sha_state_in <= sha_digest;
                            sha_block_in <= sha_block1;
                            sha_init <= 1'b0;
                            sha_start <= 1'b1;
                            op_step <= 4'd1;
                        end else begin
                            buf_reg[24] <= sha_digest[31:0];
                            buf_reg[25] <= sha_digest[63:32];
                            buf_reg[26] <= sha_digest[95:64];
                            buf_reg[27] <= sha_digest[127:96];
                            buf_reg[28] <= sha_digest[159:128];
                            buf_reg[29] <= sha_digest[191:160];
                            buf_reg[30] <= sha_digest[223:192];
                            buf_reg[31] <= sha_digest[255:224];
                            op_busy <= 1'b0;
                            op_done <= 1'b1;
                            op_state <= OP_IDLE;
                        end
                    end
                end

                OP_CHA_WAIT: begin
                    if (cha_done) begin
                        if (op_algo == ALGO_CHACHA20_BLOCK) begin
                            for (i = 0; i < 16; i = i + 1)
                                buf_reg[i] <= cha_keystream[i*32 +: 32];
                            op_busy <= 1'b0;
                            op_done <= 1'b1;
                            op_state <= OP_IDLE;
                        end
                    end
                end

                default: begin
                    op_state <= OP_IDLE;
                end
            endcase
        end
    end
endmodule
