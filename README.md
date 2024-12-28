# M_Series_Chip_Benchmarks
A tool to benchmark apple's M series chips. <br />
Currently there is only time measurement for matmul using apple's MPS and accelerate.

## To compile
Inside the matmul folder both cpu and gpu versions have their own makefiles, move to the folder and use make. <br />

## To execute
Once compiled, inside the same folder use ./matmul N, where N is the size of the matrices N x N, you will get the compute time in miliseconds.

## To use script
Inside the script you can define the range of N you want to use, where each N will be a power of 2. and the number of times to execute with each. N<br />
Inside the matmul folder use "bash script.sh" it will compile and execute with the specifications given.

## To make graph
You need to have pandas installed. <br />
Inside the matmul folder, after having used the script, use "python Graficar.py".

