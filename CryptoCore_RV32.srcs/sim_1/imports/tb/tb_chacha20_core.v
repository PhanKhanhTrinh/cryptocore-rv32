`timescale 1ns / 1ps

module tb_chacha20_core;
    reg clk;
    reg rst_n;
    reg start;
    reg [255:0] key;
    reg [31:0] counter;
    reg [95:0] nonce;
    wire ready;
    wire busy;
    wire done;
    wire [511:0] keystream;

    reg [511:0] result;
    integer done_count;

    localparam [255:0] RFC_KEY =
        256'h1f1e1d1c1b1a191817161514131211100f0e0d0c0b0a09080706050403020100;
    localparam [95:0] RFC_NONCE = 96'h000000004a00000009000000;
    localparam [511:0] RFC_KEYSTREAM =
        512'h4e3c50a2e883d0cbb94e16ded19c12b5a2028bd905d7c21409aa9f07466482d24e6cd4c39aaa22040368c033c7f4d1c7c47120a31fdd0f5015593bd1e4e7f110;

    chacha20_core dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .key(key),
        .counter(counter),
        .nonce(nonce),
        .ready(ready),
        .busy(busy),
        .done(done),
        .keystream(keystream)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (!rst_n)
            done_count <= 0;
        else if (done)
            done_count <= done_count + 1;
    end

    task run_block;
        input [255:0] key_i;
        input [31:0] counter_i;
        input [95:0] nonce_i;
        output [511:0] result_o;
        begin
            wait (ready);
            @(posedge clk);
            key <= key_i;
            counter <= counter_i;
            nonce <= nonce_i;
            start <= 1'b1;
            @(posedge clk);
            start <= 1'b0;
            wait (done);
            #1;
            result_o = keystream;
        end
    endtask

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        start = 1'b0;
        key = 256'd0;
        counter = 32'd0;
        nonce = 96'd0;
        done_count = 0;

        repeat (4) @(posedge clk);
        rst_n = 1'b1;
        repeat (2) @(posedge clk);

        run_block(RFC_KEY, 32'h00000001, RFC_NONCE, result);
        if (result !== RFC_KEYSTREAM) begin
            $display("ChaCha20 RFC block mismatch: %h", result);
            $fatal(1);
        end

        wait (!done);
        @(posedge clk);
        done_count = 0;
        wait (ready);
        @(posedge clk);
        key <= RFC_KEY;
        counter <= 32'h00000001;
        nonce <= RFC_NONCE;
        start <= 1'b1;
        repeat (10) @(posedge clk);
        key <= 256'd0;
        counter <= 32'd0;
        nonce <= 96'd0;
        wait (done);
        repeat (90) @(posedge clk);
        if (done_count !== 1) begin
            $display("held start retriggered the core: done_count=%0d", done_count);
            $fatal(1);
        end
        start <= 1'b0;
        repeat (2) @(posedge clk);

        $display("ChaCha20 core tests passed.");
        $finish;
    end
endmodule
