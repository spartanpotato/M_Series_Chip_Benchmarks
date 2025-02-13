#include <stdbool.h>
#include <stdio.h>
#include <math.h>
#include "Conversion.h"

bool verify_matrix_product(float *A, float *B, float *C, int rowsA, int colsA, int colsB);

bool verify_matrix_product_16bits(float *A, float *B, float *C, int rowsA, int colsA, int colsB);
