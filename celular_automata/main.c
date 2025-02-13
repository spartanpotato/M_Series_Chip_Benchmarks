#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <getopt.h>  // Include getopt_long

int main(int argc, char *argv[]) {
    int n = -1;
    char *hardware = NULL;
    char *memoryAccess = NULL;
    int radius = -1;
    int iterations = 1;
    int checkInstantEnergy = -1;
    int checkEnergyOverTime = -1;

    // Define long options
    struct option long_options[] = {
        {"n", required_argument, NULL, 'n'},
        {"radius", required_argument, NULL, 'r'},
        {"memoryAccess", required_argument, NULL, 'm'},
        {"instantEnergy", required_argument, NULL, 'e'},
        {"energyOverTime", required_argument, NULL, 't'},
        {"iterations", required_argument, NULL, 'i'},
        {0, 0, 0, 0} // End of options
    };

    int opt;
    while ((opt = getopt_long(argc, argv, "n:r:m:e:t:i:", long_options, NULL)) != -1) {
        switch (opt) {
            case 'n':
                n = atoi(optarg);
                if (n <= 0) {
                    fprintf(stderr, "Invalid n, must be positive integer.\n");
                    return 1;
                }
                break;
            case 'r':
                radius = atoi(optarg);
                if (radius <= 0) {
                    fprintf(stderr, "Invalid radius, must be positive integer.\n");
                    return 1;
                }
                break;
            case 'm':
                memoryAccess = optarg;
                if (strcmp(memoryAccess, "shared") != 0 && 
                    strcmp(memoryAccess, "managed") != 0 &&
                    strcmp(memoryAccess, "private") != 0) {
                    fprintf(stderr, "Invalid hardware option. valid options are shared, managed, or private.\n");
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
                printf("Usage: ./prog --n <value> --radius <value> --memoryAccess <shared|managed|private> --instantEnergy <1|0> --energyOverTime <1|0> --iterations <value>\n");
                return 1;
            default:
                printf("Usage: ./prog --n <value> --radius <value> --memoryAccess <shared|managed|private> --instantEnergy <1|0> --energyOverTime <1|0> --iterations <value>\n");
                return 1;
        }
    }

    if (n == -1 || radius == -1 || memoryAccess == NULL || checkInstantEnergy == -1 || checkEnergyOverTime == -1){
        fprintf(stderr, "Error: Missing required parameters.\n");
        printf("Usage: ./prog --n <value> --radius <value> --memoryAccess <shared|managed|private> --instantEnergy <1|0> --energyOverTime <1|0> --iterations <value>\n");
        return 1;
    }

    if (checkInstantEnergy == 1 && checkEnergyOverTime == 1) {
        fprintf(stderr, "Error: Cannot measure energy over time and instant energy at the same time.\n");
        return 1;
    }

    char commandBuffer[1024];
    snprintf(commandBuffer, 1024, "./%s_memory/build/prog %d %d %d %d %d", memoryAccess, n, radius, iterations, checkInstantEnergy, checkEnergyOverTime);
    printf("Command: %s\n", commandBuffer);

    // for(int i = 0; i < iterations; i++) {
    system(commandBuffer);
    // }
    

    return 0;
}

