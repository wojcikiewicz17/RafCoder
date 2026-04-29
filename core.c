#include <stdint.h>
#include <stdio.h>

__attribute__((noinline, used)) static int add(int a, int b) {
    return a + b;
}

__attribute__((noinline, used)) static uint32_t update_state(uint32_t state, uint32_t input) {
    state ^= input + 0x9e3779b9u + (state << 6) + (state >> 2);
    state = (state << 13) | (state >> 19);
    state *= 1664525u;
    state += 1013904223u;
    return state;
}

__attribute__((noinline, used)) static int loop_sum(const int* data, int len) {
    int total = 0;
    for (int i = 0; i < len; ++i) {
        total = add(total, data[i]);
    }
    return total;
}

__attribute__((noinline, used)) static uint32_t state_step(uint32_t seed, const int* data, int len) {
    uint32_t state = seed;
    for (int i = 0; i < len; ++i) {
        state = update_state(state, (uint32_t)data[i]);
    }
    return state;
}

int main(void) {
    int values[] = {3, 1, 4, 1, 5, 9, 2, 6, 5};
    int len = (int)(sizeof(values) / sizeof(values[0]));

    int sum = loop_sum(values, len);
    uint32_t state = state_step(0x12345678u, values, len);

    printf("sum=%d\n", sum);
    printf("state=%u\n", state);

    if (sum != 36) {
        return 2;
    }
    return (state == 0u) ? 3 : 0;
}
