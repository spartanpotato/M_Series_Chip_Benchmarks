#include <stdio.h>
#include <stdlib.h>
#include <Accelerate/Accelerate.h>
#include <time.h>
#include "../../utils/Verify.h"

// Matrix generator
void generate_random_matrix(float *matrix, int size) {
    for (int i = 0; i < size * size; i++) {
        matrix[i] = (float)rand() / RAND_MAX;
    }
}

int main(int argc, char *argv[]) {
    if (argc != 6) {
        printf("Must be executed as ./matmul N checkResult checkEnergyOverTime checkInstantEnergy iterations");
        return 1;
    }

    int N = atoi(argv[1]);
    if (N <= 0) {
        printf("N must be a positive integer");
        return 1;
    }

    int checkResult = atoi(argv[2]);
    int checkInstantEnergy = atoi(argv[3]);
    int checkEnergyOverTime = atoi(argv[4]);
    int iterations = atoi(argv[5]);

    char energy_over_time_cmd[1024];
    char instant_energy_cmd[1024];
    snprintf(energy_over_time_cmd, sizeof(energy_over_time_cmd), "sudo powermetrics -i 1 --sampler cpu_power | grep -E 'elapsed|CPU Power' | sed 'N;s/$/\\nN=%d/' >> ./outputs/csvs/cpu_over_time_32bits.csv &", N);
    snprintf(instant_energy_cmd, sizeof(instant_energy_cmd), "sudo powermetrics -i 1 --sampler cpu_power | grep -E 'CPU Power' | sed 'N;s/$/\\nN=%d/' >> ./outputs/csvs/cpu_instant_32bits.csv &", N);


    // Allocates memory
    float *A = (float *)malloc(N * N * sizeof(float));
    float *B = (float *)malloc(N * N * sizeof(float));
    float *C = (float *)malloc(N * N * sizeof(float));
    if (!A || !B || !C) {
        printf("Error allocating memory");
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

    // Starts measuring energy usage over time if flag is true


    // Starts measuring instant energy usage if flag is true
    if (checkInstantEnergy == 1){
        system(instant_energy_cmd);
    }

    if(checkEnergyOverTime == 1){
        system(energy_over_time_cmd);
    }

    sleep(1);
    

    // Matmul
    for(int i = 0; i < iterations; i++){
        cblas_sgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans,
                N, N, N, 
                1.0, A, N, B, N, 
                0.0, C, N);
    }

    // Ends energy measurement
    if(checkEnergyOverTime == 1 || checkInstantEnergy == 1){
        // Kills command stop measuring power usage
        system("sudo pkill -f 'powermetrics'");
    }

    // Ends time measurement
    clock_gettime(CLOCK_MONOTONIC, &end_mul);

    // Calculates time 
    long mul_seconds = end_mul.tv_sec - start_mul.tv_sec;
    long mul_nanoseconds = end_mul.tv_nsec - start_mul.tv_nsec;
    double mul_elapsedTime = mul_seconds * 1000.0 + mul_nanoseconds / 1000000.0;
    mul_elapsedTime = mul_elapsedTime - 1000; // Take away the second used in sleep

    // Calculates FLOPS
    double flops = (iterations * 2.0 * N * N * N) / (mul_elapsedTime / 1000);

    // Divide time by iterations
    mul_elapsedTime = mul_elapsedTime / iterations;

    // Verifies result if flag is true
    if(checkResult == 1){
        bool isCorrect = verify_matrix_product(A, B, C, N, N, N);
        if (isCorrect){
            printf("Result was correct\n");
        }
    }

    // Prints time
    printf("Tiempo computo CPU: %f ms\n", mul_elapsedTime);
    printf("FLOPS: %f GFLOPS\n", flops / 1e9);

    // Writes the times and dimensions to a CSV file
    FILE *file = fopen("./outputs/csvs/times.csv", "a");
    if (file == NULL) {
        printf("Error opening times.csv\n");
        free(A);
        free(B);
        free(C);
        return 1;
    }

    if(checkEnergyOverTime == 0){
        // Checks if the file is empty and writes the header if necessary
        fseek(file, 0, SEEK_END);
        if (ftell(file) == 0) {
            fprintf(file, "N,ComputationTime(ms),FLOPS(GFLOPS),CPU,GPU,Presicion\n");
        }

        // Adds data
        fprintf(file, "%d,%f,%f,1,0,32\n", N, mul_elapsedTime, flops / 1e9);

        fclose(file);
    }

    // Frees memory
    free(A);
    free(B);
    free(C);

    return 0;
}
