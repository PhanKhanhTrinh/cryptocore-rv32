source [file join [file dirname [info script]] wave_common.tcl]

if {![sim_has_object /tb_aes128_core/clk]} {
    puts "No /tb_aes128_core objects found. Make sure tb_aes128_core simulation is open."
    return
}

sim_clear_waves

sim_add_divider "AES-128 Testbench Control"
sim_add /tb_aes128_core/clk
sim_add /tb_aes128_core/rst_n
sim_add /tb_aes128_core/start
sim_add /tb_aes128_core/decrypt
sim_add /tb_aes128_core/ready
sim_add /tb_aes128_core/busy
sim_add /tb_aes128_core/done
sim_add /tb_aes128_core/done_count unsigned

sim_add_divider "AES-128 Data"
sim_add /tb_aes128_core/plaintext hex
sim_add /tb_aes128_core/key hex
sim_add /tb_aes128_core/ciphertext hex
sim_add /tb_aes128_core/result hex

sim_add_divider "DUT Control"
sim_add /tb_aes128_core/dut/ready
sim_add /tb_aes128_core/dut/busy
sim_add /tb_aes128_core/dut/done
sim_add /tb_aes128_core/dut/round unsigned

sim_zoom_fit
puts "AES-128 waveform signals added without duplicates."
