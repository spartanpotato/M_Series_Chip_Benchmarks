#!/bin/bash

# Define the range of powers of 2 (inclusive)
start_power=6  
end_power=11

# Define hardware
hardware="cpu"

# define precision
precision=32

# define iterations for different n
low=$((2**15))
middle=$((2**12))
high=$((2**5))

# Function to determine the number of iterations dynamically
determine_iterations() {
  local n=$1
  if (( n <= 2**7 )); then
    echo $low  # Small n, more iterations
  elif (( n <= 2**10 )); then
    echo $middle   # Medium n, moderate iterations
  else
    echo $high   # Large n, fewer iterations
  fi
}

# Loop through the powers of 2
for (( p = start_power; p <= end_power; p++ )); do
  n=$((2**p))
  iterations=$(determine_iterations $n)

  # Run the program
  echo "Running ./prog with hardware=$hardware, precision=$precision, n=$n and iterations=$iterations"
  sudo ./prog --n $n --hardware $hardware --precision $precision --check 0 --instantEnergy 0 --energyOverTime 0 --iterations $iterations
done



