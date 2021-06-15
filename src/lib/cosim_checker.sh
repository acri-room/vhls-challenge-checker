######################################
# Check cosim
######################################

check_cosim() {
  print_progress cosim

  pushd $work_dir > /dev/null
  
  local cosim_cxxflags="$cxxflags -I$source_dir"
  local cosim_result=
  local cosim_fail=1
  local cosim_timeout_error=0
  local cosim_error=0
  local cosim_mismatch=0
  
  cat << EOS > cosim.tcl
open_project prj_hls_cosim
add_files -cflags "$cosim_cxxflags -DCOSIM" -tb $tb
open_solution -flow_target $flow solution
cosim_design -ldflags "$ldflags" -random_stall
exit
EOS

  set +e
  timeout $cosim_timeout time vitis_hls -f cosim.tcl |& tee cosim.log > $logout
  exit_code=$?
  set -e
  
  if [ $exit_code -eq 124 ] ; then
    cosim_timeout_error=1
    cosim_result="Timeout ($cosim_timeout)"
  elif grep --text -e "^ERROR:" $work_dir/vitis_hls.log | grep "nonzero return value" > /dev/null ; then
    cosim_mismatch=1
    cosim_result="Mismatch"
  elif grep --text -e "^ERROR:" $work_dir/vitis_hls.log > /dev/null ; then
    cosim_error=1
    cosim_result="Error, see log file: $work_dir/cosim.log"
  elif [ $exit_code -ne 0 ] ; then
    cosim_error=1
    cosim_result="Unknown error, see log file: $work_dir/cosim.log"
  else
    cosim_fail=0
    cosim_result="Pass"
  fi
  
  output_summary cosim_fail=$cosim_fail
  output_summary cosim_timeout=$cosim_timeout_error
  output_summary cosim_error=$cosim_error
  output_summary cosim_mismatch=$cosim_mismatch

  copy_log cosim.log
  
  if [ $cosim_fail -ne 0 ] ; then
    print_fail "CoSim: " $cosim_result
    exit
  else
    print_pass "CoSim: " $cosim_result
  fi
  
  popd > /dev/null
}
