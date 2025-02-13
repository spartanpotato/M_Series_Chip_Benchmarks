#include "Conversion.h"

unsigned short floatToHalf(float f) {
    uint32_t fbits = *((uint32_t*)&f);  // Extract the bits of the float
    uint32_t sign = (fbits >> 31) & 0x1;  // Extract the sign bit
    uint32_t exp = (fbits >> 23) & 0xFF;  // Extract the exponent bits
    uint32_t frac = fbits & 0x7FFFFF;  // Extract the fraction bits

    unsigned short hbits = 0;

    // Handle special cases for NaN, infinity, and zero
    if (exp == 0xFF) {
        if (frac != 0) {
            // NaN: Set exponent to 0x1F and fraction to whatever is left
            hbits = (sign << 15) | 0x7C00 | (frac >> 13);
        } else {
            // Infinity: Set exponent to 0x1F and fraction to 0
            hbits = (sign << 15) | 0x7C00;
        }
    } else if (exp == 0) {
        // Subnormal or zero
        if (frac == 0) {
            // Zero
            hbits = (sign << 15);
        } else {
            // Subnormal numbers: adjust exponent and shift fraction
            exp = 0x71;
            while ((frac & 0x800000) == 0) {
                frac <<= 1;
                --exp;
            }
            frac &= ~0x800000;  // Clear the leading 1 of the fraction
            hbits = (sign << 15) | (exp << 10) | (frac >> 13);
        }
    } else {
        // Normalized number: adjust exponent for half precision
        exp -= 112;  // Shift exponent for 16-bit precision
        hbits = (sign << 15) | (exp << 10) | (frac >> 13);
    }

    return hbits;
}

float halfToFloat(unsigned short hbits) {
    uint32_t sign = (hbits >> 15) & 0x1;  // Extract the sign bit
    uint32_t exp = (hbits >> 10) & 0x1F;  // Extract the exponent bits
    uint32_t frac = hbits & 0x3FF;  // Extract the fraction bits

    uint32_t fbits = 0;

    if (exp == 0x1F) {
        // NaN or infinity
        fbits = (sign << 31) | 0x7F800000 | (frac << 13);
    } else if (exp == 0) {
        // Subnormal or zero
        if (frac == 0) {
            // Zero
            fbits = (sign << 31);
        } else {
            // Subnormal number: adjust exponent and shift fraction
            exp = 1;
            while ((frac & 0x200) == 0) {
                frac <<= 1;
                --exp;
            }
            fbits = (sign << 31) | ((exp + 112) << 23) | (frac << 13);
        }
    } else {
        // Normalized number
        fbits = (sign << 31) | ((exp + 112) << 23) | (frac << 13);
    }

    return *((float*)&fbits);  // Return the final float value
}