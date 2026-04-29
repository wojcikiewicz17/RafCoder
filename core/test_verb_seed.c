#include "verb_seed.h"

#include <stdio.h>
#include <string.h>

static int assert_true(int cond, const char* msg) {
    if (!cond) {
        fprintf(stderr, "%s\n", msg);
        return 1;
    }
    return 0;
}

int main(void) {
    struct state a = {0};
    struct state b = {0};
    uint64_t h1 = verb_seed_hash64("Seed", 4u);
    uint64_t h2 = verb_seed_hash64("seed", 4u);

    if (assert_true(h1 == h2, "case-insensitive hash mismatch") != 0) {
        return 1;
    }

    verb_seed_state(&a, "seed", strlen("seed"), 42u);
    verb_seed_state(&b, "grow", strlen("grow"), 42u);

    if (assert_true(a.hash64 != b.hash64, "different verbs produced identical hash") != 0) {
        return 1;
    }

    run_sector(&a, 3u);
    run_sector(&b, 3u);

    if (assert_true(a.output_words == CORE_OUTPUT_WORDS, "invalid output words for state a") != 0) {
        return 1;
    }
    if (assert_true(b.output_words == CORE_OUTPUT_WORDS, "invalid output words for state b") != 0) {
        return 1;
    }
    if (assert_true(a.output[0] != b.output[0], "state transition collision detected") != 0) {
        return 1;
    }

    puts("ok");
    return 0;
}
