######################################
# Get QoR
######################################
get_qor() {

  ruby << EOS >> $work_dir/qor.txt
require 'rexml/document'

doc = REXML::Document.new(File.new("$work_dir/prj_hls_cosim/solution/syn/report/csynth.xml"))

puts "ff=#{doc.elements['profile/AreaEstimates/Resources/FF'].text}"
puts "lut=#{doc.elements['profile/AreaEstimates/Resources/LUT'].text}"
puts "dsp=#{doc.elements['profile/AreaEstimates/Resources/DSP'].text}"
puts "bram=#{doc.elements['profile/AreaEstimates/Resources/BRAM_18K'].text}"
puts "uram=#{doc.elements['profile/AreaEstimates/Resources/URAM'].text}"
puts "clock_period=#{doc.elements['profile/PerformanceEstimates/SummaryOfTimingAnalysis/EstimatedClockPeriod'].text}"
EOS

  #eval $(grep clock_period $work_dir/qor.txt)
  eval $(cat $work_dir/qor.txt)

  if [[ $output ]] ; then
    cat $work_dir/qor.txt >> $output
  fi

  print_result "Resource usage"
  print_result "  FF   : " $ff
  print_result "  LUT  : " $lut
  print_result "  DSP  : " $dsp
  print_result "  BRAM : " $bram
  print_result "  URAM : " $uram
  print_result "Clock period (ns): " $clock_period
  print_result "Clock frequency (MHz): " $(echo "1000/$clock_period" | bc)
}

######################################
# Get simulation time
get_sim_time() {
  #sim_start=$(grep -e '^// RTL Simulation .* \[0\.00%\]' $work_dir/vitis_hls.log | awk -F @ '{print $2}' | sed 's/[^0-9]//g')
  #sim_end=$(grep -e '^// RTL Simulation .* \[100\.00%\]' $work_dir/vitis_hls.log | awk -F @ '{print $2}' | sed 's/[^0-9]//g')
  local sim_start=$(grep -e '^// RTL Simulation .* @ "[0-9]*"' $work_dir/cosim.log | head -n 1 | awk -F @ '{print $2}' | sed 's/[^0-9]//g')
  local sim_end=$(grep -e '^// RTL Simulation .* @ "[0-9]*"' $work_dir/cosim.log | tail -n 1 | awk -F @ '{print $2}' | sed 's/[^0-9]//g')
  
  local sim_time=$(echo "($sim_end-$sim_start)/1000" | bc)
  local sim_cycle=$(echo $sim_time/$target_clock_period_ns | bc)
  local sim_time=$(echo $sim_cycle*$clock_period | bc)
  
  output_summary sim_cycle=$sim_cycle
  output_summary sim_time=$sim_time

  print_result "Simulation cycle: " $sim_cycle
  print_result "Simulation time (ns): " $sim_time
}

