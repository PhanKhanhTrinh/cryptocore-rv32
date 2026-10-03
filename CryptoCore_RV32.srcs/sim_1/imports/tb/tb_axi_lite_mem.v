`timescale 1ns / 1ps

module tb_axi_lite_mem;
    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg awvalid = 1'b0;
    wire awready;
    reg [31:0] awaddr = 32'd0;
    reg wvalid = 1'b0;
    wire wready;
    reg [31:0] wdata = 32'd0;
    reg [3:0] wstrb = 4'd0;
    wire bvalid;
    reg bready = 1'b0;
    reg arvalid = 1'b0;
    wire arready;
    reg [31:0] araddr = 32'd0;
    wire rvalid;
    reg rready = 1'b0;
    wire [31:0] rdata;
    wire [31:0] debug_word0;
    wire [31:0] debug_word1;
    wire [31:0] debug_word2;
    wire [31:0] debug_word3;

    reg rom_awvalid = 1'b0;
    wire rom_awready;
    reg [31:0] rom_awaddr = 32'd0;
    reg rom_wvalid = 1'b0;
    wire rom_wready;
    reg [31:0] rom_wdata = 32'd0;
    reg [3:0] rom_wstrb = 4'd0;
    wire rom_bvalid;
    reg rom_bready = 1'b0;

    reg [31:0] read_data;

    axi_lite_ram #(
        .MEM_WORDS(16)
    ) u_ram (
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
        .s_axi_rdata(rdata),
        .debug_word0(debug_word0),
        .debug_word1(debug_word1),
        .debug_word2(debug_word2),
        .debug_word3(debug_word3)
    );

    axi_lite_rom #(
        .MEM_WORDS(512),
        .INIT_FILE("boot_rom.hex")
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
        .s_axi_arvalid(1'b0),
        .s_axi_arready(),
        .s_axi_araddr(32'd0),
        .s_axi_rvalid(),
        .s_axi_rready(1'b0),
        .s_axi_rdata()
    );

    always #5 clk = ~clk;

    task ram_write_aw_first;
        input [31:0] addr;
        input [31:0] data;
        begin
            @(posedge clk);
            awaddr <= addr;
            awvalid <= 1'b1;
            @(posedge clk);
            if (!awready) $fatal(1, "RAM AW was not accepted");
            awvalid <= 1'b0;
            repeat (2) @(posedge clk);
            wdata <= data;
            wstrb <= 4'hf;
            wvalid <= 1'b1;
            bready <= 1'b1;
            @(posedge clk);
            if (!wready) $fatal(1, "RAM W was not accepted");
            wvalid <= 1'b0;
            wait (bvalid);
            @(posedge clk);
            bready <= 1'b0;
        end
    endtask

    task ram_write_w_first;
        input [31:0] addr;
        input [31:0] data;
        begin
            @(posedge clk);
            wdata <= data;
            wstrb <= 4'hf;
            wvalid <= 1'b1;
            @(posedge clk);
            if (!wready) $fatal(1, "RAM W was not accepted");
            wvalid <= 1'b0;
            repeat (2) @(posedge clk);
            awaddr <= addr;
            awvalid <= 1'b1;
            bready <= 1'b1;
            @(posedge clk);
            if (!awready) $fatal(1, "RAM AW was not accepted");
            awvalid <= 1'b0;
            wait (bvalid);
            @(posedge clk);
            bready <= 1'b0;
        end
    endtask

    task ram_read;
        input [31:0] addr;
        output [31:0] data;
        begin
            @(posedge clk);
            araddr <= addr;
            arvalid <= 1'b1;
            rready <= 1'b1;
            @(posedge clk);
            if (!arready) $fatal(1, "RAM AR was not accepted");
            arvalid <= 1'b0;
            wait (rvalid);
            data = rdata;
            @(posedge clk);
            rready <= 1'b0;
        end
    endtask

    initial begin
        repeat (3) @(posedge clk);
        rst_n = 1'b1;
        repeat (2) @(posedge clk);

        ram_write_aw_first(32'h0000_0004, 32'haabb_ccdd);
        ram_read(32'h0000_0004, read_data);
        if (read_data !== 32'haabb_ccdd) begin
            $display("RAM AW-first split write mismatch: %h", read_data);
            $fatal(1);
        end

        ram_write_w_first(32'h0000_0008, 32'h1122_3344);
        ram_read(32'h0000_0008, read_data);
        if (read_data !== 32'h1122_3344) begin
            $display("RAM W-first split write mismatch: %h", read_data);
            $fatal(1);
        end

        @(posedge clk);
        rom_awaddr <= 32'h0000_0000;
        rom_awvalid <= 1'b1;
        @(posedge clk);
        if (!rom_awready) $fatal(1, "ROM AW was not accepted");
        rom_awvalid <= 1'b0;
        repeat (2) @(posedge clk);
        rom_wdata <= 32'hdead_beef;
        rom_wstrb <= 4'hf;
        rom_wvalid <= 1'b1;
        rom_bready <= 1'b1;
        @(posedge clk);
        if (!rom_wready) $fatal(1, "ROM W was not accepted");
        rom_wvalid <= 1'b0;
        wait (rom_bvalid);
        @(posedge clk);
        rom_bready <= 1'b0;

        $display("AXI-Lite memory tests passed.");
        $finish;
    end
endmodule
