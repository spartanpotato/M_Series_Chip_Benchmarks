#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#define command "sudo powermetrics -i 10 --sampler cpu_power | while read line; do echo \"$(gdate '+%H:%M:%S.%3N'),$line\"; done | grep -E \"CPU Power|GPU Power\" | awk -F': ' '{print $1 \",\" $2}' >> power_metrics_cpu.csv &"

// Function to execute the energy sampling command
void executeEnergySampling(int seconds) {
    // Execute the command
    system(command);

    sleep(seconds);

    system("sudo pkill -f 'powermetrics -i 1 --sampler cpu_power'");
}

int main(int argc, char **argv) {
    int seconds;

    // Takes args
    if (argc != 2) {
        fprintf(stderr, "Must be executed ./power_sampling seconds");
        return 1;
    }

    seconds = atoi(argv[1]);

    if (seconds <= 1){
        fprintf(stderr, "Seconds must be a positive integer");
        return 1;
    }

    printf("Sampling energy for %d seconds...\n", seconds);

    // Call the function to execute the system command
    executeEnergySampling(seconds);

    printf("Done\n");

    return 0;
}