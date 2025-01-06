#include <stdio.h>
#include <stdlib.h>
#include <Accelerate/Accelerate.h>
#include <time.h>
#include "../../Verify.h"

// Matrix generator
void generate_random_matrix(float *matrix, int size) {
    for (int i = 0; i < size * size; i++) {
        matrix[i] = (float)rand() / RAND_MAX;
    }
}

int main(int argc, char *argv[]) {
    if (argc != 4) {
        printf("Se debe ejecutar como ./matmul N checkResult checkEnergy");
        return 1;
    }

    int N = atoi(argv[1]);
    if (N <= 0) {
        printf("N debe ser entero positivo");
        return 1;
    }

    int checkResult = atoi(argv[2]);
    int checkEnergy = atoi(argv[3]);

    // Allocates memory
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

    // Generates input matrices
    generate_random_matrix(A, N);
    generate_random_matrix(B, N);

    // Starts measuring time
    clock_gettime(CLOCK_MONOTONIC, &start_mul);

    // Starts measuring energy usage if flag is true
    if(checkEnergy == 1){
        // Call a shell command using system() to store energy usage
        system("sudo powermetrics -i 10 --sampler cpu_power | while read line; do echo \"$(gdate '+%H:%M:%S.%3N'),$line\"; done | grep -E \"CPU Power|GPU Power\" | awk -F': ' '{print $1 \",\" $2}' >> power_metrics_cpu.csv &");
    }

    // Matmul
    cblas_sgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans,
                N, N, N, 
                1.0, A, N, B, N, 
                0.0, C, N);

    // Ends energy measurement
    if(checkEnergy == 1){
        // Kills command stop measuring power usage
        system("sudo pkill -f 'powermetrics'");
    }

    // Ends time measurement
    clock_gettime(CLOCK_MONOTONIC, &end_mul);

    // Calculates time 
    long mul_seconds = end_mul.tv_sec - start_mul.tv_sec;
    long mul_nanoseconds = end_mul.tv_nsec - start_mul.tv_nsec;
    double mul_elapsedTime = mul_seconds * 1000.0 + mul_nanoseconds / 1000000.0;


    // Calculates FLOPS
    double flops = (2.0 * N * N * N) / (mul_elapsedTime / 1000);

    // Verifies result if flag is true
    if(checkResult == 1){
        bool isCorrect = verify_matrix_product(A, B, C, N, N, N);
        if (isCorrect){
            printf("El calculo fue correcto\n");
        }
    }

    // Prints time
    printf("Tiempo computo CPU: %f ms\n", mul_elapsedTime);
    printf("FLOPS: %f GFLOPS\n", flops / 1e9);

    // Writes the times and dimensions to a CSV file
    FILE *file = fopen("times.csv", "a");
    if (file == NULL) {
        printf("Error al abrir o crear el archivo times.csv\n");
        free(A);
        free(B);
        free(C);
        return 1;
    }

    // Checks if the file is empty and writes the header if necessary
    fseek(file, 0, SEEK_END);
    if (ftell(file) == 0) {
        fprintf(file, "N,ComputationTime(ms),FLOPS(GFLOPS),CPU,GPU\n");
    }

    // Adds data
    fprintf(file, "%d,%f,%f,1,0\n", N, mul_elapsedTime, flops / 1e9);

    fclose(file);

    // Frees memory
    free(A);
    free(B);
    free(C);

    return 0;
}
