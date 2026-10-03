`timescale 1ns / 1ps

module tb_aes_modes_axi;
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

    reg [2:0]   test_phase;
    reg [31:0]  status_word;
    reg [127:0] input_block_1;
    reg [127:0] input_block_2;
    reg [127:0] input_key;
    reg [127:0] input_iv_counter;
    reg [255:0] mode_result;
    reg [255:0] cbc_ciphertext;
    reg [255:0] cbc_plaintext;
    reg [255:0] ctr_ciphertext;
    reg [255:0] ctr_plaintext;
    reg         clear_aes_counts;
    integer     aes_start_count;
    integer     aes_done_count;
    integer     poll_count;
    integer     i;

    localparam REG_CTRL   = 32'h0000_0000;
    localparam REG_STATUS = 32'h0000_0004;
    localparam REG_ALGO   = 32'h0000_0008;
    localparam REG_BUF    = 32'h0000_0010;

    localparam ALGO_AES128_CBC_ENC_2B = 32'd4;
    localparam ALGO_AES128_CBC_DEC_2B = 32'd5;
    localparam ALGO_AES128_CTR_2B     = 32'd6;

    localparam PHASE_IDLE    = 3'd0;
    localparam PHASE_CBC_ENC = 3'd1;
    localparam PHASE_CBC_DEC = 3'd2;
    localparam PHASE_CTR_ENC = 3'd3;
    localparam PHASE_CTR_DEC = 3'd4;
    localparam PHASE_DONE    = 3'd5;

    localparam [127:0] BLOCK0 =
        128'h00112233445566778899aabbccddeeff;
    localparam [127:0] BLOCK1 =
        128'hffeeddccbbaa99887766554433221100;
    localparam [127:0] AES_KEY =
        128'h000102030405060708090a0b0c0d0e0f;
    localparam [127:0] IV_COUNTER =
        128'h0f0e0d0c0b0a09080706050403020100;
    localparam [255:0] PLAINTEXT_2B = {BLOCK1, BLOCK0};
    localparam [255:0] CBC_EXPECTED =
        256'h5176505d3a1a149f2f66b03f8989085316628846f7334843bc7321cc79661680;
    localparam [255:0] CTR_EXPECTED =
        256'hb8487969cef4f9cc19d4c4a87a1b105f20b8dba1f0193d9f8c865667a0737795;

    always #5 clk = ~clk;

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

    always @(posedge clk) begin
        if (!rst_n || clear_aes_counts) begin
            aes_start_count <= 0;
            aes_done_count <= 0;
        end else begin
            if (dut.aes_start)
                aes_start_count <= aes_start_count + 1;
            if (dut.aes_done)
                aes_done_count <= aes_done_count + 1;
        end
    end

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

    task axi_read;
        input [31:0] addr;
        output [31:0] data;
        begin
            @(posedge clk);
            araddr <= addr;
            arvalid <= 1'b1;
            rready <= 1'b1;
            wait (arready);
            @(posedge clk);
            arvalid <= 1'b0;
            wait (rvalid);
            data = rdata;
            @(posedge clk);
            rready <= 1'b0;
        end
    endtask

    task write_128;
        input [31:0] addr;
        input [127:0] value;
        begin
            axi_write(addr + 32'h00, value[31:0]);
            axi_write(addr + 32'h04, value[63:32]);
            axi_write(addr + 32'h08, value[95:64]);
            axi_write(addr + 32'h0c, value[127:96]);
        end
    endtask

    task load_mode_inputs;
        input [127:0] block0;
        input [127:0] block1;
        begin
            write_128(REG_BUF + 32'h00, block0);
            write_128(REG_BUF + 32'h10, block1);
            write_128(REG_BUF + 32'h20, AES_KEY);
            write_128(REG_BUF + 32'h30, IV_COUNTER);

            input_block_1 = block0;
            input_block_2 = block1;
            input_key = AES_KEY;
            input_iv_counter = IV_COUNTER;
        end
    endtask

    task clear_status;
        begin
            axi_write(REG_STATUS, 32'h0000_0006);
            axi_read(REG_STATUS, status_word);
            if (status_word[2:1] !== 2'b00) begin
                $display("Failed to clear DONE/ERROR: status=%h", status_word);
                $fatal(1);
            end
        end
    endtask

    task reset_mode_counts;
        begin
            @(negedge clk);
            clear_aes_counts = 1'b1;
            @(posedge clk);
            #1;
            clear_aes_counts = 1'b0;
        end
    endtask

    task wait_done;
        begin
            status_word = 32'd0;
            poll_count = 0;
            while ((status_word[1] == 1'b0) &&
                   (status_word[2] == 1'b0) &&
                   (poll_count < 10000)) begin
                axi_read(REG_STATUS, status_word);
                poll_count = poll_count + 1;
            end
            if (status_word[2]) begin
                $display("AES mode returned ERROR: phase=%0d status=%h",
                         test_phase, status_word);
                $fatal(1);
            end
            if (!status_word[1]) begin
                $display("AES mode timeout: phase=%0d state=%0d step=%0d",
                         test_phase, dut.op_state, dut.op_step);
                $fatal(1);
            end
        end
    endtask

    task read_mode_result;
        output [255:0] value;
        begin
            for (i = 0; i < 8; i = i + 1)
                axi_read(REG_BUF + 32'h50 + i*4, value[i*32 +: 32]);
        end
    endtask

    task run_mode;
        input [2:0] phase;
        input [31:0] algo;
        output [255:0] value;
        begin
            test_phase = phase;
            clear_status;
            reset_mode_counts;
            axi_write(REG_ALGO, algo);
            axi_write(REG_CTRL, 32'd1);
            wait_done;
            read_mode_result(value);
            if ((aes_start_count !== 2) || (aes_done_count !== 2)) begin
                $display("Expected two AES blocks: phase=%0d starts=%0d done=%0d",
                         phase, aes_start_count, aes_done_count);
                $fatal(1);
            end
        end
    endtask

    initial begin
        awvalid = 1'b0;
        awaddr = 32'd0;
        wvalid = 1'b0;
        wdata = 32'd0;
        wstrb = 4'd0;
        bready = 1'b0;
        arvalid = 1'b0;
        araddr = 32'd0;
        rready = 1'b0;
        test_phase = PHASE_IDLE;
        status_word = 32'd0;
        input_block_1 = 128'd0;
        input_block_2 = 128'd0;
        input_key = 128'd0;
        input_iv_counter = 128'd0;
        mode_result = 256'd0;
        cbc_ciphertext = 256'd0;
        cbc_plaintext = 256'd0;
        ctr_ciphertext = 256'd0;
        ctr_plaintext = 256'd0;
        clear_aes_counts = 1'b0;
        aes_start_count = 0;
        aes_done_count = 0;

        repeat (5) @(posedge clk);
        rst_n = 1'b1;
        repeat (2) @(posedge clk);

        $display("AES_MODES_TEST_BEGIN");

        load_mode_inputs(BLOCK0, BLOCK1);
        run_mode(PHASE_CBC_ENC, ALGO_AES128_CBC_ENC_2B, mode_result);
        cbc_ciphertext = mode_result;
        if (cbc_ciphertext !== CBC_EXPECTED) begin
            $display("AES-CBC encrypt mismatch: %h", cbc_ciphertext);
            $fatal(1);
        end
        $display("AES_MODE_CBC_ENC PASS result=%h", cbc_ciphertext);

        load_mode_inputs(cbc_ciphertext[127:0], cbc_ciphertext[255:128]);
        run_mode(PHASE_CBC_DEC, ALGO_AES128_CBC_DEC_2B, mode_result);
        cbc_plaintext = mode_result;
        if (cbc_plaintext !== PLAINTEXT_2B) begin
            $display("AES-CBC decrypt mismatch: %h", cbc_plaintext);
            $fatal(1);
        end
        $display("AES_MODE_CBC_DEC PASS result=%h", cbc_plaintext);

        load_mode_inputs(BLOCK0, BLOCK1);
        run_mode(PHASE_CTR_ENC, ALGO_AES128_CTR_2B, mode_result);
        ctr_ciphertext = mode_result;
        if (ctr_ciphertext !== CTR_EXPECTED) begin
            $display("AES-CTR encrypt mismatch: %h", ctr_ciphertext);
            $fatal(1);
        end
        $display("AES_MODE_CTR_ENC PASS result=%h", ctr_ciphertext);

        load_mode_inputs(ctr_ciphertext[127:0], ctr_ciphertext[255:128]);
        run_mode(PHASE_CTR_DEC, ALGO_AES128_CTR_2B, mode_result);
        ctr_plaintext = mode_result;
        if (ctr_plaintext !== PLAINTEXT_2B) begin
            $display("AES-CTR decrypt mismatch: %h", ctr_plaintext);
            $fatal(1);
        end
        $display("AES_MODE_CTR_DEC PASS result=%h", ctr_plaintext);

        test_phase = PHASE_DONE;
        $display("AES_MODES_TEST_END");
        $display("AES CBC/CTR mode tests passed.");
        $finish;
    end

    initial begin
        #200000;
        $display("AES mode testbench timed out.");
        $fatal(1);
    end
endmodule
