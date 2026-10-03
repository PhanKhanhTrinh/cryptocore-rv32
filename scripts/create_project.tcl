# Recreate a portable Vivado project from the checked-in sources.

set script_dir [file dirname [file normalize [info script]]]
set repo_root  [file normalize [file join $script_dir ..]]
set build_dir  [file normalize [file join $repo_root build]]

file mkdir $build_dir
create_project CryptoCore_RV32 $build_dir -part xc7z020clg400-1 -force

set_property target_language Verilog [current_project]
set_property default_lib xil_defaultlib [current_project]

if {[catch {
    set_property board_part tul.com.tw:pynq-z2:part0:1.0 [current_project]
} board_error]} {
    puts "WARNING: PYNQ-Z2 board files were not found; continuing with the XC7Z020 part."
}

set rtl_dir [file join $repo_root CryptoCore_RV32.srcs sources_1 imports rtl]
set cpu_file [file join $repo_root CryptoCore_RV32.srcs sources_1 new picorv32.v]
set fw_dir [file join $repo_root CryptoCore_RV32.srcs sources_1 imports firmware]
set tb_dir [file join $repo_root CryptoCore_RV32.srcs sim_1 imports tb]
set xdc_file [file join $repo_root CryptoCore_RV32.srcs constrs_1 imports constraints pynq_z2.xdc]

set rtl_files [glob -nocomplain -directory $rtl_dir *.v]
lappend rtl_files $cpu_file
add_files -norecurse $rtl_files

set mem_files [glob -nocomplain -directory $fw_dir *.hex]
add_files -norecurse $mem_files
foreach mem_file $mem_files {
    set_property file_type {Memory Initialization Files} [get_files -all $mem_file]
}

add_files -fileset constrs_1 -norecurse $xdc_file

set tb_files [glob -nocomplain -directory $tb_dir *.v]
add_files -fileset sim_1 -norecurse $tb_files

set_property top pynq_z2_top [get_filesets sources_1]
set_property top tb_soc_firmware [get_filesets sim_1]
set_property xsim.simulate.runtime 20us [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "Created project: [file join $build_dir CryptoCore_RV32.xpr]"
