`timescale 1ns / 1ps

module tb_sha256_core;
    reg clk;
    reg rst_n;
    reg start;
    reg init;
    reg [255:0] state_in;
    reg [511:0] block;
    wire ready;
    wire busy;
    wire done;
    wire [255:0] digest;

    reg [255:0] mid_state;
    reg [255:0] final_digest;
    integer done_count;

    sha256_core dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .init(init),
        .state_in(state_in),
        .block(block),
        .ready(ready),
        .busy(busy),
        .done(done),
        .digest(digest)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (!rst_n)
            done_count <= 0;
        else if (done)
            done_count <= done_count + 1;
    end

    initial begin
        $dumpfile("build/tb_sha256_core.vcd");
        $dumpvars(0, tb_sha256_core);
    end

    task run_block;
        input init_i;
        input [255:0] state_i;
        input [511:0] block_i;
        output [255:0] digest_o;
        begin
            wait (ready);
            @(posedge clk);
            init <= init_i;
            state_in <= state_i;
            block <= block_i;
            start <= 1'b1;
            @(posedge clk);
            start <= 1'b0;
            wait (done);
            #1;
            digest_o = digest;
        end
    endtask

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        start = 1'b0;
        init = 1'b1;
        state_in = 256'd0;
        block = 512'd0;
        done_count = 0;

        repeat (4) @(posedge clk);
        rst_n = 1'b1;
        repeat (2) @(posedge clk);

        run_block(
            1'b1,
            256'd0,
            512'h61626380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018,
            final_digest
        );
        if (final_digest !== 256'hba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad) begin
            $display("single-block SHA mismatch: %h", final_digest);
            $fatal(1);
        end

        done_count = 0;
        wait (ready);
        @(posedge clk);
        init <= 1'b1;
        state_in <= 256'd0;
        block <= 512'h61626380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018;
        start <= 1'b1;
        wait (done);
        repeat (10) @(posedge clk);
        if (done_count !== 1) begin
            $display("held start retriggered the core: done_count=%0d", done_count);
            $fatal(1);
        end
        start <= 1'b0;
        repeat (2) @(posedge clk);

        run_block(
            1'b1,
            256'd0,
            512'h61616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161,
            mid_state
        );
        run_block(
            1'b0,
            mid_state,
            512'h80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200,
            final_digest
        );
        if (final_digest !== 256'hffe054fe7ae0cb6dc65c3af9b61d5209f439851db43d0ba5997337df154668eb) begin
            $display("two-block SHA mismatch: %h", final_digest);
            $fatal(1);
        end

        $display("SHA-256 core tests passed.");
        $finish;
    end
endmodule
