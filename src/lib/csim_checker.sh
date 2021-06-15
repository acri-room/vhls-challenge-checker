######################################
# Check csim
######################################

check_csim() {
  print_progress csim

  pushd $work_dir > /dev/null

  local csim_cxxflags="$cxxflags -I$source_dir"
  local csim_result=
  local csim_fail=1
  local csim_timeout_error=0
  local csim_compile_error=0
  local csim_runtime_error=0
  local csim_error=0
  local csim_mismatch=0
  
  cat << EOS > csim.tcl
open_project -reset prj_csim
add_files -cflags "$csim_cxxflags" $kernel_source
add_files -cflags "$csim_cxxflags -DCSIM" -tb $tb
set_top kernel
open_solution -flow_target $flow solution
set_part xcu200-fsgd2104-2-e
create_clock -period ${target_clock_period_ns}ns -name default
csim_design -ldflags "$ldflags"
exit
EOS
  
  set +e
  timeout $csim_timeout time vitis_hls -f csim.tcl |& tee csim.log > $logout
  local exit_code=$?
  set -e
  
  if [ $exit_code -eq 124 ] ; then
    csim_timeout_error=1
    csim_result="Timeout ($csim_timeout)"
  elif grep --text -e "^ERROR:" $work_dir/vitis_hls.log | grep "compilation error" > /dev/null ; then
    csim_compile_error=1
    csim_result="Compile error, see log file: $work_dir/csim.log"
  elif grep --text -e "^ERROR:" $work_dir/vitis_hls.log | grep "CSim failed with errors" > /dev/null ; then
    csim_runtime_error=1
    csim_result="Runtime error, see log file: $work_dir/csim.log"
  elif grep --text -e "^ERROR:" $work_dir/vitis_hls.log | grep "nonzero return value" > /dev/null ; then
    csim_mismatch=1
    csim_result="Mismatch"
  elif [ $exit_code -ne 0 ] ; then
    csim_error=1
    csim_result="Unknown error (exit code: $exit_code), see log file: $work_dir/csim.log"
  else
    csim_fail=0
    csim_result="Pass"
  fi
  
  output_summary csim_fail=$csim_fail
  output_summary csim_timeout=$csim_timeout_error
  output_summary csim_compile_error=$csim_compile_error
  output_summary csim_runtime_error=$csim_runtime_error
  output_summary csim_error=$csim_error
  output_summary csim_mismatch=$csim_mismatch

  copy_log csim.log
  
  if [ $csim_fail -ne 0 ] ; then
    print_fail "CSim: " $csim_result
    exit
  else
    print_pass "CSim: " $csim_result
  fi
  
  popd > /dev/null
}
