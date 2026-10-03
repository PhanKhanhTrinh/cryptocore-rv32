`timescale 1ns / 1ps

module tb_crypto_perf;
    reg clk = 1'b0;
    reg rst_n = 1'b0;

    reg         awvalid;
    wire        awready;
    reg [31:0]  awaddr;
    reg         wvalid;
    wire        wready;
    reg [31:0]  wdata;
    reg [3:0]   wstrb;
    wire        bvalid;
    reg         bready;
    reg         arvalid;
    wire        arready;
    reg [31:0]  araddr;
    wire        rvalid;
    reg         rready;
    wire [31:0] rdata;

    integer i;
    integer cycle_count;
    integer op_start_cycle;
    integer op_latency;
    integer aes_total_cycles;
    integer sha_cycles;
    integer chacha_cycles;
    integer tmp_cycles;
    integer block_idx;

    localparam BASE = 32'h0000_0000;
    localparam REG_CTRL = BASE + 32'h00;
    localparam REG_STATUS = BASE + 32'h04;
    localparam REG_ALGO = BASE + 32'h08;
    localparam REG_BUF = BASE + 32'h10;

    localparam ALGO_AES128_ENC     = 32'd0;
    localparam ALGO_CHACHA20_BLOCK = 32'd2;
    localparam ALGO_SHA256_2BLOCK  = 32'd8;

    always #5 clk = ~clk;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            cycle_count <= 0;
        else
            cycle_count <= cycle_count + 1;
    end

    crypto_coprocessor_axi dut (
        .clk(clk),
        .rst_n(rst_n),
        .s_axi_awvalid(awvalid),
        .s_axi_awready(awready),
        .s_axi_awaddr(awaddr),
        .s_axi_wvalid(wvalid),
        .s_axi_wready(wready),
        .s_axi_wdata(wdata),
        .s_axi_wstrb(wstrb),
        .s_axi_bvalid(bvalid),
        .s_axi_bready(bready),
        .s_axi_arvalid(arvalid),
        .s_axi_arready(arready),
        .s_axi_araddr(araddr),
        .s_axi_rvalid(rvalid),
        .s_axi_rready(rready),
        .s_axi_rdata(rdata)
    );

    task axi_write;
        input [31:0] addr;
        input [31:0] data;
        begin
            @(posedge clk);
            awaddr <= addr;
            wdata <= data;
            wstrb <= 4'hf;
            awvalid <= 1'b1;
            wvalid <= 1'b1;
            bready <= 1'b1;
            wait (awready && wready);
            @(posedge clk);
            awvalid <= 1'b0;
            wvalid <= 1'b0;
            wait (bvalid);
            @(posedge clk);
            bready <= 1'b0;
        end
    endtask

    task clear_done;
        begin
            axi_write(REG_STATUS, 32'h0000_0002);
        end
    endtask

    task start_and_measure;
        input [31:0] algo;
        output integer cycles;
        begin
            clear_done;
            axi_write(REG_ALGO, algo);
            axi_write(REG_CTRL, 32'd1);

            wait (dut.op_busy == 1'b1);
            op_start_cycle = cycle_count;
            wait (dut.op_done == 1'b1);
            op_latency = cycle_count - op_start_cycle;
            cycles = op_latency;

            if (dut.op_error) begin
                $display("PERF ERROR: algo=%0d returned op_error", algo);
                $fatal(1);
            end
        end
    endtask

    task load_aes_payload_block;
        input integer block_index;
        integer word_idx;
        begin
            for (word_idx = 0; word_idx < 4; word_idx = word_idx + 1)
                axi_write(REG_BUF + word_idx*4, 32'h03020100 + ((block_index*4 + word_idx) << 24)
                                                   + ((block_index*4 + word_idx) << 16)
                                                   + ((block_index*4 + word_idx) << 8)
                                                   +  (block_index*4 + word_idx));
            axi_write(REG_BUF + 32'h10, 32'h0c0d0e0f);
            axi_write(REG_BUF + 32'h14, 32'h08090a0b);
            axi_write(REG_BUF + 32'h18, 32'h04050607);
            axi_write(REG_BUF + 32'h1c, 32'h00010203);
        end
    endtask

    task load_sha_64byte_payload;
        integer word_idx;
        begin
            for (word_idx = 0; word_idx < 16; word_idx = word_idx + 1)
                axi_write(REG_BUF + word_idx*4, 32'h00010203 + (word_idx << 24) + (word_idx << 16) + (word_idx << 8) + word_idx);
            axi_write(REG_BUF + 32'h40, 32'h80000000);
            for (word_idx = 17; word_idx < 31; word_idx = word_idx + 1)
                axi_write(REG_BUF + word_idx*4, 32'h00000000);
            axi_write(REG_BUF + 32'h7c, 32'h00000200);
        end
    endtask

    task load_chacha_inputs;
        begin
            axi_write(REG_BUF + 32'h20, 32'h03020100);
            axi_write(REG_BUF + 32'h24, 32'h07060504);
            axi_write(REG_BUF + 32'h28, 32'h0b0a0908);
            axi_write(REG_BUF + 32'h2c, 32'h0f0e0d0c);
            axi_write(REG_BUF + 32'h30, 32'h13121110);
            axi_write(REG_BUF + 32'h34, 32'h17161514);
            axi_write(REG_BUF + 32'h38, 32'h1b1a1918);
            axi_write(REG_BUF + 32'h3c, 32'h1f1e1d1c);
            axi_write(REG_BUF + 32'h40, 32'h00000001);
            axi_write(REG_BUF + 32'h44, 32'h09000000);
            axi_write(REG_BUF + 32'h48, 32'h4a000000);
            axi_write(REG_BUF + 32'h4c, 32'h00000000);
        end
    endtask

    initial begin
        awvalid = 0;
        awaddr = 0;
        wvalid = 0;
        wdata = 0;
        wstrb = 0;
        bready = 0;
        arvalid = 0;
        araddr = 0;
        rready = 0;
        aes_total_cycles = 0;
        sha_cycles = 0;
        chacha_cycles = 0;
        tmp_cycles = 0;

        repeat (5) @(posedge clk);
        rst_n = 1'b1;
        repeat (2) @(posedge clk);

        for (block_idx = 0; block_idx < 4; block_idx = block_idx + 1) begin
            load_aes_payload_block(block_idx);
            start_and_measure(ALGO_AES128_ENC, tmp_cycles);
            aes_total_cycles = aes_total_cycles + tmp_cycles;
        end

        load_sha_64byte_payload;
        start_and_measure(ALGO_SHA256_2BLOCK, sha_cycles);

        load_chacha_inputs;
        start_and_measure(ALGO_CHACHA20_BLOCK, chacha_cycles);

        $display("CRYPTO_PERF_BEGIN");
        $display("AES-128 64-byte payload: operations=4 bytes=64 cycles=%0d bytes_per_cycle=%0f",
                 aes_total_cycles, 64.0 / aes_total_cycles);
        $display("SHA-256 64-byte message with padding: operations=1 bytes=64 cycles=%0d bytes_per_cycle=%0f",
                 sha_cycles, 64.0 / sha_cycles);
        $display("ChaCha20 64-byte block: operations=1 bytes=64 cycles=%0d bytes_per_cycle=%0f",
                 chacha_cycles, 64.0 / chacha_cycles);
        $display("CRYPTO_PERF_END");
        $finish;
    end
endmodule
