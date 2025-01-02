#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

int main(int argc, char *argv[]) {
    int n= -1;
    char *hardware = NULL;
    int precision = -1;
    int check = -1;

    int opt;
    while ((opt = getopt(argc, argv, "n:h:p:c:")) != -1) {
        switch (opt) {
            case 'n':
                n = atoi(optarg);
                if (n <= 0){
                    fprintf(stderr, "Invalid n, must be positive integer.\n");
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
            case '?':
                printf("Usage: ./prog -n <value> -h <cpu|gpu> -p <16|32|64> -c <1|0>\n");
                return 1;
            default:
                printf("Usage: ./prog -n <value> -hw <cpu|gpu> -p <16|32|64> -c <1|0>\n");
                return 1;
        }
    }

    if (n == -1 || hardware == NULL || precision == -1 || check == -1) {
        fprintf(stderr, "Error: Missing required parameters.\n");
        printf("Usage: ./prog -n <value> -hw <cpu|gpu> -p <16|32|64> -c <1|0>\n");
        return 1;
    }

    char commandBuffer[1024];
    snprintf(commandBuffer, 1024, "./%s/%dbits/matmul %d %d", hardware, precision, n, check);
    printf("Command: %s\n", commandBuffer);
    system(commandBuffer);


    return 0;
}
