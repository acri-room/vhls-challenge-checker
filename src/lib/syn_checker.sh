######################################
# Check syn
######################################

check_syn() {
  pushd $work_dir > /dev/null
  
  local syn_fail=1
  local syn_timeout_error=0
  
  cat << EOS > syn.tcl
open_project prj_hls_cosim
open_solution -flow_target $flow solution
export_design -flow syn -rtl verilog -format ip_catalog
exit
EOS
  
  set +e
  timeout $syn_timeout time vitis_hls -f syn.tcl &> syn.log
  exit_code=$?
  set -e
  
  if [ $exit_code -eq 124 ] ; then
    syn_timeout_error=1
    syn_result="Timeout ($syn_timeout)"
  else
    syn_fail=0
    syn_result=Pass
  fi
  
  output_summary syn_fail=$syn_fail
  output_summary syn_timeout=$syn_timeout_error
  
  if [ $syn_fail -ne 0 ] ; then
    print_fail "Syn: " $syn_result
    exit
  else
    print_pass "Syn: " $syn_result
  fi
  
  popd > /dev/null
}

