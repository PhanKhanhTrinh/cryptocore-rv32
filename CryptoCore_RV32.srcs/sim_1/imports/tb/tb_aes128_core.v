`timescale 1ns / 1ps

module tb_aes128_core;
    reg clk;
    reg rst_n;
    reg start;
    reg decrypt;
    reg [127:0] plaintext;
    reg [127:0] key;
    wire ready;
    wire busy;
    wire done;
    wire [127:0] ciphertext;

    reg [127:0] result;
    integer done_count;

    localparam [127:0] KAT_PLAINTEXT = 128'h00112233445566778899aabbccddeeff;
    localparam [127:0] KAT_KEY = 128'h000102030405060708090a0b0c0d0e0f;
    localparam [127:0] KAT_CIPHERTEXT = 128'h69c4e0d86a7b0430d8cdb78070b4c55a;

    aes128_core dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .decrypt(decrypt),
        .plaintext(plaintext),
        .key(key),
        .ready(ready),
        .busy(busy),
        .done(done),
        .ciphertext(ciphertext)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (!rst_n)
            done_count <= 0;
        else if (done)
            done_count <= done_count + 1;
    end

    task run_block;
        input decrypt_i;
        input [127:0] plaintext_i;
        input [127:0] key_i;
        output [127:0] result_o;
        begin
            wait (ready);
            @(posedge clk);
            plaintext <= plaintext_i;
            key <= key_i;
            decrypt <= decrypt_i;
            start <= 1'b1;
            @(posedge clk);
            start <= 1'b0;
            wait (done);
            #1;
            result_o = ciphertext;
        end
    endtask

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        start = 1'b0;
        decrypt = 1'b0;
        plaintext = 128'd0;
        key = 128'd0;
        done_count = 0;

        repeat (4) @(posedge clk);
        rst_n = 1'b1;
        repeat (2) @(posedge clk);

        run_block(1'b0, KAT_PLAINTEXT, KAT_KEY, result);
        if (result !== KAT_CIPHERTEXT) begin
            $display("AES-128 KAT mismatch: %h", result);
            $fatal(1);
        end

        run_block(1'b1, KAT_CIPHERTEXT, KAT_KEY, result);
        if (result !== KAT_PLAINTEXT) begin
            $display("AES-128 decrypt KAT mismatch: %h", result);
            $fatal(1);
        end

        wait (!done);
        @(posedge clk);
        done_count = 0;
        wait (ready);
        @(posedge clk);
        plaintext <= KAT_PLAINTEXT;
        key <= KAT_KEY;
        decrypt <= 1'b0;
        start <= 1'b1;
        repeat (5) @(posedge clk);
        plaintext <= 128'd0;
        key <= 128'd0;
        wait (done);
        #1;
        if (ciphertext !== KAT_CIPHERTEXT) begin
            $display("held-start AES result mismatch: %h", ciphertext);
            $fatal(1);
        end
        repeat (30) @(posedge clk);
        if (done_count !== 1) begin
            $display("held start retriggered the core: done_count=%0d", done_count);
            $fatal(1);
        end
        start <= 1'b0;
        repeat (2) @(posedge clk);

        $display("AES-128 core tests passed.");
        $finish;
    end
endmodule
