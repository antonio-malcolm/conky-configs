#!/bin/sh

# Copyright 2015 Antonio Malcolm
#   
# This file, and all contents herein, is subject to the terms of the Mozilla Public License, v. 2.0. 
# If a copy of the MPL was not distributed with this file, 
# you can obtain one at http://mozilla.org/MPL/2.0/.
#
# conky-cpus-system-informatics-colors.sh - Obtains the max CPU speed, as well as the current speed for all available CPUs (or cores, or threads, as the case may be), 
# and generates a percentage for the current usage of each. Unless otherwise directed (by way of a parameter), generates a line of Conky text output for each, 
# and echoes the result. If directed to return only the generated percentages, a comma-delimited string of percentages is generated and echoed.  
#
# conky-cpus-system-informatics-colors.sh - Obtains the number of CPUs/cores/threads available and generates a corresponding number of lines of output for conky.
# Each line contains the CPU/core/thread number, current usage in MHz, and current usage, as a percentage.
#
# v2015.07.27
#
# Authored by Antonio Malcolm


font1="$1"
font2="$2"
color1="$3"
color2="$4"

if [ ! -z "$font1" ]
then
  font1='${font '"$font1"'}'
fi

if [ ! -z "$font2" ]
then
  font2='${font '"$font2"'}'
fi

if [ ! -z "$color1" ]
then
  color1='${'"$color1"'}'
fi

if [ ! -z "$color2" ]
then
  color2='${'"$color2"'}'
fi

result=''
cpuStatusOutput="`$HOME/.config/conky/scripts/posix/cpus-system-informatics-colors.sh`"

if [ -z "$cpuStatusOutput" ]
then
  echo "$font1$color1"'CPU Data Unavailable'
  exit 0
fi

cpuStatusOutput="$cpuStatusOutput,"

hasNext() {

  case "$1" in
    *,*) return 0 ;;
  esac

  return 1

}

count=1
voffset='-130'

while hasNext "$cpuStatusOutput"
do

  if [ $count -gt 1 ]
  then

    voffset='1'

# append newline...
result="$result"'
'

  fi
  
  statusPair="${cpuStatusOutput%%,*}"
  mhz="${statusPair%%:*}"
  percentage="${statusPair#*:}"

  result=$result'${goto 198}${voffset '$voffset'}'"$font1$color1$count $font2$color2$mhz"'MHz ${alignr 188}('$percentage'%)'

  cpuStatusOutput="${cpuStatusOutput#*,}"
  count=$(($count + 1))

done

echo "$result"
exit $?