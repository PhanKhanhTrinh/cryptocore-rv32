source [file join [file dirname [info script]] wave_common.tcl]

if {![sim_has_object /tb_aes_modes_axi/clk]} {
    puts "No /tb_aes_modes_axi objects found. Make sure the AES modes simulation is open."
    return
}

sim_clear_waves

sim_add_divider "AES Mode Test Control"
sim_add /tb_aes_modes_axi/clk
sim_add /tb_aes_modes_axi/rst_n
sim_add /tb_aes_modes_axi/test_phase unsigned
sim_add /tb_aes_modes_axi/status_word hex
sim_add /tb_aes_modes_axi/aes_start_count unsigned
sim_add /tb_aes_modes_axi/aes_done_count unsigned

sim_add_divider "Coprocessor Mode FSM"
sim_add /tb_aes_modes_axi/dut/algo_sel_reg unsigned
sim_add /tb_aes_modes_axi/dut/op_busy
sim_add /tb_aes_modes_axi/dut/op_done
sim_add /tb_aes_modes_axi/dut/op_error
sim_add /tb_aes_modes_axi/dut/op_state unsigned
sim_add /tb_aes_modes_axi/dut/op_step unsigned

sim_add_divider "AES Core Sequencing"
sim_add /tb_aes_modes_axi/dut/aes_start
sim_add /tb_aes_modes_axi/dut/aes_decrypt
sim_add /tb_aes_modes_axi/dut/aes_ready
sim_add /tb_aes_modes_axi/dut/aes_busy
sim_add /tb_aes_modes_axi/dut/aes_done
sim_add /tb_aes_modes_axi/dut/aes_block_in hex
sim_add /tb_aes_modes_axi/dut/aes_ciphertext hex
sim_add /tb_aes_modes_axi/dut/aes_feedback hex
sim_add /tb_aes_modes_axi/dut/aes_save0 hex

sim_add_divider "Current Mode Inputs and Result"
sim_add /tb_aes_modes_axi/input_block_1 hex
sim_add /tb_aes_modes_axi/input_block_2 hex
sim_add /tb_aes_modes_axi/input_key hex
sim_add /tb_aes_modes_axi/input_iv_counter hex
sim_add /tb_aes_modes_axi/mode_result hex

sim_add_divider "Latched Verified Results"
sim_add /tb_aes_modes_axi/cbc_ciphertext hex
sim_add /tb_aes_modes_axi/cbc_plaintext hex
sim_add /tb_aes_modes_axi/ctr_ciphertext hex
sim_add /tb_aes_modes_axi/ctr_plaintext hex

sim_zoom_fit
puts "AES CBC/CTR waveform signals added without duplicates."
