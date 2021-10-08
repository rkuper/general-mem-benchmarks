#!/bin/bash

# LLCRDMISS
# awk '/LLCRDMISSLAT \(ns\)/ { getline; getline; print $9 }'

total_runs=4
metrics=()

for loop in $(eval echo {1..$total_runs})
do
  sudo ./run-one.sh > temp_$loop.txt
done

 awk '/LLCRDMISSLAT \(ns\)/ { getline; getline; print $9 }' ../results/32x1_2400_1chan_default_run2.txt
