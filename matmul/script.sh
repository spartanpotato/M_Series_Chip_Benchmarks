#!/bin/bash
low=5
high=14
iterations=3
cd ./cpu && make
cd ../gpu && make
cd ..
for ((i=low; i<=high; i++))
do
  for ((j=0; j<iterations; j++))
  do
    ./cpu/matmul $((2**i))
    ./gpu/matmul $((2**i))
  done
done
cd ./cpu && make clean
cd ../gpu && make clean