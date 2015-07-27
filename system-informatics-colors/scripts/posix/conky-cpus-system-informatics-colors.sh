#!/bin/sh

# Copyright 2015 Antonio Malcolm
#   
# This file, and all contents herein, is subject to the terms of the Mozilla Public License, v. 2.0. 
# If a copy of the MPL was not distributed with this file, 
# you can obtain one at http://mozilla.org/MPL/2.0/.
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

result="$font1$color1"'CPU Data Unavailable'

cpuCount=`nproc`
cpuMaxSpeed=`lscpu | awk '/CPU max MHz/{printf "%.f",$4; exit}'`

if [ ! -z "$cpuCount" ]
then

  voffset='-130'

  if [ $cpuCount -gt 1 ]
  then

    result=''

    for idx in `seq 1 $cpuCount`
    do

      if [ $idx -gt 1 ]
      then

# append newline...
result="$result"'
'

        voffset='1'

      fi

      cpuCurrentSpeed=`awk -v idx=$idx '/cpu MHz/{i++}i==idx{printf "%.f",$4; exit}' /proc/cpuinfo`

      cpuUsePercentage=`awk -v dividend=$cpuCurrentSpeed -v divisor=$cpuMaxSpeed 'BEGIN {printf "%.2f", dividend/divisor; exit}'`
      cpuUsePercentage="${cpuUsePercentage#*.}"

      result=$result'${goto 198}${voffset '$voffset'}'"$font1$color1$idx $font2$color2$cpuCurrentSpeed"'MHz ${alignr 188}('$cpuUsePercentage'%)'

    done

  else

    # default to MHz output of single CPU, with average CPU load percentage...
    result='${goto 198}${voffset '$voffset'}'"$font1$color1"'0'" $font2$color2"'${'"exec awk '/cpu MHz/{i++}i==1{printf \"%.f\","'$4; exit}'"' /proc/cpuinfo}MHz"' ${alignr 188}(${cpu cpu0}%)'

  fi

fi

echo "$result"
exit $?