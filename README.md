# M_Series_Chip_Benchmarks
A tool to benchmark apple's M series chips. <br />
Currently there is only time measurement for matmul using apple's MPS and accelerate for single presicion floats.

## To compile
Inside the matmul folder both cpu and gpu versions have their own makefiles, move to the folder and use make. <br />
To use the main program you also need to use make on the matmul folder

## To execute
Once compiled, inside the same folder use ./matmul N check, where N is the size of the matrices N x N, and check is a boolean that says if you want the program to perform a sequential matmul on cpu to verify the result. You will get the compute time in miliseconds, the gflops, and, if check is '1', wether the result was correct.
<br />
To execute from the main program use "./prog -n \<value\> -h \<cpu|gpu\> -p \<16|32|64\> -c \<1|0\>" <br />
Where:
- n: positive integer, size of the n x n matrices.
- h: hardware, whether to use the cpu or gpu version.
- p: presicion, whether to use half, single or double presicion, as of now, only single presicion works.
- c: check, whether to compare the result with a sequential, cpu version of matmul.


## To use script
Inside the script you can define the range of N you want to use, where each N will be a power of 2. and the number of times to execute with each. N<br />
Inside the matmul folder use "bash script.sh" it will compile and execute with the specifications given.

## To make graph
You need to have pandas installed. <br />
Inside the matmul folder, after having used the script, use "python Graficar.py".

## Considerations
Apple's accelerate depends on the number of cores veclib is allowed to use, to change them use "export VECLIB_MAXIMUM_THREADS=num_cores" <br />
The gpu implementation has high memory requirements, you need N^2 * 4 * 6 bytes to perform the benchmark.
