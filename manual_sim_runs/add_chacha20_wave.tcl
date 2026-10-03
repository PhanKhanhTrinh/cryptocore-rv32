source [file join [file dirname [info script]] wave_common.tcl]

if {![sim_has_object /tb_chacha20_core/clk]} {
    puts "No /tb_chacha20_core objects found. Make sure tb_chacha20_core simulation is open."
    return
}

sim_clear_waves

sim_add_divider "ChaCha20 Testbench Control"
sim_add /tb_chacha20_core/clk
sim_add /tb_chacha20_core/rst_n
sim_add /tb_chacha20_core/start
sim_add /tb_chacha20_core/ready
sim_add /tb_chacha20_core/busy
sim_add /tb_chacha20_core/done
sim_add /tb_chacha20_core/done_count unsigned

sim_add_divider "ChaCha20 Inputs"
sim_add /tb_chacha20_core/key hex
sim_add /tb_chacha20_core/counter hex
sim_add /tb_chacha20_core/nonce hex

sim_add_divider "ChaCha20 Output"
sim_add /tb_chacha20_core/keystream hex
sim_add /tb_chacha20_core/result hex

sim_add_divider "DUT Control"
sim_add /tb_chacha20_core/dut/ready
sim_add /tb_chacha20_core/dut/busy
sim_add /tb_chacha20_core/dut/done
sim_add /tb_chacha20_core/dut/phase unsigned
sim_add /tb_chacha20_core/dut/step unsigned
sim_add /tb_chacha20_core/dut/qr_a_idx unsigned
sim_add /tb_chacha20_core/dut/qr_b_idx unsigned
sim_add /tb_chacha20_core/dut/qr_c_idx unsigned
sim_add /tb_chacha20_core/dut/qr_d_idx unsigned

sim_add_divider "DUT State Sample"
sim_add {/tb_chacha20_core/dut/x[0]} hex
sim_add {/tb_chacha20_core/dut/x[1]} hex
sim_add {/tb_chacha20_core/dut/x[2]} hex
sim_add {/tb_chacha20_core/dut/x[3]} hex
sim_add {/tb_chacha20_core/dut/x[12]} hex
sim_add {/tb_chacha20_core/dut/x[13]} hex
sim_add {/tb_chacha20_core/dut/x[14]} hex
sim_add {/tb_chacha20_core/dut/x[15]} hex

sim_zoom_fit
puts "ChaCha20 waveform signals added without duplicates."
