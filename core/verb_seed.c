#include "verb_seed.h"

#define FNV_OFFSET_BASIS 0xCBF29CE484222325ULL
#define FNV_PRIME 0x100000001B3ULL
#define GOLDEN64 0x9E3779B97F4A7C15ULL

static uint8_t ascii_lower(uint8_t c) {
    if (c >= (uint8_t)'A' && c <= (uint8_t)'Z') {
        return (uint8_t)(c + 32u);
    }
    return c;
}

uint64_t verb_seed_hash64(const char* verb, size_t len) {
    uint64_t h = FNV_OFFSET_BASIS;
    size_t i;

    if (verb == (void*)0 || len == 0u) {
        return h ^ GOLDEN64;
    }

    for (i = 0u; i < len; ++i) {
        uint8_t b = ascii_lower((uint8_t)verb[i]);
        h ^= (uint64_t)b;
        h *= FNV_PRIME;
    }

    h ^= ((uint64_t)len * GOLDEN64);
    h ^= (h >> 33u);
    h *= 0xff51afd7ed558ccdULL;
    h ^= (h >> 29u);
    return h;
}

void verb_seed_state(struct state* s, const char* verb, size_t len, uint32_t salt) {
    uint64_t seed;

    if (s == (void*)0) {
        return;
    }

    seed = verb_seed_hash64(verb, len) ^ ((uint64_t)salt * GOLDEN64);

    s->hash64 = seed;
    s->crc32 = (uint32_t)((seed >> 32u) ^ (seed & 0xFFFFFFFFu) ^ salt);
    s->coherence_q16 = (uint32_t)(15000u + (seed & 0x7FFFu));
    s->entropy_q16 = (uint32_t)(12000u + ((seed >> 15u) & 0x7FFFu));
    s->last_entropy_milli = 0u;
    s->last_invariant_milli = 0u;
    s->output_words = 0u;
    s->reserved = 0u;

    {
        uint32_t i;
        for (i = 0u; i < CORE_OUTPUT_WORDS; ++i) {
            s->output[i] = 0u;
        }
    }
}
