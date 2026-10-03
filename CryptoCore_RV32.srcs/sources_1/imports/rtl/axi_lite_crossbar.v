`timescale 1ns / 1ps

module axi_lite_crossbar (
    input wire        clk,
    input wire        rst_n,
    input wire        m_awvalid,
    output wire       m_awready,
    input wire [31:0] m_awaddr,
    input wire [2:0]  m_awprot,
    input wire        m_wvalid,
    output wire       m_wready,
    input wire [31:0] m_wdata,
    input wire [3:0]  m_wstrb,
    output wire       m_bvalid,
    input wire        m_bready,
    input wire        m_arvalid,
    output wire       m_arready,
    input wire [31:0] m_araddr,
    input wire [2:0]  m_arprot,
    output wire       m_rvalid,
    input wire        m_rready,
    output wire [31:0] m_rdata,
    output wire       rom_awvalid,
    input wire        rom_awready,
    output wire [31:0] rom_awaddr,
    output wire       rom_wvalid,
    input wire        rom_wready,
    output wire [31:0] rom_wdata,
    output wire [3:0]  rom_wstrb,
    input wire        rom_bvalid,
    output wire       rom_bready,
    output wire       rom_arvalid,
    input wire        rom_arready,
    output wire [31:0] rom_araddr,
    input wire        rom_rvalid,
    output wire       rom_rready,
    input wire [31:0] rom_rdata,
    output wire       ram_awvalid,
    input wire        ram_awready,
    output wire [31:0] ram_awaddr,
    output wire       ram_wvalid,
    input wire        ram_wready,
    output wire [31:0] ram_wdata,
    output wire [3:0]  ram_wstrb,
    input wire        ram_bvalid,
    output wire       ram_bready,
    output wire       ram_arvalid,
    input wire        ram_arready,
    output wire [31:0] ram_araddr,
    input wire        ram_rvalid,
    output wire       ram_rready,
    input wire [31:0] ram_rdata,
    output wire       cry_awvalid,
    input wire        cry_awready,
    output wire [31:0] cry_awaddr,
    output wire       cry_wvalid,
    input wire        cry_wready,
    output wire [31:0] cry_wdata,
    output wire [3:0]  cry_wstrb,
    input wire        cry_bvalid,
    output wire       cry_bready,
    output wire       cry_arvalid,
    input wire        cry_arready,
    output wire [31:0] cry_araddr,
    input wire        cry_rvalid,
    output wire       cry_rready,
    input wire [31:0] cry_rdata
);
    localparam SEL_ROM = 2'd0;
    localparam SEL_RAM = 2'd1;
    localparam SEL_CRY = 2'd2;

    reg [1:0] wr_sel;
    reg [1:0] rd_sel;
    reg [31:0] awaddr_hold;
    reg [31:0] wdata_hold;
    reg [3:0]  wstrb_hold;
    reg [31:0] araddr_hold;
    reg       aw_pending;
    reg       w_pending;
    reg       aw_done;
    reg       w_done;
    reg       ar_pending;
    reg       rd_active;

    wire [1:0] aw_sel = (m_awaddr[31:28] == 4'h0) ? SEL_ROM :
                        (m_awaddr[31:28] == 4'h1) ? SEL_RAM : SEL_CRY;
    wire [1:0] ar_sel = (m_araddr[31:28] == 4'h0) ? SEL_ROM :
                        (m_araddr[31:28] == 4'h1) ? SEL_RAM : SEL_CRY;
    wire       write_issue = aw_pending && w_pending;

    assign rom_awvalid = write_issue && !aw_done && (wr_sel == SEL_ROM);
    assign ram_awvalid = write_issue && !aw_done && (wr_sel == SEL_RAM);
    assign cry_awvalid = write_issue && !aw_done && (wr_sel == SEL_CRY);
    assign rom_wvalid  = write_issue && !w_done && (wr_sel == SEL_ROM);
    assign ram_wvalid  = write_issue && !w_done && (wr_sel == SEL_RAM);
    assign cry_wvalid  = write_issue && !w_done && (wr_sel == SEL_CRY);
    assign rom_awaddr = awaddr_hold;
    assign ram_awaddr = awaddr_hold - 32'h1000_0000;
    assign cry_awaddr = awaddr_hold - 32'h2000_0000;
    assign rom_wdata = wdata_hold;
    assign ram_wdata = wdata_hold;
    assign cry_wdata = wdata_hold;
    assign rom_wstrb = wstrb_hold;
    assign ram_wstrb = wstrb_hold;
    assign cry_wstrb = wstrb_hold;
    assign m_awready = !aw_pending && !aw_done;
    assign m_wready  = !w_pending && !w_done;
    assign m_bvalid  = (aw_done && w_done) &&
                       ((wr_sel == SEL_ROM) ? rom_bvalid :
                        (wr_sel == SEL_RAM) ? ram_bvalid : cry_bvalid);
    assign rom_bready = m_bready && m_bvalid && (wr_sel == SEL_ROM);
    assign ram_bready = m_bready && m_bvalid && (wr_sel == SEL_RAM);
    assign cry_bready = m_bready && m_bvalid && (wr_sel == SEL_CRY);

    assign rom_arvalid = ar_pending && (rd_sel == SEL_ROM);
    assign ram_arvalid = ar_pending && (rd_sel == SEL_RAM);
    assign cry_arvalid = ar_pending && (rd_sel == SEL_CRY);
    assign rom_araddr = araddr_hold;
    assign ram_araddr = araddr_hold - 32'h1000_0000;
    assign cry_araddr = araddr_hold - 32'h2000_0000;
    assign m_arready = !ar_pending && !rd_active;
    assign m_rvalid = rd_active &&
                      ((rd_sel == SEL_ROM) ? rom_rvalid :
                       (rd_sel == SEL_RAM) ? ram_rvalid : cry_rvalid);
    assign m_rdata  = (rd_sel == SEL_ROM) ? rom_rdata :
                      (rd_sel == SEL_RAM) ? ram_rdata : cry_rdata;
    assign rom_rready = m_rready && m_rvalid && (rd_sel == SEL_ROM);
    assign ram_rready = m_rready && m_rvalid && (rd_sel == SEL_RAM);
    assign cry_rready = m_rready && m_rvalid && (rd_sel == SEL_CRY);

    always @(posedge clk) begin
        if (!rst_n) begin
            wr_sel <= SEL_ROM;
            rd_sel <= SEL_ROM;
            awaddr_hold <= 32'd0;
            wdata_hold <= 32'd0;
            wstrb_hold <= 4'd0;
            araddr_hold <= 32'd0;
            aw_pending <= 1'b0;
            w_pending <= 1'b0;
            aw_done <= 1'b0;
            w_done <= 1'b0;
            ar_pending <= 1'b0;
            rd_active <= 1'b0;
        end else begin
            if (m_awvalid && m_awready) begin
                wr_sel <= aw_sel;
                awaddr_hold <= m_awaddr;
                aw_pending <= 1'b1;
            end
            if (m_wvalid && m_wready) begin
                wdata_hold <= m_wdata;
                wstrb_hold <= m_wstrb;
                w_pending <= 1'b1;
            end

            if ((rom_awvalid && rom_awready) || (ram_awvalid && ram_awready) || (cry_awvalid && cry_awready)) begin
                aw_pending <= 1'b0;
                aw_done <= 1'b1;
            end
            if ((rom_wvalid && rom_wready) || (ram_wvalid && ram_wready) || (cry_wvalid && cry_wready)) begin
                w_pending <= 1'b0;
                w_done <= 1'b1;
            end
            if (m_bvalid && m_bready) begin
                aw_pending <= 1'b0;
                w_pending <= 1'b0;
                aw_done <= 1'b0;
                w_done <= 1'b0;
            end

            if (m_arvalid && m_arready) begin
                rd_sel <= ar_sel;
                araddr_hold <= m_araddr;
                ar_pending <= 1'b1;
            end
            if ((rom_arvalid && rom_arready) || (ram_arvalid && ram_arready) || (cry_arvalid && cry_arready)) begin
                ar_pending <= 1'b0;
                rd_active <= 1'b1;
            end
            if (m_rvalid && m_rready)
                rd_active <= 1'b0;
        end
    end
endmodule
