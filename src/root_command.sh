#inspect_args

#set -x

# Get arguments and flags
source_dir=${args[source_dir]}
output=${args[--output]}
work_dir=${args[--work-dir]}
synthesis=${args[--synthesis]}
verbose=${args[--verbose]}
docker=${args[--docker]}
force=${args[--force]}
log_dir=${args[--log-dir]}
log_limit=${args[--log-limit]}
progress=${args[--progress]}

set -ue

source_dir=$(readlink -f $source_dir)
work_dir=$(readlink -f $work_dir)

self=$(readlink -f $BASH_SOURCE)
self_base=$(basename $self)
self_dir=$(dirname $self)

logout=/dev/null
if [[ $verbose ]] ; then
  logout=/dev/stdout
fi

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

if [[ $log_dir ]] ; then
  log_dir=$(readlink -f $log_dir)
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
  #docker build -t $repo:$tag $self_dir
  build_docker_image -t $repo:$tag

  # Run docker
  run_opts=
  if [[ $output ]] ; then
    touch $output
    run_opts="$run_opts -v $output:/tmp/output.txt:rw"
  fi
  if [[ $log_dir ]] ; then
    mkdir $log_dir
    run_opts="$run_opts -v $log_dir:/tmp/log:rw"
  fi

  cmd_opts=
  if [[ $synthesis ]] ; then
    cmd_opts="$cmd_opts --synthesis"
  fi
  if [[ $log_limit ]] ; then
    cmd_opts="$cmd_opts --log-limit $log_limit"
  fi
  if [[ $progress ]] ; then
    cmd_opts="$cmd_opts --progress"
  fi

  docker run \
    --rm \
    -v /tools/Xilinx:/tools/Xilinx:ro \
    -v $self:/tmp/$self_base:ro \
    -v $source_dir:/tmp/source:ro \
    --cpus=1 \
    --memory 16g \
    --env LIBRARY_PATH=/usr/lib/x86_64-linux-gnu \
    $run_opts \
    $repo:$tag \
    /tmp/$self_base --force --output /tmp/output.txt --log-dir /tmp/log $cmd_opts /tmp/source
  
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
flow=vitis
vitis_version=2020.2
csim_timeout=1m
hls_timeout=5m
cosim_timeout=5m
syn_timeout=30m
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

if [[ $synthesis ]] ; then
  check_syn
fi

get_qor
get_sim_time

output_summary normal_exit=1

