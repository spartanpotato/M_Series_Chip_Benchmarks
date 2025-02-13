#!/bin/bash

# Define the range of powers of 2 (inclusive)
start_power=6  
end_power=11

# Define hardware
hardware="cpu"

# define precision
precision=32


# Loop through the powers of 2
for (( p = start_power; p <= end_power; p++ )); do
  n=$((2**p))

  # Run the program
  echo "Running ./prog with hardware=$hardware, precision=$precision, n=$n and iterations=1"
  sudo ./prog --n $n --hardware $hardware --precision $precision --check 0 --instantEnergy 0 --energyOverTime 1 --iterations 1
done

# Transform data
echo "Transforming data with hardware=$hardware, precision=$precision"
python ./python_scripts/transform_${hardware}_over_time.py ${precision}

