#include "sector.h"

#include <pthread.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define THREADS 8u
#define ITERS 80u
#define RUN_ITERS 128u

typedef struct thread_ctx {
    state st;
    uint32_t seed;
    uint32_t snapshot[CORE_OUTPUT_WORDS];
} thread_ctx;

static void seed_state(state* st, uint32_t seed) {
    memset(st, 0, sizeof(*st));
    st->hash64 = 0xCBF29CE484222325ULL ^ ((uint64_t)seed * 0x9E3779B97F4A7C15ULL);
    st->crc32 = seed * 2654435761u;
    st->coherence_q16 = 1000u + (seed * 997u % 64000u);
    st->entropy_q16 = 2000u + (seed * 313u % 62000u);
}

static void* run_thread(void* arg) {
    thread_ctx* ctx = (thread_ctx*)arg;
    uint32_t i;

    seed_state(&ctx->st, ctx->seed);
    for (i = 0u; i < ITERS; ++i) {
        run_sector(&ctx->st, RUN_ITERS);
    }
    memcpy(ctx->snapshot, ctx->st.output, sizeof(ctx->snapshot));
    return NULL;
}

int main(void) {
    pthread_t th[THREADS];
    thread_ctx ctx[THREADS];
    thread_ctx baseline[THREADS];
    uint32_t i;

    for (i = 0u; i < THREADS; ++i) {
        ctx[i].seed = 111u + i * 17u;
        if (pthread_create(&th[i], NULL, run_thread, &ctx[i]) != 0) {
            fprintf(stderr, "pthread_create failed for thread %u\n", i);
            return 1;
        }
    }

    for (i = 0u; i < THREADS; ++i) {
        if (pthread_join(th[i], NULL) != 0) {
            fprintf(stderr, "pthread_join failed for thread %u\n", i);
            return 1;
        }
    }

    for (i = 0u; i < THREADS; ++i) {
        baseline[i].seed = ctx[i].seed;
        run_thread(&baseline[i]);

        if (memcmp(ctx[i].snapshot, baseline[i].snapshot, sizeof(ctx[i].snapshot)) != 0) {
            fprintf(stderr, "non-reentrant output mismatch for seed %u\n", ctx[i].seed);
            return 1;
        }
    }

    for (i = 0u; i < THREADS; ++i) {
        uint32_t j;
        for (j = i + 1u; j < THREADS; ++j) {
            if (memcmp(ctx[i].snapshot, ctx[j].snapshot, sizeof(ctx[i].snapshot)) == 0) {
                fprintf(stderr, "unexpected output collision for seeds %u and %u\n", ctx[i].seed, ctx[j].seed);
                return 1;
            }
        }
    }

    printf("ok\n");
    return 0;
}
