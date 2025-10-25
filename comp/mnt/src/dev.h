#ifndef _DEV_H_
#define _DEV_H_

#define DEV_GPIO_A 0x400
#define DEV_MEM    0x1000
#define DEV_MEMEND 0x1fff

struct gpio {
    uint32_t out; 
};

struct gpio * const gpio_a = (struct gpio *) DEV_GPIO_A;
uint32_t * const mem = (uint32_t *) DEV_MEM;

#endif /* _DEV_H_ */