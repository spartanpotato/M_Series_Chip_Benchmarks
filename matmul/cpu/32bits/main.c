#include <stdio.h>
#include <stdlib.h>
#include <Accelerate/Accelerate.h>
#include <time.h>
#include "../../Verify.h"

// Genera matriz
void generate_random_matrix(float *matrix, int size) {
    for (int i = 0; i < size * size; i++) {
        matrix[i] = (float)rand() / RAND_MAX;
    }
}

int main(int argc, char *argv[]) {
    if (argc != 3) {
        printf("Se debe ejecutar como ./matmul N Check");
        return 1;
    }

    int N = atoi(argv[1]);
    if (N <= 0) {
        printf("N debe ser entero positivo");
        return 1;
    }

    int check = atoi(argv[2]);

    // Reserva memoria para matrices
    float *A = (float *)malloc(N * N * sizeof(float));
    float *B = (float *)malloc(N * N * sizeof(float));
    float *C = (float *)malloc(N * N * sizeof(float));
    if (!A || !B || !C) {
        printf("Error al reservar memoria para matrices");
        free(A);
        free(B);
        free(C);
        return 1;
    }

    struct timespec start_mul, end_mul;

    generate_random_matrix(A, N);
    generate_random_matrix(B, N);

    // Medir tiempo para la multiplicación de matrices
    clock_gettime(CLOCK_MONOTONIC, &start_mul);

    // Multiplicacion de matrices usando BLAS
    cblas_sgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans,
                N, N, N, 
                1.0, A, N, B, N, 
                0.0, C, N);

    clock_gettime(CLOCK_MONOTONIC, &end_mul);

    // Calcular tiempo para la multiplicación
    long mul_seconds = end_mul.tv_sec - start_mul.tv_sec;
    long mul_nanoseconds = end_mul.tv_nsec - start_mul.tv_nsec;
    double mul_elapsedTime = mul_seconds * 1000.0 + mul_nanoseconds / 1000000.0;


    // Calcular FLOPS
    double flops = (2.0 * N * N * N) / (mul_elapsedTime / 1000);

    // Verificar correctitud
    if(check == 1){
        bool isCorrect = verify_matrix_product(A, B, C, N, N, N);
        if (isCorrect){
            printf("El calculo fue correcto\n");
        }
    }

    // Imprimir tiempo
    printf("Tiempo computo CPU: %f ms\n", mul_elapsedTime);
    printf("FLOPS: %f GFLOPS\n", flops / 1e9);

    // Escribe los tiempos y N en un archivo CSV
    FILE *file = fopen("times.csv", "a");
    if (file == NULL) {
        printf("Error al abrir o crear el archivo times.csv\n");
        free(A);
        free(B);
        free(C);
        return 1;
    }

    // Verifica si el archivo está vacío y escribe el encabezado si es necesario
    fseek(file, 0, SEEK_END);
    if (ftell(file) == 0) {
        fprintf(file, "N,ComputationTime(ms),FLOPS(GFLOPS),CPU,GPU\n");
    }

    // Agrega los datos
    fprintf(file, "%d,%f,%f,1,0\n", N, mul_elapsedTime, flops / 1e9);

    fclose(file);

    // Libera memoria
    free(A);
    free(B);
    free(C);

    return 0;
}
