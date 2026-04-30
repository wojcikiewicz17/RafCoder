#ifndef CORE_ARCH_PRIMITIVES_H
#define CORE_ARCH_PRIMITIVES_H

#include <stddef.h>
#include <stdint.h>

/*
 * Primitive contract:
 * - C fallback is canonical behavior.
 * - x86_64, armv7 and aarch64 assembly backends must be behavior-equivalent.
 * - ARM NEON vectorized path is intentionally TODO and must not be advertised
 *   as implemented/performance-validated yet.
 */
uint64_t core_xor_u64(uint64_t a, uint64_t b);
uint64_t core_mul_u64(uint64_t a, uint64_t b);
uint64_t core_rotl_u64(uint64_t x, uint32_t shift);
uint8_t core_load_u8(const uint8_t* ptr);
void core_store_u8(uint8_t* ptr, uint8_t value);
void core_xor_block(uint8_t* dst, const uint8_t* src, size_t len);

#endif
