#!/bin/bash
# The purpose of this script is to generate timing/profiling files for each binary
#  called using this script
# The way to use it is just to prepend this script ("zlayer.sh") on your binary/app
#  command line.

#== check_pid() ==
# Check if the given PID is running
check_pid()
{
  [
  echo $?
}

#== pid2tree() ==
# Insert accordingly the given PID to their tree
pid_command_list=()
pid_parents_tree=()
ppid()
{
  ps -p $1 -o ppid=;
}
add2tree()
{
  # '$1' : PID array branch
  # '$2' : parent's PID
  # '$3' : current PID
  [ -z "$1" -o -z "$2" -o -z "$3" ] && exit 123
  tree=$1
  [ -z "${tree[$2]}" ] && tree[$2]=($3) || add2tree tree[$2] $2 $3
}
pid2tree()
{
  parent=$(ppid $1)
  add2tree $parent $1
}

#== mv_gmon() ==
# Remove or rename the gprof output (profile) file. The renaming is necessary because
#  gprof always create the file 'gmon.out', unless you explicitly change that during
#  compilation. Easier to rename it...
#
mv_gmon()
{
  if [[ -f "gmon.out" ]]; then
      if [[ "$#" -eq "0" ]]; then
          rm gmon.out
      else
          mv gmon.out "$1".gmon
      fi
#  else
#      echo "File 'gmon.out' not found"
  fi
}

BIN=$(basename "$1")

if [[ -z "$1" ]]; then
    echo "Usage: $0 'binary' [arguments]"
    exit 1
else
    if [[ ! -x `which $BIN` ]]; then
        >&2 echo "File called for profiling is not executable"
        exit 1
    fi
fi

#== taimin() ==
# Just collect the amount of time spent running the given binary.
#
function taimin(){
#  TFILE="$1.time"
  time -p $* > $1_command.out
#  echo "command $*" >> $TFILE
}

#== amplxe() ==
# If available, profile using Intel's VTune, otherwise collect the time spent.
#
function amplxe(){
  AMPL=$(which amplxe-cl)
  if [[ -z "$AMPL" ]]; then
      echo "amplxe-cl not found, running the timing function instead.."
      taimin $*
  else
      amplxe-cl -collect hotspots -r "prof_$1" -no-auto-finalize -- $*
  fi
}

mv_gmon
RUN="$*"
set +xv

taimin $RUN
!-1:p | tr -s ' ' | cut -d ' ' -f2-
pid=$$
until [ "$pid" -eq "1" ]; do cmd=$(ps -p $pid -o command=;); ppid=$(ps -p $pid -o ppid=;); echo "$pid : $cmd"; pid=$ppid; done

set -xv
mv_gmon $BIN

