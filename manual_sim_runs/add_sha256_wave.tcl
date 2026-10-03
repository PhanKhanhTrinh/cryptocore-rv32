source [file join [file dirname [info script]] wave_common.tcl]

if {![sim_has_object /tb_sha256_core/clk]} {
    puts "No /tb_sha256_core objects found. Make sure tb_sha256_core simulation is open."
    return
}

sim_clear_waves

sim_add_divider "SHA-256 Testbench Control"
sim_add /tb_sha256_core/clk
sim_add /tb_sha256_core/rst_n
sim_add /tb_sha256_core/start
sim_add /tb_sha256_core/init
sim_add /tb_sha256_core/ready
sim_add /tb_sha256_core/busy
sim_add /tb_sha256_core/done
sim_add /tb_sha256_core/done_count unsigned

sim_add_divider "SHA-256 Data"
sim_add /tb_sha256_core/state_in hex
sim_add /tb_sha256_core/block hex
sim_add /tb_sha256_core/digest hex
sim_add /tb_sha256_core/mid_state hex
sim_add /tb_sha256_core/final_digest hex

sim_add_divider "DUT Control"
sim_add /tb_sha256_core/dut/ready
sim_add /tb_sha256_core/dut/busy
sim_add /tb_sha256_core/dut/done
sim_add /tb_sha256_core/dut/round unsigned

sim_zoom_fit
puts "SHA-256 waveform signals added without duplicates."
