`timescale 1ns / 1ps

module tb_crypto_axi;
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

    reg [31:0] status_word;
    reg [127:0] aes_result;
    reg [255:0] two_block_result;
    reg [255:0] sha_result;
    reg [511:0] cha_result;
    integer i;
    integer poll_count;

    localparam BASE = 32'h0000_0000;
    localparam REG_CTRL = BASE + 32'h00;
    localparam REG_STATUS = BASE + 32'h04;
    localparam REG_ALGO = BASE + 32'h08;
    localparam REG_BUF = BASE + 32'h10;
    localparam ALGO_AES128_ENC        = 32'd0;
    localparam ALGO_SHA256_1BLOCK     = 32'd1;
    localparam ALGO_CHACHA20_BLOCK    = 32'd2;
    localparam ALGO_AES128_DEC        = 32'd3;
    localparam ALGO_AES128_CBC_ENC_2B = 32'd4;
    localparam ALGO_AES128_CBC_DEC_2B = 32'd5;
    localparam ALGO_AES128_CTR_2B     = 32'd6;
    localparam ALGO_AES128_GCM_1B     = 32'd7;
    localparam ALGO_SHA256_2BLOCK     = 32'd8;
    localparam ALGO_REMOVED_CHACHA20_POLY_1B = 32'd9;
    localparam ALGO_INVALID           = 32'd10;

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

    task axi_write_strb;
        input [31:0] addr;
        input [31:0] data;
        input [3:0]  strb_in;
        begin
            @(posedge clk);
            awaddr <= addr;
            wdata <= data;
            wstrb <= strb_in;
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
            wstrb <= 4'hf;
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

    task wait_done;
        begin
            status_word = 32'd0;
            poll_count = 0;
            while ((status_word[1] == 1'b0) && (status_word[2] == 1'b0) && (poll_count < 10000)) begin
                axi_read(REG_STATUS, status_word);
                poll_count = poll_count + 1;
            end
            if (status_word[2]) begin
                $display("Operation returned ERROR status=%h", status_word);
                $fatal(1);
            end
            if (status_word[1] == 1'b0) begin
                $display("Operation timeout status=%h algo=%h op_state=%0d op_step=%0d aes_start=%0d aes_busy=%0d aes_done=%0d sha_busy=%0d cha_busy=%0d",
                    status_word, dut.algo_sel_reg, dut.op_state, dut.op_step,
                    dut.aes_start, dut.aes_busy, dut.aes_done, dut.sha_busy, dut.cha_busy);
                $fatal(1);
            end
        end
    endtask

    task expect_start_error;
        input [31:0] algo;
        begin
            axi_write(REG_STATUS, 32'h0000_0006);
            axi_write(REG_ALGO, algo);
            axi_write(REG_CTRL, 32'd1);
            axi_read(REG_STATUS, status_word);
            if (status_word !== 32'h0000_0004) begin
                $display("Unsupported algorithm did not set ERROR only. algo=%0d status=%h", algo, status_word);
                $fatal(1);
            end
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

        repeat (5) @(posedge clk);
        rst_n = 1'b1;

        axi_write(REG_ALGO, 32'h1234_5678);
        axi_write_strb(REG_ALGO, 32'h0000_0001, 4'b0001);
        axi_read(REG_ALGO, status_word);
        if (status_word !== 32'h1234_5601) begin
            $display("ALGO_SEL byte strobe mismatch: %h", status_word);
            $fatal(1);
        end
        axi_write(REG_ALGO, 32'd0);
        axi_write_strb(REG_CTRL, 32'h0000_0001, 4'b1110);
        repeat (5) @(posedge clk);
        axi_read(REG_STATUS, status_word);
        if (status_word[1:0] !== 2'b00) begin
            $display("CTRL start ignored WSTRB: status=%h", status_word);
            $fatal(1);
        end
        expect_start_error(ALGO_INVALID);
        axi_write(REG_ALGO, ALGO_AES128_ENC);

        // AES-128 Known Answer Test
        axi_write(REG_BUF + 32'h00, 32'hccddeeff);
        axi_write(REG_BUF + 32'h04, 32'h8899aabb);
        axi_write(REG_BUF + 32'h08, 32'h44556677);
        axi_write(REG_BUF + 32'h0c, 32'h00112233);
        axi_write(REG_BUF + 32'h10, 32'h0c0d0e0f);
        axi_write(REG_BUF + 32'h14, 32'h08090a0b);
        axi_write(REG_BUF + 32'h18, 32'h04050607);
        axi_write(REG_BUF + 32'h1c, 32'h00010203);
        axi_write(REG_ALGO, ALGO_AES128_ENC);
        axi_write(REG_CTRL, 32'd1);
        wait_done;
        for (i = 0; i < 4; i = i + 1)
            axi_read(REG_BUF + 32'h50 + i*4, aes_result[i*32 +: 32]);
        if (aes_result !== 128'h69c4e0d86a7b0430d8cdb78070b4c55a) begin
            $display("AES mismatch: %h", aes_result);
            $fatal(1);
        end

        axi_write(REG_STATUS, 32'h0000_0002);

        // AES-128 direct decrypt
        axi_write(REG_BUF + 32'h00, 32'h70b4c55a);
        axi_write(REG_BUF + 32'h04, 32'hd8cdb780);
        axi_write(REG_BUF + 32'h08, 32'h6a7b0430);
        axi_write(REG_BUF + 32'h0c, 32'h69c4e0d8);
        axi_write(REG_BUF + 32'h10, 32'h0c0d0e0f);
        axi_write(REG_BUF + 32'h14, 32'h08090a0b);
        axi_write(REG_BUF + 32'h18, 32'h04050607);
        axi_write(REG_BUF + 32'h1c, 32'h00010203);
        axi_write(REG_ALGO, ALGO_AES128_DEC);
        axi_write(REG_CTRL, 32'd1);
        wait_done;
        for (i = 0; i < 4; i = i + 1)
            axi_read(REG_BUF + 32'h50 + i*4, aes_result[i*32 +: 32]);
        if (aes_result !== 128'h00112233445566778899aabbccddeeff) begin
            $display("AES decrypt mismatch: %h", aes_result);
            $fatal(1);
        end

        axi_write_strb(REG_STATUS, 32'h0000_0002, 4'b1110);
        axi_read(REG_STATUS, status_word);
        if (!status_word[1]) begin
            $display("STATUS clear ignored WSTRB: status=%h", status_word);
            $fatal(1);
        end
        expect_start_error(ALGO_INVALID);
        axi_write(REG_STATUS, 32'h0000_0002);

        // AES-128 CBC encrypt/decrypt over two blocks. For modes, BUF[8..11] is key and BUF[12..15] is IV/counter.
        axi_write(REG_BUF + 32'h00, 32'hccddeeff);
        axi_write(REG_BUF + 32'h04, 32'h8899aabb);
        axi_write(REG_BUF + 32'h08, 32'h44556677);
        axi_write(REG_BUF + 32'h0c, 32'h00112233);
        axi_write(REG_BUF + 32'h10, 32'h33221100);
        axi_write(REG_BUF + 32'h14, 32'h77665544);
        axi_write(REG_BUF + 32'h18, 32'hbbaa9988);
        axi_write(REG_BUF + 32'h1c, 32'hffeeddcc);
        axi_write(REG_BUF + 32'h20, 32'h0c0d0e0f);
        axi_write(REG_BUF + 32'h24, 32'h08090a0b);
        axi_write(REG_BUF + 32'h28, 32'h04050607);
        axi_write(REG_BUF + 32'h2c, 32'h00010203);
        axi_write(REG_BUF + 32'h30, 32'h03020100);
        axi_write(REG_BUF + 32'h34, 32'h07060504);
        axi_write(REG_BUF + 32'h38, 32'h0b0a0908);
        axi_write(REG_BUF + 32'h3c, 32'h0f0e0d0c);
        axi_write(REG_ALGO, ALGO_AES128_CBC_ENC_2B);
        axi_write(REG_CTRL, 32'd1);
        wait_done;
        for (i = 0; i < 8; i = i + 1)
            axi_read(REG_BUF + 32'h50 + i*4, two_block_result[i*32 +: 32]);
        if (two_block_result !== 256'h5176505d3a1a149f2f66b03f8989085316628846f7334843bc7321cc79661680) begin
            $display("AES-CBC encrypt mismatch: %h", two_block_result);
            $fatal(1);
        end

        axi_write(REG_STATUS, 32'h0000_0002);
        for (i = 0; i < 8; i = i + 1)
            axi_write(REG_BUF + i*4, two_block_result[i*32 +: 32]);
        axi_write(REG_ALGO, ALGO_AES128_CBC_DEC_2B);
        axi_write(REG_CTRL, 32'd1);
        wait_done;
        for (i = 0; i < 8; i = i + 1)
            axi_read(REG_BUF + 32'h50 + i*4, two_block_result[i*32 +: 32]);
        if (two_block_result !== 256'hffeeddccbbaa9988776655443322110000112233445566778899aabbccddeeff) begin
            $display("AES-CBC decrypt mismatch: %h", two_block_result);
            $fatal(1);
        end

        axi_write(REG_STATUS, 32'h0000_0002);
        axi_write(REG_BUF + 32'h00, 32'hccddeeff);
        axi_write(REG_BUF + 32'h04, 32'h8899aabb);
        axi_write(REG_BUF + 32'h08, 32'h44556677);
        axi_write(REG_BUF + 32'h0c, 32'h00112233);
        axi_write(REG_BUF + 32'h10, 32'h33221100);
        axi_write(REG_BUF + 32'h14, 32'h77665544);
        axi_write(REG_BUF + 32'h18, 32'hbbaa9988);
        axi_write(REG_BUF + 32'h1c, 32'hffeeddcc);
        axi_write(REG_ALGO, ALGO_AES128_CTR_2B);
        axi_write(REG_CTRL, 32'd1);
        wait_done;
        for (i = 0; i < 8; i = i + 1)
            axi_read(REG_BUF + 32'h50 + i*4, two_block_result[i*32 +: 32]);
        if (two_block_result !== 256'hb8487969cef4f9cc19d4c4a87a1b105f20b8dba1f0193d9f8c865667a0737795) begin
            $display("AES-CTR mismatch: %h", two_block_result);
            $fatal(1);
        end

        // AES-GCM is compiled out by default in the resource-optimized FPGA build.
        expect_start_error(ALGO_AES128_GCM_1B);
        axi_write(REG_STATUS, 32'h0000_0002);

        // SHA-256("abc") padded single block
        axi_write(REG_BUF + 32'h00, 32'h61626380);
        for (i = 1; i < 15; i = i + 1)
            axi_write(REG_BUF + i*4, 32'h00000000);
        axi_write(REG_BUF + 32'h3c, 32'h00000018);
        axi_write(REG_ALGO, ALGO_SHA256_1BLOCK);
        axi_write(REG_CTRL, 32'd1);
        wait_done;
        for (i = 0; i < 8; i = i + 1)
            axi_read(REG_BUF + 32'h60 + i*4, sha_result[i*32 +: 32]);
        if (sha_result !== 256'hba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad) begin
            $display("SHA mismatch: %h", sha_result);
            $fatal(1);
        end

        axi_write(REG_STATUS, 32'h0000_0002);

        // SHA-256 two-block hash for 64 bytes of "a"; second block contains padding.
        for (i = 0; i < 16; i = i + 1)
            axi_write(REG_BUF + i*4, 32'h61616161);
        axi_write(REG_BUF + 32'h40, 32'h80000000);
        for (i = 17; i < 31; i = i + 1)
            axi_write(REG_BUF + i*4, 32'h00000000);
        axi_write(REG_BUF + 32'h7c, 32'h00000200);
        axi_write(REG_ALGO, ALGO_SHA256_2BLOCK);
        axi_write(REG_CTRL, 32'd1);
        wait_done;
        for (i = 0; i < 8; i = i + 1)
            axi_read(REG_BUF + 32'h60 + i*4, sha_result[i*32 +: 32]);
        if (sha_result !== 256'hffe054fe7ae0cb6dc65c3af9b61d5209f439851db43d0ba5997337df154668eb) begin
            $display("SHA two-block mismatch: %h", sha_result);
            $fatal(1);
        end

        axi_write(REG_STATUS, 32'h0000_0002);

        // ChaCha20 RFC8439 block test
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
        axi_write(REG_ALGO, ALGO_CHACHA20_BLOCK);
        axi_write(REG_CTRL, 32'd1);
        wait_done;
        for (i = 0; i < 16; i = i + 1)
            axi_read(REG_BUF + i*4, cha_result[i*32 +: 32]);
        if (cha_result !== 512'h4e3c50a2e883d0cbb94e16ded19c12b5a2028bd905d7c21409aa9f07466482d24e6cd4c39aaa22040368c033c7f4d1c7c47120a31fdd0f5015593bd1e4e7f110) begin
            $display("ChaCha mismatch: %h", cha_result);
            $fatal(1);
        end

        axi_write(REG_STATUS, 32'h0000_0002);

        // ChaCha20-Poly1305/Poly1305 was removed from RTL to reduce DSP/LUT pressure.
        expect_start_error(ALGO_REMOVED_CHACHA20_POLY_1B);

        $display("All resource-optimized crypto AXI tests passed.");
        $finish;
    end
endmodule
