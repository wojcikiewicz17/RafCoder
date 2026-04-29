#define _POSIX_C_SOURCE 200809L
#include "sector.h"

#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#define BENCH_WARMUP_RUNS 8u
#define BENCH_SAMPLE_RUNS 32u

static uint64_t now_ns(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ((uint64_t)ts.tv_sec * 1000000000ULL) + (uint64_t)ts.tv_nsec;
}

static void usage(const char* argv0) {
    fprintf(stderr, "Usage: %s [--iterations N] [--format csv|json]\n", argv0);
}

int main(int argc, char** argv) {
    uint32_t iterations = 1000u;
    const char* format = "csv";
    uint64_t samples[BENCH_SAMPLE_RUNS];
    uint64_t min_ns;
    uint64_t max_ns;
    uint64_t sum_ns = 0ULL;
    state s = {0};
    uint32_t i;

    for (i = 1u; i < (uint32_t)argc; ++i) {
        if (strcmp(argv[i], "--iterations") == 0) {
            if ((i + 1u) >= (uint32_t)argc) {
                usage(argv[0]);
                return 2;
            }
            iterations = (uint32_t)strtoul(argv[i + 1], (char**)0, 10);
            i += 1u;
        } else if (strcmp(argv[i], "--format") == 0) {
            if ((i + 1u) >= (uint32_t)argc) {
                usage(argv[0]);
                return 2;
            }
            format = argv[i + 1];
            i += 1u;
        } else {
            usage(argv[0]);
            return 2;
        }
    }

    if ((strcmp(format, "csv") != 0) && (strcmp(format, "json") != 0)) {
        fprintf(stderr, "Invalid format '%s'. Expected csv or json.\n", format);
        return 2;
    }

    for (i = 0u; i < BENCH_WARMUP_RUNS; ++i) {
        run_sector(&s, iterations);
    }

    for (i = 0u; i < BENCH_SAMPLE_RUNS; ++i) {
        uint64_t t0 = now_ns();
        run_sector(&s, iterations);
        samples[i] = now_ns() - t0;
        sum_ns += samples[i];
    }

    min_ns = samples[0];
    max_ns = samples[0];
    for (i = 1u; i < BENCH_SAMPLE_RUNS; ++i) {
        if (samples[i] < min_ns) {
            min_ns = samples[i];
        }
        if (samples[i] > max_ns) {
            max_ns = samples[i];
        }
    }

    if (strcmp(format, "json") == 0) {
        printf("{\n");
        printf("  \"metric\": \"run_sector_ns\",\n");
        printf("  \"iterations_per_run\": %u,\n", iterations);
        printf("  \"warmup_runs\": %u,\n", BENCH_WARMUP_RUNS);
        printf("  \"sample_runs\": %u,\n", BENCH_SAMPLE_RUNS);
        printf("  \"min_ns\": %" PRIu64 ",\n", min_ns);
        printf("  \"max_ns\": %" PRIu64 ",\n", max_ns);
        printf("  \"mean_ns\": %.2f,\n", (double)sum_ns / (double)BENCH_SAMPLE_RUNS);
        printf("  \"samples_ns\": [");
        for (i = 0u; i < BENCH_SAMPLE_RUNS; ++i) {
            printf("%" PRIu64 "%s", samples[i], (i + 1u == BENCH_SAMPLE_RUNS) ? "" : ", ");
        }
        printf("]\n}\n");
    } else {
        printf("metric,iterations_per_run,warmup_runs,sample_runs,sample_index,elapsed_ns\n");
        for (i = 0u; i < BENCH_SAMPLE_RUNS; ++i) {
            printf("run_sector_ns,%u,%u,%u,%u,%" PRIu64 "\n", iterations, BENCH_WARMUP_RUNS, BENCH_SAMPLE_RUNS, i, samples[i]);
        }
    }

    return 0;
}
