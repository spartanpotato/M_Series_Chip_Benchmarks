#include "TimeUtils.h"

// Funcion para obetener tiempo de inicio
uint64_t startTimer() {
    return mach_absolute_time();
}

// Funcion para obtener tiempo transcurrido
double endTimer(uint64_t startTime) {
    uint64_t endTime = mach_absolute_time();
    mach_timebase_info_data_t timebase;
    mach_timebase_info(&timebase);

    // Convertir tiempo a nanosegundos
    uint64_t elapsed = (endTime - startTime) * timebase.numer / timebase.denom;

    // Regresar tiempo en milisengudos
    return elapsed / 1e6;
}