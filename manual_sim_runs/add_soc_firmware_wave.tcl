source [file join [file dirname [info script]] wave_common.tcl]

if {![sim_has_object /tb_soc_firmware/clk]} {
    puts "No /tb_soc_firmware objects found. Make sure tb_soc_firmware simulation is open."
    return
}

sim_clear_waves

sim_add_divider "Firmware Testbench Status"
sim_add /tb_soc_firmware/clk
sim_add /tb_soc_firmware/rst_n
sim_add /tb_soc_firmware/trap_o
sim_add /tb_soc_firmware/axi_read_o
sim_add /tb_soc_firmware/axi_write_o
sim_add /tb_soc_firmware/fw_magic_o hex
sim_add /tb_soc_firmware/fw_passmask_o hex
sim_add /tb_soc_firmware/fw_stage_o hex
sim_add /tb_soc_firmware/fw_detail_o hex

sim_add_divider "CPU AXI Master"
sim_add /tb_soc_firmware/dut/mem_axi_awvalid
sim_add /tb_soc_firmware/dut/mem_axi_awready
sim_add /tb_soc_firmware/dut/mem_axi_awaddr hex
sim_add /tb_soc_firmware/dut/mem_axi_wvalid
sim_add /tb_soc_firmware/dut/mem_axi_wready
sim_add /tb_soc_firmware/dut/mem_axi_wdata hex
sim_add /tb_soc_firmware/dut/mem_axi_arvalid
sim_add /tb_soc_firmware/dut/mem_axi_arready
sim_add /tb_soc_firmware/dut/mem_axi_araddr hex
sim_add /tb_soc_firmware/dut/mem_axi_rvalid
sim_add /tb_soc_firmware/dut/mem_axi_rready
sim_add /tb_soc_firmware/dut/mem_axi_rdata hex

sim_add_divider "Crypto Peripheral"
sim_add /tb_soc_firmware/dut/cry_awvalid
sim_add /tb_soc_firmware/dut/cry_awready
sim_add /tb_soc_firmware/dut/cry_awaddr hex
sim_add /tb_soc_firmware/dut/cry_wvalid
sim_add /tb_soc_firmware/dut/cry_wready
sim_add /tb_soc_firmware/dut/cry_wdata hex
sim_add /tb_soc_firmware/dut/cry_arvalid
sim_add /tb_soc_firmware/dut/cry_arready
sim_add /tb_soc_firmware/dut/cry_araddr hex
sim_add /tb_soc_firmware/dut/cry_rvalid
sim_add /tb_soc_firmware/dut/cry_rready
sim_add /tb_soc_firmware/dut/cry_rdata hex
sim_add /tb_soc_firmware/dut/u_crypto/algo_sel_reg unsigned
sim_add /tb_soc_firmware/dut/u_crypto/op_busy
sim_add /tb_soc_firmware/dut/u_crypto/op_done
sim_add /tb_soc_firmware/dut/u_crypto/op_error
sim_add /tb_soc_firmware/dut/u_crypto/op_state unsigned

sim_zoom_fit
puts "SoC firmware waveform signals added without duplicates."
