#include <stdint.h>

#include "dev.h"

void main(void) {
    uint32_t x = 0b10101010;
    gpio_a->out = x;
    *(mem+0) = x;
    *(mem+1) = x;
}