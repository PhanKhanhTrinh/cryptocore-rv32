`timescale 1ns / 1ps

module axi_lite_rom #(
    parameter MEM_WORDS = 256,
    parameter INIT_FILE = "firmware/boot_rom.hex"
) (
    input wire        clk,
    input wire        rst_n,
    input wire        s_axi_awvalid,
    output wire       s_axi_awready,
    input wire [31:0] s_axi_awaddr,
    input wire        s_axi_wvalid,
    output wire       s_axi_wready,
    input wire [31:0] s_axi_wdata,
    input wire [3:0]  s_axi_wstrb,
    output reg        s_axi_bvalid,
    input wire        s_axi_bready,
    input wire        s_axi_arvalid,
    output wire       s_axi_arready,
    input wire [31:0] s_axi_araddr,
    output reg        s_axi_rvalid,
    input wire        s_axi_rready,
    output reg [31:0] s_axi_rdata
);
    function integer clog2;
        input integer value;
        integer v;
        begin
            v = value - 1;
            for (clog2 = 0; v > 0; clog2 = clog2 + 1)
                v = v >> 1;
        end
    endfunction

    localparam ADDR_BITS = clog2(MEM_WORDS);
    (* ram_style = "block" *) reg [31:0] mem [0:MEM_WORDS-1];
    reg        aw_pending;
    reg        w_pending;
    integer i;
    initial begin
        for (i = 0; i < MEM_WORDS; i = i + 1)
            mem[i] = 32'h00000013;
        $readmemh(INIT_FILE, mem);
    end

    assign s_axi_awready = !aw_pending && !s_axi_bvalid;
    assign s_axi_wready  = !w_pending && !s_axi_bvalid;
    assign s_axi_arready = !s_axi_rvalid;

    always @(posedge clk) begin
        if (!rst_n) begin
            aw_pending <= 1'b0;
            w_pending <= 1'b0;
            s_axi_bvalid <= 1'b0;
            s_axi_rvalid <= 1'b0;
            s_axi_rdata <= 32'd0;
        end else begin
            if (s_axi_awvalid && s_axi_awready)
                aw_pending <= 1'b1;
            if (s_axi_wvalid && s_axi_wready)
                w_pending <= 1'b1;
            if (aw_pending && w_pending && !s_axi_bvalid) begin
                aw_pending <= 1'b0;
                w_pending <= 1'b0;
                s_axi_bvalid <= 1'b1;
            end
            if (s_axi_bvalid && s_axi_bready)
                s_axi_bvalid <= 1'b0;
            if (s_axi_arvalid && s_axi_arready) begin
                s_axi_rdata <= mem[s_axi_araddr[ADDR_BITS+1:2]];
                s_axi_rvalid <= 1'b1;
            end
            if (s_axi_rvalid && s_axi_rready)
                s_axi_rvalid <= 1'b0;
        end
    end
endmodule

module axi_lite_ram #(
    parameter MEM_WORDS = 1024
) (
    input wire        clk,
    input wire        rst_n,
    input wire        s_axi_awvalid,
    output wire       s_axi_awready,
    input wire [31:0] s_axi_awaddr,
    input wire        s_axi_wvalid,
    output wire       s_axi_wready,
    input wire [31:0] s_axi_wdata,
    input wire [3:0]  s_axi_wstrb,
    output reg        s_axi_bvalid,
    input wire        s_axi_bready,
    input wire        s_axi_arvalid,
    output wire       s_axi_arready,
    input wire [31:0] s_axi_araddr,
    output reg        s_axi_rvalid,
    input wire        s_axi_rready,
    output reg [31:0] s_axi_rdata,
    output wire [31:0] debug_word0,
    output wire [31:0] debug_word1,
    output wire [31:0] debug_word2,
    output wire [31:0] debug_word3
);
    function integer clog2;
        input integer value;
        integer v;
        begin
            v = value - 1;
            for (clog2 = 0; v > 0; clog2 = clog2 + 1)
                v = v >> 1;
        end
    endfunction

    localparam ADDR_BITS = clog2(MEM_WORDS);
    (* ram_style = "block" *) reg [7:0] mem_b0 [0:MEM_WORDS-1];
    (* ram_style = "block" *) reg [7:0] mem_b1 [0:MEM_WORDS-1];
    (* ram_style = "block" *) reg [7:0] mem_b2 [0:MEM_WORDS-1];
    (* ram_style = "block" *) reg [7:0] mem_b3 [0:MEM_WORDS-1];
    integer i;
    reg [31:0] wr_data;
    reg [31:0] awaddr_hold;
    reg [31:0] wdata_hold;
    reg [3:0]  wstrb_hold;
    reg [31:0] debug_word0_r;
    reg [31:0] debug_word1_r;
    reg [31:0] debug_word2_r;
    reg [31:0] debug_word3_r;
    reg        aw_pending;
    reg        w_pending;
    integer idx;

    initial begin
        for (i = 0; i < MEM_WORDS; i = i + 1) begin
            mem_b0[i] = 8'd0;
            mem_b1[i] = 8'd0;
            mem_b2[i] = 8'd0;
            mem_b3[i] = 8'd0;
        end
    end

    assign s_axi_awready = !aw_pending && !s_axi_bvalid;
    assign s_axi_wready  = !w_pending && !s_axi_bvalid;
    assign s_axi_arready = !s_axi_rvalid;
    assign debug_word0 = debug_word0_r;
    assign debug_word1 = debug_word1_r;
    assign debug_word2 = debug_word2_r;
    assign debug_word3 = debug_word3_r;

    always @(posedge clk) begin
        if (!rst_n) begin
            awaddr_hold <= 32'd0;
            wdata_hold <= 32'd0;
            wstrb_hold <= 4'd0;
            debug_word0_r <= 32'd0;
            debug_word1_r <= 32'd0;
            debug_word2_r <= 32'd0;
            debug_word3_r <= 32'd0;
            aw_pending <= 1'b0;
            w_pending <= 1'b0;
            s_axi_bvalid <= 1'b0;
            s_axi_rvalid <= 1'b0;
            s_axi_rdata <= 32'd0;
        end else begin
            if (s_axi_awvalid && s_axi_awready) begin
                awaddr_hold <= s_axi_awaddr;
                aw_pending <= 1'b1;
            end
            if (s_axi_wvalid && s_axi_wready) begin
                wdata_hold <= s_axi_wdata;
                wstrb_hold <= s_axi_wstrb;
                w_pending <= 1'b1;
            end
            if (aw_pending && w_pending && !s_axi_bvalid) begin
                idx = awaddr_hold[ADDR_BITS+1:2];
                if (idx == 0)
                    wr_data = debug_word0_r;
                else if (idx == 1)
                    wr_data = debug_word1_r;
                else if (idx == 2)
                    wr_data = debug_word2_r;
                else if (idx == 3)
                    wr_data = debug_word3_r;
                else
                    wr_data = 32'd0;
                if (wstrb_hold[0]) wr_data[7:0]   = wdata_hold[7:0];
                if (wstrb_hold[1]) wr_data[15:8]  = wdata_hold[15:8];
                if (wstrb_hold[2]) wr_data[23:16] = wdata_hold[23:16];
                if (wstrb_hold[3]) wr_data[31:24] = wdata_hold[31:24];
                if (wstrb_hold[0]) mem_b0[idx] <= wdata_hold[7:0];
                if (wstrb_hold[1]) mem_b1[idx] <= wdata_hold[15:8];
                if (wstrb_hold[2]) mem_b2[idx] <= wdata_hold[23:16];
                if (wstrb_hold[3]) mem_b3[idx] <= wdata_hold[31:24];
                if (idx == 0) debug_word0_r <= wr_data;
                if (idx == 1) debug_word1_r <= wr_data;
                if (idx == 2) debug_word2_r <= wr_data;
                if (idx == 3) debug_word3_r <= wr_data;
                aw_pending <= 1'b0;
                w_pending <= 1'b0;
                s_axi_bvalid <= 1'b1;
            end
            if (s_axi_bvalid && s_axi_bready)
                s_axi_bvalid <= 1'b0;
            if (s_axi_arvalid && s_axi_arready) begin
                s_axi_rdata <= {
                    mem_b3[s_axi_araddr[ADDR_BITS+1:2]],
                    mem_b2[s_axi_araddr[ADDR_BITS+1:2]],
                    mem_b1[s_axi_araddr[ADDR_BITS+1:2]],
                    mem_b0[s_axi_araddr[ADDR_BITS+1:2]]
                };
                s_axi_rvalid <= 1'b1;
            end
            if (s_axi_rvalid && s_axi_rready)
                s_axi_rvalid <= 1'b0;
        end
    end
endmodule
