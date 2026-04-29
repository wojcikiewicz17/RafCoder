CC ?= cc
AR ?= ar
CFLAGS ?= -O2 -Wall -Wextra -Werror -std=c11
CFLAGS += -ffreestanding -nostdlib -fno-builtin -fno-stack-protector

SRC = sector.c verb_seed.c arch/primitives.c

ifeq ($(shell uname -m),x86_64)
SRC += arch/x86_64/primitives.S
endif
ifeq ($(shell uname -m),aarch64)
SRC += arch/aarch64/primitives.S
endif
ifeq ($(shell uname -m),armv7l)
SRC += arch/armv7/primitives.S
endif
ifeq ($(shell uname -m),armv8l)
SRC += arch/armv7/primitives.S
endif

OBJ = $(SRC:.c=.o)
OBJ := $(OBJ:.S=.o)

all: libsector_core.a

libsector_core.a: $(OBJ)
	$(AR) rcs $@ $(OBJ)

%.o: %.c
	$(CC) $(CFLAGS) -I. -c $< -o $@

%.o: %.S
	$(CC) $(CFLAGS) -I. -c $< -o $@

test_reentrancy: test_sector_reentrancy.c $(SRC)
	$(CC) -O2 -Wall -Wextra -Werror -std=c11 -I. test_sector_reentrancy.c $(SRC) -pthread -o $@

test_snapshot: test_sector_snapshot.c $(SRC)
	$(CC) -O2 -Wall -Wextra -Werror -std=c11 -I. test_sector_snapshot.c $(SRC) -o $@

test_primitives_equivalence: test_primitives_equivalence.c $(SRC)
	$(CC) -O2 -Wall -Wextra -Werror -std=c11 -I. test_primitives_equivalence.c $(SRC) -o $@

benchmark_run_sector: benchmark_run_sector.c $(SRC)
	$(CC) -O2 -Wall -Wextra -Werror -std=c11 -I. benchmark_run_sector.c $(SRC) -o $@


test_verb_seed: test_verb_seed.c $(SRC)
	$(CC) -O2 -Wall -Wextra -Werror -std=c11 -I. test_verb_seed.c $(SRC) -o $@

clean:
	rm -f $(OBJ) libsector_core.a test_reentrancy test_snapshot test_primitives_equivalence test_verb_seed benchmark_run_sector

.PHONY: all clean test_reentrancy test_snapshot test_primitives_equivalence test_verb_seed benchmark_run_sector
