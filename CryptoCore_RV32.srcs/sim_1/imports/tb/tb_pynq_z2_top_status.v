`timescale 1ns / 1ps

module tb_pynq_z2_top_status;
    reg clk125 = 1'b0;
    reg [3:0] btn = 4'd0;
    reg [1:0] sw = 2'd0;
    wire [3:0] led;
    wire [7:0] jb;

    always #4 clk125 = ~clk125;

    pynq_z2_top dut (
        .CLK125MHZ(clk125),
        .BTN(btn),
        .SW(sw),
        .LED(led),
        .JB(jb)
    );

    initial begin
        force dut.clk50 = clk125;
        force dut.clk_locked = 1'b1;
        force dut.rst_n = 1'b1;
        force dut.heartbeat_cnt = 27'h2000000;
        force dut.activity_stretch = 24'h000001;
        force dut.soc_trap = 1'b0;
        force dut.soc_axi_read = 1'b1;
        force dut.soc_axi_write = 1'b0;
        force dut.fw_magic = 32'h600d0001;
        force dut.fw_passmask = 32'h00000007;
        force dut.fw_stage = 32'h00000001;

        sw = 2'b00;
        #20;
        if (led !== 4'b1001) begin
            $display("System LED view mismatch: led=%b", led);
            $fatal(1);
        end

        sw = 2'b01;
        #20;
        if (led !== 4'b0111) begin
            $display("Firmware LED view mismatch: led=%b", led);
            $fatal(1);
        end

        if (jb[1] !== 1'b1 || jb[2] !== 1'b0 || jb[3] !== 1'b1 || jb[4] !== 1'b0 ||
            jb[5] !== 1'b0 || jb[6] !== 1'b1 || jb[7] !== 1'b1) begin
            $display("JB debug mapping mismatch: jb=%b", jb);
            $fatal(1);
        end

        $display("PYNQ-Z2 top-level status mapping test passed.");
        $finish;
    end
endmodule
