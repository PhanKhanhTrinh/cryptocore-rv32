source [file join [file dirname [info script]] wave_common.tcl]

if {![sim_has_object /tb_crypto_perf/clk]} {
    puts "No /tb_crypto_perf objects found. Make sure tb_crypto_perf simulation is open."
    return
}

sim_clear_waves

sim_add_divider "Performance Counters"
sim_add /tb_crypto_perf/clk
sim_add /tb_crypto_perf/rst_n
sim_add /tb_crypto_perf/cycle_count unsigned
sim_add /tb_crypto_perf/op_start_cycle unsigned
sim_add /tb_crypto_perf/op_latency unsigned
sim_add /tb_crypto_perf/aes_total_cycles unsigned
sim_add /tb_crypto_perf/sha_cycles unsigned
sim_add /tb_crypto_perf/chacha_cycles unsigned
sim_add /tb_crypto_perf/tmp_cycles unsigned

sim_add_divider "AXI-Lite Transaction"
sim_add /tb_crypto_perf/awvalid
sim_add /tb_crypto_perf/awready
sim_add /tb_crypto_perf/awaddr hex
sim_add /tb_crypto_perf/wvalid
sim_add /tb_crypto_perf/wready
sim_add /tb_crypto_perf/wdata hex
sim_add /tb_crypto_perf/bvalid
sim_add /tb_crypto_perf/bready
sim_add /tb_crypto_perf/arvalid
sim_add /tb_crypto_perf/arready
sim_add /tb_crypto_perf/araddr hex
sim_add /tb_crypto_perf/rvalid
sim_add /tb_crypto_perf/rready
sim_add /tb_crypto_perf/rdata hex

sim_add_divider "Coprocessor Operation"
sim_add /tb_crypto_perf/dut/algo_sel_reg unsigned
sim_add /tb_crypto_perf/dut/op_busy
sim_add /tb_crypto_perf/dut/op_done
sim_add /tb_crypto_perf/dut/op_error
sim_add /tb_crypto_perf/dut/op_state unsigned
sim_add /tb_crypto_perf/dut/op_step unsigned
sim_add /tb_crypto_perf/dut/aes_start
sim_add /tb_crypto_perf/dut/sha_start
sim_add /tb_crypto_perf/dut/cha_start
sim_add /tb_crypto_perf/dut/aes_done
sim_add /tb_crypto_perf/dut/sha_done
sim_add /tb_crypto_perf/dut/cha_done

sim_zoom_fit
puts "Crypto performance waveform signals added without duplicates."
