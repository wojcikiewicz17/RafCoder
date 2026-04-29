#include "primitives.h"

#if !defined(__x86_64__) && !defined(__aarch64__) && !defined(__arm__)
uint64_t core_xor_u64(uint64_t a, uint64_t b) {
    return a ^ b;
}

uint64_t core_mul_u64(uint64_t a, uint64_t b) {
    return a * b;
}

uint64_t core_rotl_u64(uint64_t x, uint32_t shift) {
    uint32_t s = shift & 63u;
    if (s == 0u) {
        return x;
    }
    return (x << s) | (x >> (64u - s));
}

uint8_t core_load_u8(const uint8_t* ptr) {
    return *ptr;
}

void core_store_u8(uint8_t* ptr, uint8_t value) {
    *ptr = value;
}

void core_xor_block(uint8_t* dst, const uint8_t* src, size_t len) {
    size_t i;
    for (i = 0; i < len; ++i) {
        dst[i] ^= src[i];
    }
}
#endif
