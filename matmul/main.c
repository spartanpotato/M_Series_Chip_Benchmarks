#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <getopt.h>  // Include getopt_long

int main(int argc, char *argv[]) {
    int n = -1;
    char *hardware = NULL;
    int precision = -1;
    int check = -1;
    int iterations = 1;
    int checkInstantEnergy = -1;
    int checkEnergyOverTime = -1;

    // Define long options
    struct option long_options[] = {
        {"n", required_argument, NULL, 'n'},
        {"hardware", required_argument, NULL, 'h'},
        {"precision", required_argument, NULL, 'p'},
        {"check", required_argument, NULL, 'c'},
        {"instantEnergy", required_argument, NULL, 'e'},
        {"energyOverTime", required_argument, NULL, 't'},
        {"iterations", required_argument, NULL, 'i'},
        {0, 0, 0, 0} // End of options
    };

    int opt;
    while ((opt = getopt_long(argc, argv, "n:h:p:c:e:t:i:", long_options, NULL)) != -1) {
        switch (opt) {
            case 'n':
                n = atoi(optarg);
                if (n <= 0) {
                    fprintf(stderr, "Invalid n, must be positive integer.\n");
                    return 1;
                }
                break;
            case 'h':
                hardware = optarg;
                if (strcmp(hardware, "cpu") != 0 && strcmp(hardware, "gpu") != 0) {
                    fprintf(stderr, "Invalid hardware option. Choose 'cpu' or 'gpu'.\n");
                    return 1;
                }
                break;
            case 'p':
                precision = atoi(optarg);
                if (precision != 16 && precision != 32 && precision != 64) {
                    fprintf(stderr, "Invalid precision. Choose 16, 32, or 64.\n");
                    return 1;
                }
                break;
            case 'c':
                check = atoi(optarg);
                if (check != 0 && check != 1) {
                    fprintf(stderr, "Invalid check. Choose 1 or 0.\n");
                    return 1;
                }
                break;
            case 'e':
                checkInstantEnergy = atoi(optarg);
                if (checkInstantEnergy != 0 && checkInstantEnergy != 1) {
                    fprintf(stderr, "Invalid checkInstantEnergy. Choose 1 or 0.\n");
                    return 1;
                }
                break;
            case 't':
                checkEnergyOverTime = atoi(optarg);
                if (checkEnergyOverTime != 0 && checkEnergyOverTime != 1) {
                    fprintf(stderr, "Invalid checkEnergyOverTime. Choose 1 or 0.\n");
                    return 1;
                }
                break;
            case 'i':
                iterations = atoi(optarg);
                if (iterations <= 0) {
                    fprintf(stderr, "Invalid iterations. Choose positive integer.\n");
                    return 1;
                }
                break;
            case '?':
                printf("Usage: ./prog --n <value> --hardware <cpu|gpu> --precision <16|32|64> --check <1|0>\n --energy <1|0> --iterations <value>\n");
                return 1;
            default:
                printf("Usage: ./prog --n <value> --hardware <cpu|gpu> --precision <16|32|64> --check <1|0>\n --energy <1|0> --iterations <value>\n");
                return 1;
        }
    }

    if (n == -1 || hardware == NULL || precision == -1 || check == -1 || checkInstantEnergy == -1) {
        fprintf(stderr, "Error: Missing required parameters.\n");
        printf("Usage: ./prog --n <value> --hardware <cpu|gpu> --precision <16|32|64> --check <1|0>\n --instantEnergy <1|0> --energyOverTime <1|0> --iterations <value>\n");
        return 1;
    }

    if (checkInstantEnergy == 1 && checkEnergyOverTime == 1) {
        fprintf(stderr, "Error: Cannot measure energy over time and instant energy at the same time.\n");
        return 1;
    }

    char commandBuffer[1024];
    snprintf(commandBuffer, 1024, "./%s/%dbits/matmul %d %d %d %d %d", hardware, precision, n, check, checkInstantEnergy, checkEnergyOverTime, iterations);
    printf("Command: %s\n", commandBuffer);

    // for(int i = 0; i < iterations; i++) {
    system(commandBuffer);
    // }
    

    return 0;
}

