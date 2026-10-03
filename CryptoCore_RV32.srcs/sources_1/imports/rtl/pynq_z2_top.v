`timescale 1ns / 1ps

module pynq_z2_top (
    input wire CLK125MHZ,
    input wire [3:0] BTN,
    input wire [1:0] SW,
    output wire [3:0] LED,
    output wire [7:0] JB
);
    wire clk50;
    wire clk_locked;
    reg [1:0] btn0_sync = 2'b00;
    reg [19:0] lock_high_cnt = 20'd0;
    reg [19:0] lock_low_cnt = 20'd0;
    reg rst_n_r = 1'b0;
    reg [26:0] heartbeat_cnt = 27'd0;
    reg [23:0] activity_stretch = 24'd0;
    wire rst_n;
    wire board_reset;
    wire soc_trap;
    wire soc_axi_read;
    wire soc_axi_write;
    wire [31:0] fw_magic;
    wire [31:0] fw_passmask;
    wire [31:0] fw_stage;
    wire [31:0] fw_detail;
    wire [3:0] led_system;
    wire [3:0] led_firmware;

    assign board_reset = btn0_sync[1];

    clk_50mhz_from_125 u_clkgen (
        .clk125(CLK125MHZ),
        .reset(1'b0),
        .clk50(clk50),
        .locked(clk_locked)
    );

    always @(posedge clk50) begin
        btn0_sync <= {btn0_sync[0], BTN[0]};

        if (clk_locked) begin
            lock_low_cnt <= 20'd0;
            if (!lock_high_cnt[19])
                lock_high_cnt <= lock_high_cnt + 20'd1;
        end else begin
            lock_high_cnt <= 20'd0;
            if (!lock_low_cnt[19])
                lock_low_cnt <= lock_low_cnt + 20'd1;
        end

        if (board_reset)
            rst_n_r <= 1'b0;
        else if (lock_low_cnt[19])
            rst_n_r <= 1'b0;
        else if (!rst_n_r && lock_high_cnt[19])
            rst_n_r <= 1'b1;
    end

    assign rst_n = rst_n_r;

    always @(posedge clk50) begin
        if (!rst_n) begin
            heartbeat_cnt <= 27'd0;
            activity_stretch <= 24'd0;
        end else begin
            heartbeat_cnt <= heartbeat_cnt + 27'd1;
            if (soc_axi_read || soc_axi_write)
                activity_stretch <= 24'hffffff;
            else if (activity_stretch != 24'd0)
                activity_stretch <= activity_stretch - 24'd1;
        end
    end

    riscv_crypto_soc u_soc (
        .clk(clk50),
        .rst_n(rst_n),
        .trap_o(soc_trap),
        .axi_read_o(soc_axi_read),
        .axi_write_o(soc_axi_write),
        .fw_magic_o(fw_magic),
        .fw_passmask_o(fw_passmask),
        .fw_stage_o(fw_stage),
        .fw_detail_o(fw_detail)
    );

    assign led_system = { |activity_stretch, soc_trap, ~rst_n, heartbeat_cnt[25] };
    assign led_firmware = fw_passmask[3:0];
    assign LED = SW[0] ? led_firmware : led_system;

    // Expose simple observability on Pmod JB for scope/LA.
    assign JB[0] = clk50;
    assign JB[1] = rst_n;
    assign JB[2] = soc_trap;
    assign JB[3] = soc_axi_read;
    assign JB[4] = soc_axi_write;
    assign JB[5] = heartbeat_cnt[24];
    assign JB[6] = fw_magic[0];
    assign JB[7] = fw_stage[0];
endmodule

module clk_50mhz_from_125 (
    input wire clk125,
    input wire reset,
    output wire clk50,
    output wire locked
);
`ifdef __ICARUS__
    assign clk50 = clk125;
    assign locked = !reset;
`else
    wire clkfb;
    wire clkfb_buf;
    wire clk50_mmcm;

    MMCME2_BASE #(
        .BANDWIDTH("OPTIMIZED"),
        .CLKFBOUT_MULT_F(8.000),
        .CLKFBOUT_PHASE(0.000),
        .CLKIN1_PERIOD(8.000),
        .CLKOUT0_DIVIDE_F(20.000),
        .CLKOUT0_DUTY_CYCLE(0.500),
        .CLKOUT0_PHASE(0.000),
        .CLKOUT1_DIVIDE(1),
        .CLKOUT1_DUTY_CYCLE(0.500),
        .CLKOUT1_PHASE(0.000),
        .CLKOUT2_DIVIDE(1),
        .CLKOUT2_DUTY_CYCLE(0.500),
        .CLKOUT2_PHASE(0.000),
        .CLKOUT3_DIVIDE(1),
        .CLKOUT3_DUTY_CYCLE(0.500),
        .CLKOUT3_PHASE(0.000),
        .CLKOUT4_CASCADE("FALSE"),
        .CLKOUT4_DIVIDE(1),
        .CLKOUT4_DUTY_CYCLE(0.500),
        .CLKOUT4_PHASE(0.000),
        .CLKOUT5_DIVIDE(1),
        .CLKOUT5_DUTY_CYCLE(0.500),
        .CLKOUT5_PHASE(0.000),
        .CLKOUT6_DIVIDE(1),
        .CLKOUT6_DUTY_CYCLE(0.500),
        .CLKOUT6_PHASE(0.000),
        .DIVCLK_DIVIDE(1),
        .REF_JITTER1(0.010),
        .STARTUP_WAIT("FALSE")
    ) u_mmcm (
        .CLKIN1(clk125),
        .CLKFBIN(clkfb_buf),
        .RST(reset),
        .PWRDWN(1'b0),
        .CLKFBOUT(clkfb),
        .CLKFBOUTB(),
        .CLKOUT0(clk50_mmcm),
        .CLKOUT0B(),
        .CLKOUT1(),
        .CLKOUT1B(),
        .CLKOUT2(),
        .CLKOUT2B(),
        .CLKOUT3(),
        .CLKOUT3B(),
        .CLKOUT4(),
        .CLKOUT5(),
        .CLKOUT6(),
        .LOCKED(locked)
    );

    BUFG u_clkfb_buf (
        .I(clkfb),
        .O(clkfb_buf)
    );

    BUFG u_clk50_buf (
        .I(clk50_mmcm),
        .O(clk50)
    );
`endif
endmodule
