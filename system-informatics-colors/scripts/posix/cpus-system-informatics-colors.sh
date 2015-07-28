#!/bin/sh

# Copyright 2015 Antonio Malcolm
#   
# This file, and all contents herein, is subject to the terms of the Mozilla Public License, v. 2.0. 
# If a copy of the MPL was not distributed with this file, 
# you can obtain one at http://mozilla.org/MPL/2.0/.
#
# cpus-system-informatics-colors.sh - Obtains the max CPU speed, as well as the current speed for all available CPUs (or cores, or threads, as the case may be), in Mhz, 
# generates a percentage for the current usage of each, then generates and echoes either a comma-delimited string of semicolon-delimted MHZ:percentage pairs, or, 
# if directed by way of an argument, generates and echoes a comma-delimited string of percentages only.  
#
# v2015.07.27
#
# Authored by Antonio Malcolm

percentagesOnly=false
reverseOrder=false

if [ ! -z "$1" ] && $1
then
  percentagesOnly=true
fi

if [ ! -z "$2" ] && $2
then
  reverseOrder=true
fi

result=''

fetchMHzFromOutput() {
  echo ${4%%.*}
}

cpuMaxMHz=`lscpu | grep 'CPU max MHz'`
cpuMaxMHz=`fetchMHzFromOutput $cpuMaxMHz`

voffset='-130'

cat /proc/cpuinfo | grep 'cpu MHz' | {

  count=1
  delimter=''

  while read -r line
  do

    if [ ! -z "$line" ]
    then

      if [ $count -gt 1 ]
      then
        delimiter=','
      fi
    
      cpuCurrentMHz=`fetchMHzFromOutput $line`
      cpuCurrentPercentage="`awk -v dividend=$cpuCurrentMHz -v divisor=$cpuMaxMHz 'BEGIN {printf "%.2f", dividend/divisor; exit}'`"

      if [ "$cpuCurrentPercentage" = '1.00' ]
      then
        cpuCurrentPercentage='100'
      else
        cpuCurrentPercentage="${cpuCurrentPercentage#*.}"
      fi

      if $percentagesOnly
      then
        
        if $reverseOrder
        then
          result="$cpuCurrentPercentage$delimiter$result"
        else
          result="$result$delimiter$cpuCurrentPercentage"
        fi

      else
        result="$result$delimiter$cpuCurrentMHz:$cpuCurrentPercentage"
      fi

      count=$(($count + 1))

    fi

  done

  echo "$result"
  exit $?

}

exit $?