source [file join [file dirname [info script]] wave_common.tcl]

if {![sim_has_object /tb_crypto_axi/clk]} {
    puts "No /tb_crypto_axi objects found. Make sure tb_crypto_axi simulation is open."
    return
}

sim_clear_waves

sim_add_divider "AXI Testbench Control"
sim_add /tb_crypto_axi/clk
sim_add /tb_crypto_axi/rst_n
sim_add /tb_crypto_axi/status_word hex
sim_add /tb_crypto_axi/aes_result hex
sim_add /tb_crypto_axi/sha_result hex
sim_add /tb_crypto_axi/cha_result hex

sim_add_divider "AXI-Lite Write Channel"
sim_add /tb_crypto_axi/awvalid
sim_add /tb_crypto_axi/awready
sim_add /tb_crypto_axi/awaddr hex
sim_add /tb_crypto_axi/wvalid
sim_add /tb_crypto_axi/wready
sim_add /tb_crypto_axi/wdata hex
sim_add /tb_crypto_axi/wstrb hex
sim_add /tb_crypto_axi/bvalid
sim_add /tb_crypto_axi/bready

sim_add_divider "AXI-Lite Read Channel"
sim_add /tb_crypto_axi/arvalid
sim_add /tb_crypto_axi/arready
sim_add /tb_crypto_axi/araddr hex
sim_add /tb_crypto_axi/rvalid
sim_add /tb_crypto_axi/rready
sim_add /tb_crypto_axi/rdata hex

sim_add_divider "Coprocessor State"
sim_add /tb_crypto_axi/dut/ctrl_reg hex
sim_add /tb_crypto_axi/dut/algo_sel_reg unsigned
sim_add /tb_crypto_axi/dut/op_busy
sim_add /tb_crypto_axi/dut/op_done
sim_add /tb_crypto_axi/dut/op_error
sim_add /tb_crypto_axi/dut/op_state unsigned
sim_add /tb_crypto_axi/dut/op_step unsigned
sim_add /tb_crypto_axi/dut/aes_start
sim_add /tb_crypto_axi/dut/sha_start
sim_add /tb_crypto_axi/dut/cha_start
sim_add /tb_crypto_axi/dut/aes_done
sim_add /tb_crypto_axi/dut/sha_done
sim_add /tb_crypto_axi/dut/cha_done

sim_add_divider "Buffer Samples"
sim_add {/tb_crypto_axi/dut/buf_reg[0]} hex
sim_add {/tb_crypto_axi/dut/buf_reg[1]} hex
sim_add {/tb_crypto_axi/dut/buf_reg[4]} hex
sim_add {/tb_crypto_axi/dut/buf_reg[8]} hex
sim_add {/tb_crypto_axi/dut/buf_reg[20]} hex
sim_add {/tb_crypto_axi/dut/buf_reg[24]} hex

sim_zoom_fit
puts "Crypto AXI waveform signals added without duplicates."
