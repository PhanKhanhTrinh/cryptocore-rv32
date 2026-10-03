`timescale 1ns / 1ps

module tb_axi_lite_crossbar;
    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg m_awvalid = 1'b0;
    wire m_awready;
    reg [31:0] m_awaddr = 32'd0;
    reg [2:0] m_awprot = 3'd0;
    reg m_wvalid = 1'b0;
    wire m_wready;
    reg [31:0] m_wdata = 32'd0;
    reg [3:0] m_wstrb = 4'd0;
    wire m_bvalid;
    reg m_bready = 1'b0;
    reg m_arvalid = 1'b0;
    wire m_arready;
    reg [31:0] m_araddr = 32'd0;
    reg [2:0] m_arprot = 3'd0;
    wire m_rvalid;
    reg m_rready = 1'b0;
    wire [31:0] m_rdata;

    wire rom_awvalid, rom_wvalid, rom_bready, rom_arvalid, rom_rready;
    wire ram_awvalid, ram_wvalid, ram_bready, ram_arvalid, ram_rready;
    wire cry_awvalid, cry_wvalid, cry_bready, cry_arvalid, cry_rready;
    wire [31:0] rom_awaddr, rom_wdata, rom_araddr;
    wire [31:0] ram_awaddr, ram_wdata, ram_araddr;
    wire [31:0] cry_awaddr, cry_wdata, cry_araddr;
    wire [3:0] rom_wstrb, ram_wstrb, cry_wstrb;

    reg rom_bvalid = 1'b0;
    reg ram_bvalid = 1'b0;
    reg cry_bvalid = 1'b0;
    reg rom_rvalid = 1'b0;
    reg ram_rvalid = 1'b0;
    reg cry_rvalid = 1'b0;

    integer ram_aw_count;
    integer ram_w_count;
    integer cry_w_count;

    axi_lite_crossbar dut (
        .clk(clk),
        .rst_n(rst_n),
        .m_awvalid(m_awvalid),
        .m_awready(m_awready),
        .m_awaddr(m_awaddr),
        .m_awprot(m_awprot),
        .m_wvalid(m_wvalid),
        .m_wready(m_wready),
        .m_wdata(m_wdata),
        .m_wstrb(m_wstrb),
        .m_bvalid(m_bvalid),
        .m_bready(m_bready),
        .m_arvalid(m_arvalid),
        .m_arready(m_arready),
        .m_araddr(m_araddr),
        .m_arprot(m_arprot),
        .m_rvalid(m_rvalid),
        .m_rready(m_rready),
        .m_rdata(m_rdata),
        .rom_awvalid(rom_awvalid),
        .rom_awready(1'b1),
        .rom_awaddr(rom_awaddr),
        .rom_wvalid(rom_wvalid),
        .rom_wready(1'b1),
        .rom_wdata(rom_wdata),
        .rom_wstrb(rom_wstrb),
        .rom_bvalid(rom_bvalid),
        .rom_bready(rom_bready),
        .rom_arvalid(rom_arvalid),
        .rom_arready(1'b1),
        .rom_araddr(rom_araddr),
        .rom_rvalid(rom_rvalid),
        .rom_rready(rom_rready),
        .rom_rdata(32'h1111_1111),
        .ram_awvalid(ram_awvalid),
        .ram_awready(1'b1),
        .ram_awaddr(ram_awaddr),
        .ram_wvalid(ram_wvalid),
        .ram_wready(1'b1),
        .ram_wdata(ram_wdata),
        .ram_wstrb(ram_wstrb),
        .ram_bvalid(ram_bvalid),
        .ram_bready(ram_bready),
        .ram_arvalid(ram_arvalid),
        .ram_arready(1'b1),
        .ram_araddr(ram_araddr),
        .ram_rvalid(ram_rvalid),
        .ram_rready(ram_rready),
        .ram_rdata(32'h2222_2222),
        .cry_awvalid(cry_awvalid),
        .cry_awready(1'b1),
        .cry_awaddr(cry_awaddr),
        .cry_wvalid(cry_wvalid),
        .cry_wready(1'b1),
        .cry_wdata(cry_wdata),
        .cry_wstrb(cry_wstrb),
        .cry_bvalid(cry_bvalid),
        .cry_bready(cry_bready),
        .cry_arvalid(cry_arvalid),
        .cry_arready(1'b1),
        .cry_araddr(cry_araddr),
        .cry_rvalid(cry_rvalid),
        .cry_rready(cry_rready),
        .cry_rdata(32'h3333_3333)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (!rst_n) begin
            ram_aw_count <= 0;
            ram_w_count <= 0;
            cry_w_count <= 0;
        end else begin
            if (ram_awvalid) ram_aw_count <= ram_aw_count + 1;
            if (ram_wvalid) ram_w_count <= ram_w_count + 1;
            if (cry_wvalid) cry_w_count <= cry_w_count + 1;
            if (ram_awvalid && ram_wvalid)
                ram_bvalid <= 1'b1;
            if (ram_bvalid && ram_bready)
                ram_bvalid <= 1'b0;
        end
    end

    initial begin
        repeat (3) @(posedge clk);
        rst_n = 1'b1;
        repeat (2) @(posedge clk);

        m_awaddr <= 32'h1000_0004;
        m_awvalid <= 1'b1;
        @(posedge clk);
        if (!m_awready) $fatal(1, "AW was not accepted");
        m_awvalid <= 1'b0;

        repeat (2) @(posedge clk);
        m_awaddr <= 32'h2000_0000;
        m_wdata <= 32'ha5a5_5a5a;
        m_wstrb <= 4'hf;
        m_wvalid <= 1'b1;
        @(posedge clk);
        if (!m_wready) $fatal(1, "W was not accepted");
        m_wvalid <= 1'b0;

        repeat (4) @(posedge clk);
        if (ram_aw_count !== 1 || ram_w_count !== 1 || cry_w_count !== 0) begin
            $display("Crossbar split AW/W route mismatch: ram_aw=%0d ram_w=%0d cry_w=%0d",
                ram_aw_count, ram_w_count, cry_w_count);
            $fatal(1);
        end

        $display("AXI-Lite crossbar tests passed.");
        $finish;
    end
endmodule
