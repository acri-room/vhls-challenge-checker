#inspect_args

# Get arguments and flags
source_dir=${args[source_dir]}
output=${args[--output]}
work_dir=${args[--work-dir]}
docker=${args[--docker]}
force=${args[--force]}

set -ue

source_dir=$(readlink -f $source_dir)
work_dir=$(readlink -f $work_dir)

self=$(readlink -f $BASH_SOURCE)
self_base=$(basename $self)
self_dir=$(dirname $self)

# Argument check
if [[ ! -e $source_dir ]] ; then
  red_bold Error: "Source directory '$source_dir' doesn't exist!"
  exit 1
fi

if [[ $output ]] ; then
  output=$(readlink -f $output)
  if [[ $force ]] ; then
    echo > $force
  elif [[ -e $output ]] ; then
    red_bold Error: "Output file '$output' already exists!"
    exit 1
  fi
fi

if [[ ! $force ]] && [[ -e $work_dir ]] ; then
  red_bold Error: "Working directory '$work_dir' already exists!"
  exit 1
fi

# Docker
if [[ $docker ]] ; then
  repo=$self_base
  tag=latest

  # Build docker
  docker build -t $repo:$tag $self_dir

  # Run docker
  run_opts=
  if [[ $output ]] ; then
    touch $output
    run_opts="-v $output:/tmp/output.txt:rw"
  fi

  docker run \
    -v /tools/Xilinx:/tools/Xilinx:ro \
    -v $self:/tmp/$self_base:ro \
    -v $source_dir:/tmp/source:ro \
    --cpus=1 \
    --memory 4g \
    $run_opts \
    $repo:$tag \
    /tmp/$self_base --force --output /tmp/output.txt /tmp/source
  
  exit
fi

# Source files
regulation=$source_dir/regulation.txt
tb=$source_dir/tb.cpp
kernel_source=$source_dir/kernel.cpp
kernel_header=$source_dir/kernel.hpp

# Argument check
if [ ! -e $regulation ] ; then
  red_bold "Error: Regulation file ($regulation) doesn't exist!"
  exit 1
fi

if [ ! -e $tb ] ; then
  red_bold "Error: Testbench ($tb) doesn't exist!"
  exit 1
fi

if [ ! -e $kernel_source ] ; then
  red_bold "Error: Kernel source ($kernel_source) doesn't exist!"
  exit 1
fi

if [ ! -e $kernel_header ] ; then
  red_bold "Error: Kernel header ($kernel_header) doesn't exist!"
  exit 1
fi

# Load regulation
target_clock_period_ns=10
flow=vivado
vitis_version=2020.2
csim_timeout=1m
hls_timeout=5m
cosim_timeout=5m
cxxflags=
ldflags=

source $regulation

# Tool setup
source /tools/Xilinx/Vitis/$vitis_version/settings64.sh

# Create working directory
mkdir -p $work_dir

# Check
check_bytes
check_csim
check_hls
check_cosim
get_qor
get_sim_time
