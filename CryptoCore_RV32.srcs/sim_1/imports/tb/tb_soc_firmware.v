`timescale 1ns / 1ps

module tb_soc_firmware;
    reg clk = 1'b0;
    reg rst_n = 1'b0;
    wire trap_o;
    wire axi_read_o;
    wire axi_write_o;
    wire [31:0] fw_magic_o;
    wire [31:0] fw_passmask_o;
    wire [31:0] fw_stage_o;
    wire [31:0] fw_detail_o;
    integer cycle_count = 0;
    integer stage1_cycle = -1;
    integer stage2_cycle = -1;
    integer stage3_cycle = -1;
    integer pass1_cycle = -1;
    integer pass2_cycle = -1;
    integer pass3_cycle = -1;
    integer done_cycle = -1;
    integer report_done_cycle;
    reg [31:0] last_stage = 32'hffff_ffff;
    reg [31:0] last_passmask = 32'hffff_ffff;

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (!rst_n) begin
            cycle_count <= 0;
            stage1_cycle <= -1;
            stage2_cycle <= -1;
            stage3_cycle <= -1;
            pass1_cycle <= -1;
            pass2_cycle <= -1;
            pass3_cycle <= -1;
            done_cycle <= -1;
            last_stage <= 32'hffff_ffff;
            last_passmask <= 32'hffff_ffff;
        end else begin
            cycle_count <= cycle_count + 1;
            if (fw_stage_o != last_stage) begin
                if (fw_stage_o == 32'd1) stage1_cycle <= cycle_count;
                if (fw_stage_o == 32'd2) stage2_cycle <= cycle_count;
                if (fw_stage_o == 32'd3) stage3_cycle <= cycle_count;
                last_stage <= fw_stage_o;
            end
            if (fw_passmask_o != last_passmask) begin
                if (fw_passmask_o == 32'h0000_0001) pass1_cycle <= cycle_count;
                if (fw_passmask_o == 32'h0000_0003) pass2_cycle <= cycle_count;
                if (fw_passmask_o == 32'h0000_0007) pass3_cycle <= cycle_count;
                last_passmask <= fw_passmask_o;
            end
            if ((fw_magic_o == 32'h600d0001) && (done_cycle < 0))
                done_cycle <= cycle_count;
        end
    end

    riscv_crypto_soc dut (
        .clk(clk),
        .rst_n(rst_n),
        .trap_o(trap_o),
        .axi_read_o(axi_read_o),
        .axi_write_o(axi_write_o),
        .fw_magic_o(fw_magic_o),
        .fw_passmask_o(fw_passmask_o),
        .fw_stage_o(fw_stage_o),
        .fw_detail_o(fw_detail_o)
    );

    initial begin
        repeat (10) @(posedge clk);
        rst_n = 1'b1;

        repeat (20000) begin
            @(posedge clk);
            if (fw_magic_o == 32'h600d0001) begin
                report_done_cycle = (done_cycle >= 0) ? done_cycle : cycle_count;
                $display("HW_BENCH_BEGIN");
                $display("HW_BENCH_AES cycles=%0d start=%0d done=%0d", pass1_cycle - stage1_cycle, stage1_cycle, pass1_cycle);
                $display("HW_BENCH_SHA cycles=%0d start=%0d done=%0d", pass2_cycle - stage2_cycle, stage2_cycle, pass2_cycle);
                $display("HW_BENCH_CHACHA cycles=%0d start=%0d done=%0d", pass3_cycle - stage3_cycle, stage3_cycle, pass3_cycle);
                $display("HW_BENCH_TOTAL cycles=%0d done=%0d", report_done_cycle, report_done_cycle);
                $display("HW_BENCH_END");
                if (fw_passmask_o !== 32'h0000_0007) begin
                    $display("Firmware passmask mismatch: %h", fw_passmask_o);
                    $fatal(1);
                end
                if (trap_o !== 1'b0) begin
                    $display("Unexpected trap during firmware run");
                    $fatal(1);
                end
                repeat (1000) @(posedge clk);
                if (trap_o !== 1'b0) begin
                    $display("Unexpected trap after firmware pass");
                    $fatal(1);
                end
                if (fw_magic_o !== 32'h600d0001 || fw_passmask_o !== 32'h0000_0007 || fw_stage_o !== 32'h0000_0000) begin
                    $display("Firmware status changed after pass. magic=%h passmask=%h stage=%h detail=%h",
                        fw_magic_o, fw_passmask_o, fw_stage_o, fw_detail_o);
                    $fatal(1);
                end
                $display("Firmware end-to-end test passed and remained stable. magic=%h passmask=%h",
                    fw_magic_o, fw_passmask_o);
                $finish;
            end
            if (fw_magic_o[31:16] == 16'hdead) begin
                $display("Firmware failure. magic=%h passmask=%h stage=%h detail=%h", fw_magic_o, fw_passmask_o, fw_stage_o, fw_detail_o);
                $display("crypto: busy=%0d done=%0d algo=%h ctrl=%h status=%h buf20=%h",
                    dut.u_crypto.op_busy, dut.u_crypto.op_done, dut.u_crypto.algo_sel_reg,
                    dut.u_crypto.ctrl_reg, {29'd0, dut.u_crypto.op_error, dut.u_crypto.op_done, dut.u_crypto.op_busy},
                    dut.u_crypto.buf_reg[20]);
                $fatal(1);
            end
        end

        $display("Firmware timeout. magic=%h passmask=%h stage=%h detail=%h", fw_magic_o, fw_passmask_o, fw_stage_o, fw_detail_o);
        $display("crypto: busy=%0d done=%0d algo=%h ctrl=%h status=%h aw=%0d w=%0d b=%0d ar=%0d r=%0d",
            dut.u_crypto.op_busy, dut.u_crypto.op_done, dut.u_crypto.algo_sel_reg, dut.u_crypto.ctrl_reg,
            {29'd0, dut.u_crypto.op_error, dut.u_crypto.op_done, dut.u_crypto.op_busy},
            dut.cry_awvalid, dut.cry_wvalid, dut.cry_bvalid, dut.cry_arvalid, dut.cry_rvalid);
        $display("buf0=%h buf4=%h buf20=%h aes_busy=%0d aes_done=%0d",
            dut.u_crypto.buf_reg[0], dut.u_crypto.buf_reg[4], dut.u_crypto.buf_reg[20],
            dut.u_crypto.aes_busy, dut.u_crypto.aes_done);
        $fatal(1);
    end
endmodule
