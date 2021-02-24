######################################
# Check hls
######################################

check_hls() {
  pushd $work_dir > /dev/null
  
  local hls_cxxflags="$cxxflags -I$source_dir"
  local hls_result=
  local hls_fail=1
  local hls_timeout=0
  local hls_error=0
  
  cat << EOS > hls.tcl
open_project -reset prj_hls_cosim
add_files -cflags "$hls_cxxflags" $kernel_source
set_top kernel
open_solution -flow_target $flow solution
set_part xcu200-fsgd2104-2-e
create_clock -period ${target_clock_period_ns}ns -name default
csynth_design
exit
EOS
  
  set +e
  timeout $hls_timeout vitis_hls -f hls.tcl > hls.log
  exit_code=$?
  set -e
  
  if [ $exit_code -eq 124 ] ; then
    hls_timeout=1
    hls_result="Timeout ($hls_timeout)"
  elif grep -e "^ERROR:" $work_dir/vitis_hls.log > /dev/null ; then
    hls_error=1
    hls_result="HLS error, see log file: $work_dir/hls.log"
  elif [ $exit_code -ne 0 ] ; then
    hls_error=1
    hls_result="HLS unknown error, see log file: $work_dir/hls.log"
  elif [ ! -e $work_dir/prj_hls_cosim/solution/syn/report/csynth.xml ] ; then
    hls_error=1
    hls_result="HLS report not found, see log file: $work_dir/hls.log"
  else
    hls_fail=0
    hls_result=Pass
  fi
  
  output_summary hls_fail=$hls_fail
  output_summary hls_timeout=$hls_timeout
  output_summary hls_error=$hls_error
  
  if [ $hls_fail -ne 0 ] ; then
    print_fail "HLS: " $hls_result
    exit
  else
    print_pass "HLS: " $hls_result
  fi
  
  popd > /dev/null
}
