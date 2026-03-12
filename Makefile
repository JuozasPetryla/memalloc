TARGET_EXEC := main

CC := gcc
CPPCHECK := cppcheck
CPPCHECK_SUPPRESS_FLAGS := missingInclude missingIncludeSystem
CPPCHECK_SUPPRESS := $(foreach s,$(CPPCHECK_SUPPRESS_FLAGS),--suppress=$(s))
CFLAGS := -Wall -Wextra -ggdb -O0 -fno-omit-frame-pointer
CPPFLAGS := -Isrc -Ilib 

BUILD_DIR := build
SRC_DIR := src

SRC     := $(wildcard $(SRC_DIR)/*.c)

SRC_OBJS := $(patsubst $(SRC_DIR)/%.c,$(BUILD_DIR)/src/%.o,$(SRC))
OBJS := $(SRC_OBJS)

$(BUILD_DIR):
	@mkdir -p $@

$(BUILD_DIR)/src/%.o: $(SRC_DIR)/%.c | $(BUILD_DIR)
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/$(TARGET_EXEC): $(OBJS) | $(BUILD_DIR)
	$(CC) $(OBJS) -o $@ 
	
.PHONY: all clean

all: $(BUILD_DIR)/$(TARGET_EXEC)

clean:
	rm -rf $(BUILD_DIR)

cppcheck:
	@$(CPPCHECK) --quiet --enable=all --error-exitcode=1 --inline-suppr \
	$(CPPCHECK_SUPPRESS) -I$(SRC_DIR) --check-level=exhaustive \
	$(SRC_DIR)
