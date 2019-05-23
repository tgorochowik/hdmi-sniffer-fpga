create_project video_sniffer ./video_sniffer -part xc7z010clg400-1 -force
set_property "ip_repo_paths" "./fpga/ip_repo/" [get_filesets sources_1]
update_ip_catalog -rebuild
set_property target_language VHDL [current_project]
import_files -fileset sources_1 "./fpga/src/hdl/hdmi_ddc_w.vhd"
import_files -fileset sources_1 "./fpga/src/hdl/system_top.vhd"
import_files -fileset sources_1 "./fpga/src/hdl/twislavectl.vhd"
import_files -fileset constrs_1 "./fpga/src/constrs/top.xdc"
source ./fpga/src/bd/vsniff_top.tcl
set_property synth_checkpoint_mode Hierarchical [get_files ./video_sniffer/video_sniffer.srcs/sources_1/bd/vsniff_top/vsniff_top.bd]
