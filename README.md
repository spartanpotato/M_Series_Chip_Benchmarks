# M_Series_Chip_Benchmarks
A tool to benchmark apple's M series chips. <br />
Currently there time and flops measurement for matmul using apple's MPS and accelerate for single presicion floats. As well as energy usage for both. Next update will see use of python to make proper graphs with that data.

## Requirements
- This project is meant to be run on M series chips.
- mac core utils to use gdate, to install use "brew install coreutils". 

## To compile
Inside the matmul folder use make, it will make executables for the main program and each matmul implementation.

## To execute
Once compiled, inside the same folder use ./matmul N checkResult checkEnergy, where N is the size of the matrices N x N, checkEnergy is a boolean that says if you want the program to perform a sequential matmul on cpu to verify the result, checkResult if you want see correctness with a sequential version, checkEnergy if you want to see energy usage.
<br />
To execute from the main program use "./prog -n \<value\> -h \<cpu|gpu\> -p \<16|32|64\> -c \<1|0\> -e \<1|0\> -i \<value\>" <br />
Where:
- n: positive integer, size of the n x n matrices.
- h: hardware, whether to use the cpu or gpu version.
- p: presicion, whether to use half, single or double presicion, as of now, only single presicion works.
- c: check, whether to compare the result with a sequential, cpu version of matmul.
- e: check energy, wether to check energy usage and leave it on a csv.
- i: iterations, how many times do you wish to repeat the benchmark.
On your first iteration you will be prompted to enter your password to use power metrics, it isn't necessary if you are not measuring energy usage


## To use script
Inside the script you can define the range of N you want to use, where each N will be a power of 2. and the number of times to execute with each N.<br />
Inside the matmul folder use "bash script.sh" it will compile and execute with the specifications given.

## To make graph
You need to have pandas installed. <br />
Inside the matmul folder, after having used the script, use "python Graficar.py".

## Considerations
Apple's accelerate depends on the number of cores veclib is allowed to use, to change them use "export VECLIB_MAXIMUM_THREADS=num_cores" <br />
The gpu implementation has high memory requirements, you need N^2 * 4 * 6 bytes to perform the benchmark. 

## Temporary
There is a folder power_sampling, its purpouse will be to get an average cpu and gpu usage that can be used to tell how much energy is actually used on the benchmarks.
