#!/bin/bash
low=6
high=8
iterations=2
cd ./cpu/32bits && make
cd ../../gpu/32bits && make
cd ../..
for ((i=low; i<=high; i++))
do
  for ((j=0; j<iterations; j++))
  do
    ./cpu/32bits/matmul $((2**i)) 0
    ./gpu/32bits/matmul $((2**i)) 0
  done
done
cd ./cpu/32bits && make clean
cd ../../gpu/32bits && make clean
