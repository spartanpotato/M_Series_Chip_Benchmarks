#include <mach/mach_time.h>
#include <stdint.h>

// Gets start time
uint64_t startTimer();

// Gets time passed
double endTimer(uint64_t startTime);