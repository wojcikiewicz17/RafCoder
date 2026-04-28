CC ?= cc
AR ?= ar
CFLAGS ?= -O2 -Wall -Wextra -Werror -std=c11
CFLAGS += -ffreestanding -nostdlib -fno-builtin -fno-stack-protector

SRC = sector.c arch/primitives.c

ifeq ($(shell uname -m),x86_64)
SRC += arch/x86_64/primitives.S
endif
ifeq ($(shell uname -m),aarch64)
SRC += arch/aarch64/primitives.S
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

clean:
	rm -f $(OBJ) libsector_core.a test_reentrancy

.PHONY: all clean test_reentrancy
