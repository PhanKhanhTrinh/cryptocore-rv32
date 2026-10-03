`timescale 1ns / 1ps

module tb_soc_trap_firmware;
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

    localparam [31:0] TRAP_MARKER = 32'h5452_4150;

    always #10 clk = ~clk;

    riscv_crypto_soc #(
        .ROM_INIT_FILE("boot_rom_trap.hex")
    ) dut (
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

    always @(posedge clk) begin
        if (rst_n) begin
            cycle_count <= cycle_count + 1;

            if (trap_o) begin
                if (fw_magic_o !== TRAP_MARKER) begin
                    $display("TRAP_TEST_FAIL marker=%h expected=%h",
                             fw_magic_o, TRAP_MARKER);
                    $fatal(1);
                end
                if (fw_stage_o !== 32'h0000_0001) begin
                    $display("TRAP_TEST_FAIL stage=%h expected=00000001",
                             fw_stage_o);
                    $fatal(1);
                end
                if (fw_passmask_o !== 32'h0000_0000) begin
                    $display("TRAP_TEST_FAIL passmask=%h expected=00000000",
                             fw_passmask_o);
                    $fatal(1);
                end

                $display("TRAP_TEST_PASS cycle=%0d trap=%b magic=%h stage=%h",
                         cycle_count, trap_o, fw_magic_o, fw_stage_o);
                $finish;
            end

            if (cycle_count > 500) begin
                $display("TRAP_TEST_TIMEOUT trap=%b magic=%h stage=%h",
                         trap_o, fw_magic_o, fw_stage_o);
                $fatal(1);
            end
        end
    end

    initial begin
        repeat (5) @(posedge clk);
        rst_n = 1'b1;
    end
endmodule
