#include "sector.h"
#include "arch/primitives.h"

#define ALPHA_NUM 1u
#define ALPHA_DEN 4u
#define Q16_ONE 65535u
#define FNV_OFFSET_BASIS 0xCBF29CE484222325ULL
#define FNV_PRIME 0x100000001B3ULL

static uint8_t payload[CORE_PAYLOAD_SIZE];

typedef struct scratch_state {
    uint32_t unique_marks[8];
    uint32_t spread_milli;
} scratch_state;

static scratch_state scratch;

static uint32_t u32_min(uint32_t a, uint32_t b) {
    return (a < b) ? a : b;
}

static uint32_t entropy_milli(const uint8_t* data, uint32_t len) {
    uint32_t i;
    uint32_t unique = 0u;
    uint32_t transitions = 0u;
    uint32_t unique_term;
    uint32_t trans_term;
    uint32_t raw;

    if (len == 0u) {
        return 0u;
    }

    for (i = 0u; i < 8u; ++i) {
        scratch.unique_marks[i] = 0u;
    }

    for (i = 0u; i < len; ++i) {
        uint8_t b = core_load_u8(data + i);
        uint32_t slot = ((uint32_t)b) >> 5u;
        uint32_t bit = 1u << (((uint32_t)b) & 31u);
        if ((scratch.unique_marks[slot] & bit) == 0u) {
            scratch.unique_marks[slot] |= bit;
            unique += 1u;
        }
        if (i > 0u) {
            uint8_t p = core_load_u8(data + (i - 1u));
            if (p != b) {
                transitions += 1u;
            }
        }
    }

    unique_term = (unique * 6000u) / 256u;
    trans_term = (len > 1u) ? ((transitions * 2000u) / (len - 1u)) : 0u;
    raw = unique_term + trans_term;
    return u32_min(raw, 8000u) / 8u;
}

static void coherence_update(uint32_t* c_q16, uint32_t c_in_q16, uint32_t* h_q16, uint32_t h_in_q16) {
    uint32_t c_prev = *c_q16;
    uint32_t h_prev = *h_q16;
    *c_q16 = ((ALPHA_DEN - ALPHA_NUM) * c_prev + ALPHA_NUM * c_in_q16) / ALPHA_DEN;
    *h_q16 = ((ALPHA_DEN - ALPHA_NUM) * h_prev + ALPHA_NUM * h_in_q16) / ALPHA_DEN;
}

static uint64_t fnv_step(uint64_t h, uint8_t byte) {
    uint64_t mixed = core_xor_u64(h, (uint64_t)byte);
    return core_mul_u64(mixed, FNV_PRIME);
}

static uint32_t geometric_invariant(uint32_t entropy_q16, uint32_t coherence_q16, const uint8_t* data, uint32_t len) {
    uint32_t i;
    uint32_t spread_sum = 0u;
    uint32_t phi_milli;
    uint32_t spread_milli;
    uint32_t geom_bits_milli = 750u; /* log2(64)=6 -> clamp01(6/8)=0.75 */
    uint32_t base;

    for (i = 0u; i < len; ++i) {
        uint8_t a = core_load_u8(data + i);
        uint8_t b = core_load_u8(data + ((i + 1u) % len));
        uint32_t d = (a > b) ? ((uint32_t)a - (uint32_t)b) : ((uint32_t)b - (uint32_t)a);
        spread_sum += d;
    }

    spread_milli = (spread_sum * 1000u) / (len * 255u);
    scratch.spread_milli = spread_milli;

    {
        uint32_t one_minus_h_milli = ((Q16_ONE - entropy_q16) * 1000u) / Q16_ONE;
        uint32_t c_milli = (coherence_q16 * 1000u) / Q16_ONE;
        phi_milli = (one_minus_h_milli * c_milli) / 1000u;
    }

    base = (300u * phi_milli) + (200u * (1000u - spread_milli)) + (150u * geom_bits_milli);
    return u32_min(base / 1000u, 1000u);
}

static uint32_t crc32_local(const uint8_t* data, uint32_t len) {
    uint32_t crc = 0xFFFFFFFFu;
    uint32_t i;
    uint32_t bit;
    for (i = 0u; i < len; ++i) {
        crc ^= (uint32_t)core_load_u8(data + i);
        for (bit = 0u; bit < 8u; ++bit) {
            uint32_t mask = (uint32_t)(-(int32_t)(crc & 1u));
            crc = (crc >> 1u) ^ (0xEDB88320u & mask);
        }
    }
    return ~crc;
}

static uint64_t xorshift64(uint64_t x) {
    x ^= x << 13u;
    x ^= x >> 7u;
    x ^= x << 17u;
    return x;
}

void run_sector(struct state* s, uint32_t iterations) {
    uint32_t i;
    uint32_t j;
    uint64_t rng;

    if (s == (void*)0) {
        return;
    }

    if (s->hash64 == 0ULL) {
        s->hash64 = FNV_OFFSET_BASIS;
    }
    if (s->coherence_q16 == 0u) {
        s->coherence_q16 = Q16_ONE / 2u;
    }
    if (s->entropy_q16 == 0u) {
        s->entropy_q16 = Q16_ONE / 2u;
    }

    rng = s->hash64 ^ ((uint64_t)s->crc32 << 32u) ^ 0x9E3779B97F4A7C15ULL;

    for (i = 0u; i < iterations; ++i) {
        for (j = 0u; j < CORE_PAYLOAD_SIZE; ++j) {
            rng = xorshift64(rng + (uint64_t)(i + j + 1u));
            core_store_u8(payload + j, (uint8_t)(rng & 0xFFu));
        }

        s->last_entropy_milli = entropy_milli(payload, CORE_PAYLOAD_SIZE);

        for (j = 0u; j < CORE_PAYLOAD_SIZE; ++j) {
            s->hash64 = fnv_step(s->hash64, core_load_u8(payload + j));
        }

        s->crc32 = crc32_local(payload, CORE_PAYLOAD_SIZE);

        {
            uint32_t c_in_q16 = (uint32_t)(((s->hash64 ^ (uint64_t)s->crc32) & 0xFFFFu) * Q16_ONE / 0xFFFFu);
            uint32_t h_in_q16 = (s->last_entropy_milli * Q16_ONE) / 1000u;
            coherence_update(&s->coherence_q16, c_in_q16, &s->entropy_q16, h_in_q16);
        }

        s->last_invariant_milli = geometric_invariant(s->entropy_q16, s->coherence_q16, payload, CORE_PAYLOAD_SIZE);
    }

    s->output_words = CORE_OUTPUT_WORDS;
    s->output[0] = (uint32_t)(s->hash64 & 0xFFFFFFFFu);
    s->output[1] = (uint32_t)((s->hash64 >> 32u) & 0xFFFFFFFFu);
    s->output[2] = s->crc32;
    s->output[3] = s->coherence_q16;
    s->output[4] = s->entropy_q16;
    s->output[5] = s->last_entropy_milli;
    s->output[6] = s->last_invariant_milli;
    s->output[7] = scratch.spread_milli;
}
