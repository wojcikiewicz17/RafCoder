#ifndef CORE_SECTOR_H
#define CORE_SECTOR_H

#include <stddef.h>
#include <stdint.h>

#define CORE_PAYLOAD_SIZE 32u
#define CORE_OUTPUT_WORDS 8u

typedef struct state {
    uint32_t coherence_q16;
    uint32_t entropy_q16;
    uint64_t hash64;
    uint32_t crc32;
    uint32_t last_entropy_milli;
    uint32_t last_invariant_milli;
    uint32_t output_words;
    uint32_t reserved;
    uint32_t output[CORE_OUTPUT_WORDS];
} state;

void run_sector(struct state* s, uint32_t iterations);

#endif
