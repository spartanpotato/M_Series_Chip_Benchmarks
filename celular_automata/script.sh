#!/bin/bash

# Define parameter ranges
memoryAccessModes=("shared" "managed" "private")
iterations=100
instantEnergy=0
energyOverTime=0

# Loop through all combinations
for ((n=2**7; n<=2**14; n*=2)); do
    for radius in {1..5}; do
        for memoryAccess in "${memoryAccessModes[@]}"; do
            echo "Running: ./prog --n $n --radius $radius --memoryAccess $memoryAccess --instantEnergy $instantEnergy --energyOverTime $energyOverTime --iterations $iterations"
            ./prog --n $n --radius $radius --memoryAccess $memoryAccess --instantEnergy $instantEnergy --energyOverTime $energyOverTime --iterations $iterations
        done
    done
done