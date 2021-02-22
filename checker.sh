# Usage
if [ $# -ne 3 ] ; then
  echo Error: The number of arguments should be 3!
  echo usage: $0 REGULATION TB SUBMIT_DIR
  exit 1
fi

regulation=$1; shift
tb=$1; shift
submit_dir=$1; shift

# Argument check
if [ ! -e $regulation ] ; then
  echo "Error: Specified REGULATION file ($regulation) doesn't exist!"
  exit 1
fi

if [ ! -e $tb ] ; then
  echo "Error: Specified TB file ($tb) doesn't exist!"
  exit 1
fi

if [ ! -e $submit_dir ] ; then
  echo "Error: Specified SUBMIT_DIR ($submit_dir) doesn't exist!"
  exit 1
fi

# Absolute path
tb=$(readlink -f $tb)
regulation=$(readlink -f $regulation)
submit_dir=$(readlink -f $submit_dir)

# Directories
cur_dir=$(pwd)
checker_dir=$(dirname $(readlink -f $0))

# Check submit files
#if [ ! -e $submit_dir/kernel.cpp ] ; then
#  echo "ERROR: Kernel code ($submit_dir/kernel.cpp) doesn't exist!"
#  exit 1
#fi
#
#if [ ! -e $submit_dir/kernel.hpp ] ; then
#  echo "ERROR: Kernel header ($submit_dir/kernel.hpp) doesn't exist!"
#  exit 1
#fi

submit_source_files=$(ls $submit_dir/*.cpp)

# Read regulation
target_clock_period_ns=10
flow=vivado
vitis_version=2020.2
csim_timeout=1m
hls_timeout=5m
cosim_timeout=5m

source $regulation

# Prepare output file
result=$cur_dir/result.txt
rm -f $result

# Tool setup
source /tools/Xilinx/Vitis/$vitis_version/settings64.sh

######################################
# Check file size
bytes=$(cat $submit_dir/* | wc -c | awk '{print $1}')
echo "bytes=$bytes" >> $result

echo bytes: $bytes

######################################
# Check csim
csim_cxxflags="$cxxflags -I$submit_dir -I$(dirname $tb)"

work_dir=$cur_dir/work_csim
rm -rf $work_dir
mkdir -p $work_dir
pushd $work_dir > /dev/null

timeout $csim_timeout vitis_hls \
  -f $checker_dir/tcl/csim.tcl \
  ${target_clock_period_ns}ns \
  "$submit_source_files" \
  "cxxflags=$csim_cxxflags" \
  "ldflags=$ldflags" \
  $flow \
  $tb > /dev/null

exit_code=$?

csim_result=
csim_fail=1
csim_timeout=0
csim_compile_error=0
csim_runtime_error=0
csim_error=0
csim_mismatch=0

if [ $exit_code -eq 124 ] ; then
  csim_timeout=1
  csim_result="timeout ($csim_timeout)"
elif grep -e "^ERROR:" $work_dir/vitis_hls.log | grep "compilation error" > /dev/null ; then
  csim_compile_error=1
  csim_result="compile error, see log file: $work_dir/vitis_hls.log"
elif grep -e "^ERROR:" $work_dir/vitis_hls.log | grep "CSim failed with errors" > /dev/null ; then
  csim_runtime_error=1
  csim_result="runtime error, see log file: $work_dir/vitis_hls.log"
elif grep -e "^ERROR:" $work_dir/vitis_hls.log | grep "nonzero return value" > /dev/null ; then
  csim_mismatch=1
  csim_result="mismatch"
elif [ $exit_code -ne 0 ] ; then
  csim_error=1
  csim_result="unknown error (exit code: $exit_code), see log file: $work_dir/vitis_hls.log"
else
  csim_fail=0
  csim_result="pass"
fi

echo csim_fail=$csim_fail >> $result
echo csim_timeout=$csim_timeout >> $result
echo csim_compile_error=$csim_compile_error >> $result
echo csim_runtime_error=$csim_runtime_error >> $result
echo csim_error=$csim_error >> $result
echo csim_mismatch=$csim_mismatch >> $result

echo csim: $csim_result

if [ $csim_fail -ne 0 ] ; then
  exit
fi

popd > /dev/null

######################################
# Check hls
hls_cxxflags="$cxxflags -I$submit_dir"

work_dir=$cur_dir/work_hls_cosim
rm -rf $work_dir
mkdir -p $work_dir
pushd $work_dir > /dev/null

hls_result=
hls_fail=1
hls_timeout=0
hls_error=0

timeout $hls_timeout vitis_hls \
  -f $checker_dir/tcl/hls.tcl \
  ${target_clock_period_ns}ns \
  "$submit_source_files" \
  "cxxflags=$hls_cxxflags" \
  "ldflags=$ldflags" \
  $flow \
  $tb > /dev/null

exit_code=$?

if [ $exit_code -eq 124 ] ; then
  hls_timeout=1
  hls_result="timeout ($hls_timeout)"
elif grep -e "^ERROR:" $work_dir/vitis_hls.log > /dev/null ; then
  hls_error=1
  hls_result="hls error, see log file: $work_dir/vitis_hls.log"
elif [ $exit_code -ne 0 ] ; then
  hls_error=1
  hls_result="hls unknown error, see log file: $work_dir/vitis_hls.log"
elif [ ! -e $work_dir/prj/solution/syn/report/csynth.xml ] ; then
  hls_error=1
  hls_result="hls report not found, see log file: $work_dir/vitis_hls.log"
else
  hls_fail=0
  hls_result=pass
fi

echo hls_fail=$hls_fail >> $result
echo hls_timeout=$hls_timeout >> $result
echo hls_error=$hls_error >> $result

echo hls: $hls_result

if [ $hls_fail -ne 0 ] ; then
  exit
fi

popd > /dev/null

######################################
# Check cosim
pushd $work_dir > /dev/null

cosim_cxxflags="$cxxflags -I$submit_dir -I$(dirname $tb)"

cosim_result=
cosim_fail=1
cosim_timeout=0
cosim_error=0
cosim_mismatch=0

timeout $cosim_timeout vitis_hls \
  -f $checker_dir/tcl/cosim.tcl \
  ${target_clock_period_ns}ns \
  "$submit_source_files" \
  "cxxflags=$cosim_cxxflags" \
  "ldflags=$ldflags" \
  $flow \
  $tb > /dev/null

exit_code=$?

if [ $exit_code -eq 124 ] ; then
  cosim_timeout=1
  cosim_result="timeout ($cosim_timeout)"
elif grep -e "^ERROR:" $work_dir/vitis_hls.log | grep "nonzero return value" > /dev/null ; then
  cosim_mismatch=1
  cosim_result="mismatch"
elif grep -e "^ERROR:" $work_dir/vitis_hls.log > /dev/null ; then
  cosim_error=1
  cosim_result="error, see log file: $work_dir/vitis_hls.log"
elif [ $exit_code -ne 0 ] ; then
  cosim_error=1
  cosim_result="unknown error, see log file: $work_dir/vitis_hls.log"
else
  cosim_fail=0
  cosim_result="pass"
fi

echo cosim_fail=$cosim_fail >> $result
echo cosim_timeout=$cosim_timeout >> $result
echo cosim_error=$cosim_error >> $result
echo cosim_mismatch=$cosim_mismatch >> $result

echo cosim: $cosim_result

if [ $cosim_fail -ne 0 ] ; then
  exit
fi

popd > /dev/null

######################################
# Get QoR
ruby $checker_dir/get_hls_qor.rb $work_dir/prj/solution/syn/report/csynth.xml >> $result

eval $(grep clock_period $result)

######################################
# Get simulation time
#sim_start=$(grep -e '^// RTL Simulation .* \[0\.00%\]' $work_dir/vitis_hls.log | awk -F @ '{print $2}' | sed 's/[^0-9]//g')
#sim_end=$(grep -e '^// RTL Simulation .* \[100\.00%\]' $work_dir/vitis_hls.log | awk -F @ '{print $2}' | sed 's/[^0-9]//g')
sim_start=$(grep -e '^// RTL Simulation .* @ "[0-9]*"' $work_dir/vitis_hls.log | head -n 1 | awk -F @ '{print $2}' | sed 's/[^0-9]//g')
sim_end=$(grep -e '^// RTL Simulation .* @ "[0-9]*"' $work_dir/vitis_hls.log | tail -n 1 | awk -F @ '{print $2}' | sed 's/[^0-9]//g')

sim_time=$(echo "($sim_end-$sim_start)/1000" | bc)
sim_cycle=$(echo $sim_time/$target_clock_period_ns | bc)
sim_time=$(echo $sim_cycle*$clock_period | bc)

echo sim_cycle=$sim_cycle >> $result
echo sim_time=$sim_time >> $result

