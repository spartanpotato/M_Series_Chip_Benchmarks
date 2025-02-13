#include "TimeUtils.h"

// Gets start time
uint64_t startTimer() {
    return mach_absolute_time();
}

// Gets time passed
double endTimer(uint64_t startTime) {
    uint64_t endTime = mach_absolute_time();
    mach_timebase_info_data_t timebase;
    mach_timebase_info(&timebase);

    // Converts to nanoseconds
    uint64_t elapsed = (endTime - startTime) * timebase.numer / timebase.denom;

    // Returns miliseconds
    return elapsed / 1e6;
}