#include <mach/mach_time.h>
#include <stdint.h>

// Funcion para obetenr tiempo de inicio
uint64_t startTimer();

// Funcion para obtener tiempo transcurrido
double endTimer(uint64_t startTime);