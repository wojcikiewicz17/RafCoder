#ifndef CORE_SECTOR_H
#define CORE_SECTOR_H

#include <stddef.h>
#include <stdint.h>

#define CORE_PAYLOAD_SIZE 32u
#define CORE_OUTPUT_WORDS 8u

/*
 * Public state contract for run_sector().
 *
 * Invariants:
 * - s != NULL.
 * - output_words is always clamped to CORE_OUTPUT_WORDS by run_sector().
 * - output[] is a fixed-width externally consumable payload.
 *
 * Field semantics:
 * - coherence_q16 / entropy_q16: fixed-point Q16 quality metrics.
 * - hash64: rolling 64-bit state hash.
 * - crc32: rolling checksum over state transitions.
 * - last_entropy_milli / last_invariant_milli: last computed milli-scaled probes.
 * - output_words: number of valid u32 words in output[] (0..CORE_OUTPUT_WORDS).
 * - reserved: reserved for ABI-compatible future expansion (must be preserved by callers).
 * - output[]: deterministic derived output vector with CORE_OUTPUT_WORDS entries.
 */
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

/*
 * Minimal public core API.
 *
 * Inputs:
 * - s: mutable state pointer following struct state contract above.
 * - iterations: number of transition rounds to execute.
 *
 * Outputs:
 * - Updates all mutable fields of *s deterministically for the same input state
 *   and iteration count.
 *
 * Contract:
 * - Reentrant when each thread/task uses its own state instance.
 * - Does not allocate dynamic memory.
 * - Does not require platform-specific caller setup.
 */
void run_sector(struct state* s, uint32_t iterations);

#endif
