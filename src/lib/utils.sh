output_summary() {
  if [[ $output ]] ; then
    echo "$*" >> $output
  fi
}

copy_log() {
  if [[ $log_dir ]] ; then
    if [[ $log_limit ]] ; then
      head -c $log_limit "$1" > $log_dir/$(basename "$1")
    else
      cp "$1" $log_dir/$(basename "$1")
    fi
  fi
}

bold_nnl() { printf "\e[1m%b\e[0m" "$*"; }

print_result() {
  bold_nnl "$1"; shift
  echo "$*"
}

print_pass() {
  bold_nnl "$1"; shift
  green "$*"
}

print_fail() {
  bold_nnl "$1"; shift
  red "$*"
}

print_progress() {
  if [[ $progress ]] ; then
    echo testing_$1
  fi
}

check_bytes() {
  local bytes
  bytes=$(cat $kernel_header $kernel_source | wc -c  | awk '{print $1}')
  output_summary bytes=$bytes
  print_result "Bytes of kernel code: " $bytes
}
