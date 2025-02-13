# M_Series_Chip_Benchmarks
A tool to benchmark apple's M series chips. <br />
Currently there time is and flops measurement for matmul using apple's MPS and accelerate for single presicion floats. As well as energy usage for both. Next update will see use of python to make proper graphs with that data.

## Requirements
- This project is meant to be run on M series chips.
- mac core utils to use gdate, to install use "brew install coreutils".
- pandas for grahps.

## To compile
Inside the matmul folder use make, it will make executables for the main program and each matmul implementation.

## To execute
Once compiled, inside the same folder use ./matmul N checkResult checkInstantEnergy checkEnergyOverTime iterations.
<br />
To execute from the main program use "./prog -n \<value\> -hardware \<cpu|gpu\> -precision \<16|32\> -check \<1|0\> -instantEnergy \<1|0\> -energyOverTime \<value\> -iterations \<value\>" <br />
Where:
- n: positive integer, size of the n x n matrices.
- hardware: whether to use the cpu or gpu version.
- precision: whether to use half, single or double presicion, as of now, only single presicion works.
- check: whether to compare the result with a sequential, cpu version of matmul.
- instantEnergy: whether to check energy usage without timesnaps to get an average. 
- energyOverTime: wheter to check energy usage with timesnaps.
- iterations: how many times do you wish to repeat the calculation.
You will be prompted to enter your password to use power metrics.<br />
You cannot check instant energy and energy over time at the same time <br />
The number of iterations must be 1 for energy over time.



## To use script
There are four bash scripts. three similar ones to execute the benchmark with multiple powers o 2 as n checking instant energy usage, energy over time, and not checking energy, and a final one to clear all output files. <br />
All scripts to execute have a few variables you may modify to change the scripts. These are:
- start_power: from which power of two should the script start.
- end_power: at which power of two should the script end.
- hardware: whether to use cpu or gpu
- precision: whether to use float32 or float16, only gpu is allowed float16
- low: how many iterations to use for n <= 2^7
- middle: how many iterations to use for 2^7 < n <= 2^12
- high: how many iterations to use for n > 2^12

## To make graph
If you ran the program without the script you must use, from the matmul folder "sudo python ./python_scripts/\<adequate transform script.\>" where the script depends on the options you used, there are four that follow the structure transform_\<hardware\>_\<instant|over_time\>.py. They will transform the csv data to something easier to graph, the script will do it automatically. <br />
Once you have the transformed script use the appropiate python script.
- "python ./python_scripts/graph_efficency.py hardware precision" if you used instant energy.
- "python ./python_scripts/power_time.py hardware precision max_n" if you used energy over time, where max_n means up to which power of 2 you which to graph, in order to not graph all of them and make small numbers not visible.
This will open the graph and also save it as a png insde outputs/graphs.

## Considerations
Apple's accelerate depends on the number of cores veclib is allowed to use, to change them use "export VECLIB_MAXIMUM_THREADS=num_cores" <br />
The gpu implementation has high memory requirements, you need N^2 * 4 * 6 bytes to perform the benchmark. 


