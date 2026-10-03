# Usage:
#   vivado -mode batch -source scripts/build_bitstream.tcl -tclargs 4

set script_dir [file dirname [file normalize [info script]]]
set repo_root  [file normalize [file join $script_dir ..]]
set project_file [file join $repo_root build CryptoCore_RV32.xpr]
set artifact_dir [file join $repo_root artifacts]
set report_dir [file join $artifact_dir reports]

if {[llength $argv] > 0} {
    set jobs [lindex $argv 0]
} else {
    set jobs 4
}

if {![string is integer -strict $jobs] || $jobs < 1} {
    error "The job count must be a positive integer."
}

if {[file exists $project_file]} {
    open_project $project_file
} else {
    source [file join $script_dir create_project.tcl]
}

file mkdir $report_dir

reset_run synth_1
launch_runs synth_1 -jobs $jobs
wait_on_run synth_1
set synth_status [get_property STATUS [get_runs synth_1]]
if {[string match -nocase "*error*" $synth_status]} {
    error "Synthesis failed: $synth_status"
}

launch_runs impl_1 -to_step write_bitstream -jobs $jobs
wait_on_run impl_1
set impl_status [get_property STATUS [get_runs impl_1]]
if {[string match -nocase "*error*" $impl_status]} {
    error "Implementation failed: $impl_status"
}

open_run impl_1
report_utilization -file [file join $report_dir utilization.rpt]
report_timing_summary -file [file join $report_dir timing_summary.rpt]
report_power -file [file join $report_dir power.rpt]

set run_dir [get_property DIRECTORY [get_runs impl_1]]
set bitstream [file join $run_dir pynq_z2_top.bit]
if {![file exists $bitstream]} {
    error "Implementation completed, but the expected bitstream was not found: $bitstream"
}

file copy -force $bitstream [file join $artifact_dir CryptoCore_RV32.bit]
puts "Bitstream: [file join $artifact_dir CryptoCore_RV32.bit]"
puts "Reports:   $report_dir"
close_project
