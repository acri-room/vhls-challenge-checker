set period    [lindex $argv 2]
set srcs      [lindex $argv 3]
set cxxflags  [lindex $argv 4]
set ldflags   [lindex $argv 5]
set flow      [lindex $argv 6]
set test_srcs [lindex $argv 7]

regsub "cxxflags=" $cxxflags {} cxxflags
regsub "ldflags=" $ldflags {} ldflags

open_project prj
#add_files -cflags "$cxxflags" $srcs
add_files -cflags "$cxxflags -DCOSIM" -tb $test_srcs
#set_top kernel
open_solution -flow_target $flow solution
#set_part xcu200-fsgd2104-2-e
#create_clock -period $period -name default

#cosim_design -ldflags "$ldflags" -random_stall

exit

