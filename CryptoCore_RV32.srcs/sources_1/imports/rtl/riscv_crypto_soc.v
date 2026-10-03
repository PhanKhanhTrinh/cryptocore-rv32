`timescale 1ns / 1ps

module riscv_crypto_soc #(
    parameter ROM_INIT_FILE = "boot_rom.hex"
) (
    input wire clk,
    input wire rst_n,
    output wire trap_o,
    output wire axi_read_o,
    output wire axi_write_o,
    output wire [31:0] fw_magic_o,
    output wire [31:0] fw_passmask_o,
    output wire [31:0] fw_stage_o,
    output wire [31:0] fw_detail_o
);
    wire trap;
    wire mem_axi_awvalid;
    wire mem_axi_awready;
    wire [31:0] mem_axi_awaddr;
    wire [2:0] mem_axi_awprot;
    wire mem_axi_wvalid;
    wire mem_axi_wready;
    wire [31:0] mem_axi_wdata;
    wire [3:0] mem_axi_wstrb;
    wire mem_axi_bvalid;
    wire mem_axi_bready;
    wire mem_axi_arvalid;
    wire mem_axi_arready;
    wire [31:0] mem_axi_araddr;
    wire [2:0] mem_axi_arprot;
    wire mem_axi_rvalid;
    wire mem_axi_rready;
    wire [31:0] mem_axi_rdata;

    wire rom_awvalid, rom_awready, rom_wvalid, rom_wready, rom_bvalid, rom_bready, rom_arvalid, rom_arready, rom_rvalid, rom_rready;
    wire ram_awvalid, ram_awready, ram_wvalid, ram_wready, ram_bvalid, ram_bready, ram_arvalid, ram_arready, ram_rvalid, ram_rready;
    wire cry_awvalid, cry_awready, cry_wvalid, cry_wready, cry_bvalid, cry_bready, cry_arvalid, cry_arready, cry_rvalid, cry_rready;
    wire [31:0] rom_awaddr, rom_wdata, rom_araddr, rom_rdata;
    wire [31:0] ram_awaddr, ram_wdata, ram_araddr, ram_rdata;
    wire [31:0] cry_awaddr, cry_wdata, cry_araddr, cry_rdata;
    wire [3:0] rom_wstrb, ram_wstrb, cry_wstrb;
    wire [31:0] ram_debug_word0;
    wire [31:0] ram_debug_word1;
    wire [31:0] ram_debug_word2;
    wire [31:0] ram_debug_word3;

    picorv32_axi #(
        .ENABLE_COUNTERS(0),
        .ENABLE_COUNTERS64(0),
        .ENABLE_IRQ(0),
        .ENABLE_MUL(0),
        .ENABLE_DIV(0),
        .CATCH_ILLINSN(1),
        .PROGADDR_RESET(32'h0000_0000),
        .STACKADDR(32'h1000_1000)
    ) u_cpu (
        .clk(clk),
        .resetn(rst_n),
        .trap(trap),
        .mem_axi_awvalid(mem_axi_awvalid),
        .mem_axi_awready(mem_axi_awready),
        .mem_axi_awaddr(mem_axi_awaddr),
        .mem_axi_awprot(mem_axi_awprot),
        .mem_axi_wvalid(mem_axi_wvalid),
        .mem_axi_wready(mem_axi_wready),
        .mem_axi_wdata(mem_axi_wdata),
        .mem_axi_wstrb(mem_axi_wstrb),
        .mem_axi_bvalid(mem_axi_bvalid),
        .mem_axi_bready(mem_axi_bready),
        .mem_axi_arvalid(mem_axi_arvalid),
        .mem_axi_arready(mem_axi_arready),
        .mem_axi_araddr(mem_axi_araddr),
        .mem_axi_arprot(mem_axi_arprot),
        .mem_axi_rvalid(mem_axi_rvalid),
        .mem_axi_rready(mem_axi_rready),
        .mem_axi_rdata(mem_axi_rdata),
        .pcpi_valid(),
        .pcpi_insn(),
        .pcpi_rs1(),
        .pcpi_rs2(),
        .pcpi_wr(1'b0),
        .pcpi_rd(32'd0),
        .pcpi_wait(1'b0),
        .pcpi_ready(1'b0),
        .irq(32'd0),
        .eoi(),
        .trace_valid(),
        .trace_data()
    );

    axi_lite_crossbar u_xbar (
        .clk(clk),
        .rst_n(rst_n),
        .m_awvalid(mem_axi_awvalid),
        .m_awready(mem_axi_awready),
        .m_awaddr(mem_axi_awaddr),
        .m_awprot(mem_axi_awprot),
        .m_wvalid(mem_axi_wvalid),
        .m_wready(mem_axi_wready),
        .m_wdata(mem_axi_wdata),
        .m_wstrb(mem_axi_wstrb),
        .m_bvalid(mem_axi_bvalid),
        .m_bready(mem_axi_bready),
        .m_arvalid(mem_axi_arvalid),
        .m_arready(mem_axi_arready),
        .m_araddr(mem_axi_araddr),
        .m_arprot(mem_axi_arprot),
        .m_rvalid(mem_axi_rvalid),
        .m_rready(mem_axi_rready),
        .m_rdata(mem_axi_rdata),
        .rom_awvalid(rom_awvalid),
        .rom_awready(rom_awready),
        .rom_awaddr(rom_awaddr),
        .rom_wvalid(rom_wvalid),
        .rom_wready(rom_wready),
        .rom_wdata(rom_wdata),
        .rom_wstrb(rom_wstrb),
        .rom_bvalid(rom_bvalid),
        .rom_bready(rom_bready),
        .rom_arvalid(rom_arvalid),
        .rom_arready(rom_arready),
        .rom_araddr(rom_araddr),
        .rom_rvalid(rom_rvalid),
        .rom_rready(rom_rready),
        .rom_rdata(rom_rdata),
        .ram_awvalid(ram_awvalid),
        .ram_awready(ram_awready),
        .ram_awaddr(ram_awaddr),
        .ram_wvalid(ram_wvalid),
        .ram_wready(ram_wready),
        .ram_wdata(ram_wdata),
        .ram_wstrb(ram_wstrb),
        .ram_bvalid(ram_bvalid),
        .ram_bready(ram_bready),
        .ram_arvalid(ram_arvalid),
        .ram_arready(ram_arready),
        .ram_araddr(ram_araddr),
        .ram_rvalid(ram_rvalid),
        .ram_rready(ram_rready),
        .ram_rdata(ram_rdata),
        .cry_awvalid(cry_awvalid),
        .cry_awready(cry_awready),
        .cry_awaddr(cry_awaddr),
        .cry_wvalid(cry_wvalid),
        .cry_wready(cry_wready),
        .cry_wdata(cry_wdata),
        .cry_wstrb(cry_wstrb),
        .cry_bvalid(cry_bvalid),
        .cry_bready(cry_bready),
        .cry_arvalid(cry_arvalid),
        .cry_arready(cry_arready),
        .cry_araddr(cry_araddr),
        .cry_rvalid(cry_rvalid),
        .cry_rready(cry_rready),
        .cry_rdata(cry_rdata)
    );

    axi_lite_rom #(
        .MEM_WORDS(512),
        .INIT_FILE(ROM_INIT_FILE)
    ) u_rom (
        .clk(clk),
        .rst_n(rst_n),
        .s_axi_awvalid(rom_awvalid),
        .s_axi_awready(rom_awready),
        .s_axi_awaddr(rom_awaddr),
        .s_axi_wvalid(rom_wvalid),
        .s_axi_wready(rom_wready),
        .s_axi_wdata(rom_wdata),
        .s_axi_wstrb(rom_wstrb),
        .s_axi_bvalid(rom_bvalid),
        .s_axi_bready(rom_bready),
        .s_axi_arvalid(rom_arvalid),
        .s_axi_arready(rom_arready),
        .s_axi_araddr(rom_araddr),
        .s_axi_rvalid(rom_rvalid),
        .s_axi_rready(rom_rready),
        .s_axi_rdata(rom_rdata)
    );

    axi_lite_ram #(
        .MEM_WORDS(1024)
    ) u_ram (
        .clk(clk),
        .rst_n(rst_n),
        .s_axi_awvalid(ram_awvalid),
        .s_axi_awready(ram_awready),
        .s_axi_awaddr(ram_awaddr),
        .s_axi_wvalid(ram_wvalid),
        .s_axi_wready(ram_wready),
        .s_axi_wdata(ram_wdata),
        .s_axi_wstrb(ram_wstrb),
        .s_axi_bvalid(ram_bvalid),
        .s_axi_bready(ram_bready),
        .s_axi_arvalid(ram_arvalid),
        .s_axi_arready(ram_arready),
        .s_axi_araddr(ram_araddr),
        .s_axi_rvalid(ram_rvalid),
        .s_axi_rready(ram_rready),
        .s_axi_rdata(ram_rdata),
        .debug_word0(ram_debug_word0),
        .debug_word1(ram_debug_word1),
        .debug_word2(ram_debug_word2),
        .debug_word3(ram_debug_word3)
    );

    crypto_coprocessor_axi u_crypto (
        .clk(clk),
        .rst_n(rst_n),
        .s_axi_awvalid(cry_awvalid),
        .s_axi_awready(cry_awready),
        .s_axi_awaddr(cry_awaddr),
        .s_axi_wvalid(cry_wvalid),
        .s_axi_wready(cry_wready),
        .s_axi_wdata(cry_wdata),
        .s_axi_wstrb(cry_wstrb),
        .s_axi_bvalid(cry_bvalid),
        .s_axi_bready(cry_bready),
        .s_axi_arvalid(cry_arvalid),
        .s_axi_arready(cry_arready),
        .s_axi_araddr(cry_araddr),
        .s_axi_rvalid(cry_rvalid),
        .s_axi_rready(cry_rready),
        .s_axi_rdata(cry_rdata)
    );

    assign trap_o = trap;
    assign axi_read_o = mem_axi_arvalid;
    assign axi_write_o = mem_axi_awvalid | mem_axi_wvalid;
    assign fw_magic_o = ram_debug_word0;
    assign fw_passmask_o = ram_debug_word1;
    assign fw_stage_o = ram_debug_word2;
    assign fw_detail_o = ram_debug_word3;
endmodule
