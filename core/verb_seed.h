#ifndef CORE_VERB_SEED_H
#define CORE_VERB_SEED_H

#include <stddef.h>
#include <stdint.h>

#include "sector.h"

uint64_t verb_seed_hash64(const char* verb, size_t len);
void verb_seed_state(struct state* s, const char* verb, size_t len, uint32_t salt);

#endif
