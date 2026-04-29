#include "arch/primitives.h"

#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

static uint64_t ref_rotl64(uint64_t x, uint32_t shift) {
    uint32_t s = shift & 63u;
    if (s == 0u) {
        return x;
    }
    return (x << s) | (x >> (64u - s));
}

static int check_u64(const char* name, uint64_t actual, uint64_t expected) {
    if (actual != expected) {
        fprintf(stderr,
                "%s mismatch: expected=0x%016" PRIx64 " actual=0x%016" PRIx64 "\n",
                name,
                expected,
                actual);
        return 1;
    }
    return 0;
}

static int check_u8(const char* name, uint8_t actual, uint8_t expected) {
    if (actual != expected) {
        fprintf(stderr,
                "%s mismatch: expected=0x%02" PRIx8 " actual=0x%02" PRIx8 "\n",
                name,
                expected,
                actual);
        return 1;
    }
    return 0;
}

int main(void) {
    static const uint64_t values[] = {
        0x0000000000000000ULL,
        0x0000000000000001ULL,
        0x0123456789ABCDEFULL,
        0xFEDCBA9876543210ULL,
        0xFFFFFFFFFFFFFFFFULL,
        0x8000000000000000ULL,
    };
    static const uint32_t shifts[] = {0u, 1u, 7u, 8u, 13u, 31u, 32u, 33u, 47u, 63u, 64u, 65u};

    uint8_t dst[32];
    uint8_t src[32];
    uint8_t expected[32];
    int failed = 0;
    size_t i;
    size_t j;

    for (i = 0u; i < sizeof(values) / sizeof(values[0]); ++i) {
        for (j = 0u; j < sizeof(values) / sizeof(values[0]); ++j) {
            uint64_t a = values[i];
            uint64_t b = values[j];
            failed |= check_u64("core_xor_u64", core_xor_u64(a, b), a ^ b);
            failed |= check_u64("core_mul_u64", core_mul_u64(a, b), a * b);
        }
    }

    for (i = 0u; i < sizeof(values) / sizeof(values[0]); ++i) {
        for (j = 0u; j < sizeof(shifts) / sizeof(shifts[0]); ++j) {
            char label[64];
            uint64_t actual = core_rotl_u64(values[i], shifts[j]);
            uint64_t expected_rot = ref_rotl64(values[i], shifts[j]);
            snprintf(label, sizeof(label), "core_rotl_u64[%zu,%zu]", i, j);
            failed |= check_u64(label, actual, expected_rot);
        }
    }

    for (i = 0u; i < sizeof(dst); ++i) {
        dst[i] = (uint8_t)(0xA5u ^ (uint8_t)i);
        src[i] = (uint8_t)(0x3Cu + (uint8_t)(i * 7u));
        expected[i] = dst[i] ^ src[i];
    }

    core_xor_block(dst, src, sizeof(dst));
    if (memcmp(dst, expected, sizeof(dst)) != 0) {
        fprintf(stderr, "core_xor_block mismatch\n");
        return 1;
    }

    {
        uint8_t slot = 0u;
        core_store_u8(&slot, 0x5Au);
        failed |= check_u8("core_store_u8/core_load_u8", core_load_u8(&slot), 0x5Au);
    }

    if (failed) {
        return 1;
    }

    puts("ok");
    return 0;
}
