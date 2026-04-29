#include "sector.h"

#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

static int check_u32(const char* field, uint32_t actual, uint32_t expected) {
    if (actual != expected) {
        fprintf(stderr, "%s mismatch: expected=%" PRIu32 " actual=%" PRIu32 "\n", field, expected, actual);
        return 1;
    }
    return 0;
}

static int check_u64(const char* field, uint64_t actual, uint64_t expected) {
    if (actual != expected) {
        fprintf(stderr, "%s mismatch: expected=%" PRIu64 " actual=%" PRIu64 "\n", field, expected, actual);
        return 1;
    }
    return 0;
}

int main(void) {
    state s = {0};
    int failed = 0;
    size_t i;

    static const uint64_t expected_hash64 = 18181756079169303449ULL;
    static const uint32_t expected_crc32 = 2324013866u;
    static const uint32_t expected_coherence_q16 = 38567u;
    static const uint32_t expected_entropy_q16 = 22097u;
    static const uint32_t expected_last_entropy_milli = 343u;
    static const uint32_t expected_last_invariant_milli = 346u;
    static const uint32_t expected_output_words = CORE_OUTPUT_WORDS;
    static const uint32_t expected_output[CORE_OUTPUT_WORDS] = {
        2880402329u,
        4233269970u,
        2324013866u,
        38567u,
        22097u,
        343u,
        346u,
        412u,
    };

    run_sector(&s, 42u);

    failed |= check_u64("hash64", s.hash64, expected_hash64);
    failed |= check_u32("crc32", s.crc32, expected_crc32);
    failed |= check_u32("coherence_q16", s.coherence_q16, expected_coherence_q16);
    failed |= check_u32("entropy_q16", s.entropy_q16, expected_entropy_q16);
    failed |= check_u32("last_entropy_milli", s.last_entropy_milli, expected_last_entropy_milli);
    failed |= check_u32("last_invariant_milli", s.last_invariant_milli, expected_last_invariant_milli);
    failed |= check_u32("output_words", s.output_words, expected_output_words);

    for (i = 0u; i < CORE_OUTPUT_WORDS; ++i) {
        if (s.output[i] != expected_output[i]) {
            fprintf(stderr,
                    "output[%zu] mismatch: expected=%" PRIu32 " actual=%" PRIu32 "\n",
                    i,
                    expected_output[i],
                    s.output[i]);
            failed = 1;
        }
    }

    if (failed) {
        return 1;
    }

    puts("ok");
    return 0;
}
