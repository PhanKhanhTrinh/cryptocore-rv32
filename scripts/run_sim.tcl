# Usage:
#   vivado -mode batch -source scripts/run_sim.tcl -tclargs tb_soc_firmware

set script_dir [file dirname [file normalize [info script]]]
set repo_root  [file normalize [file join $script_dir ..]]
set project_file [file join $repo_root build CryptoCore_RV32.xpr]

set supported_tops {
    tb_aes128_core
    tb_sha256_core
    tb_chacha20_core
    tb_aes_modes_axi
    tb_crypto_axi
    tb_crypto_perf
    tb_axi_lite_crossbar
    tb_axi_lite_mem
    tb_soc_firmware
    tb_soc_trap_firmware
    tb_pynq_z2_top_status
}

if {[llength $argv] > 0} {
    set sim_top [lindex $argv 0]
} else {
    set sim_top tb_soc_firmware
}

if {[lsearch -exact $supported_tops $sim_top] < 0} {
    error "Unsupported simulation top '$sim_top'. Choose one of: $supported_tops"
}

if {[file exists $project_file]} {
    open_project $project_file
} else {
    source [file join $script_dir create_project.tcl]
}

set_property top $sim_top [get_filesets sim_1]
update_compile_order -fileset sim_1

puts "Running simulation: $sim_top"
launch_simulation
run all
close_sim
close_project
