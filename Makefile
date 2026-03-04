TARGET_EXEC := main

CURL_CFLAGS := $(shell pkg-config --cflags libcurl)
CURL_LIBS   := $(shell pkg-config --libs libcurl)

CC := gcc
CPPCHECK := cppcheck
CPPCHECK_SUPPRESS_FLAGS := missingInclude missingIncludeSystem
CPPCHECK_SUPPRESS := $(foreach s,$(CPPCHECK_SUPPRESS_FLAGS),--suppress=$(s))
CFLAGS := -Wall -Wextra
CPPFLAGS := -Isrc -Ilib $(CURL_CFLAGS)
LDLIBS := $(CURL_LIBS)

BUILD_DIR := build
SRC_DIR := src
LIB_DIR := lib

SRC     := $(wildcard $(SRC_DIR)/*.c)
LIB_SRC := $(wildcard $(LIB_DIR)/*/*.c)

SRC_OBJS := $(patsubst $(SRC_DIR)/%.c,$(BUILD_DIR)/src/%.o,$(SRC))
LIB_OBJS := $(patsubst $(LIB_DIR)/%.c,$(BUILD_DIR)/lib/%.o,$(LIB_SRC))
OBJS := $(SRC_OBJS) $(LIB_OBJS)

$(BUILD_DIR):
	@mkdir -p $@

$(BUILD_DIR)/src/%.o: $(SRC_DIR)/%.c | $(BUILD_DIR)
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/lib/%.o: $(LIB_DIR)/%.c | $(BUILD_DIR)
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/$(TARGET_EXEC): $(OBJS) | $(BUILD_DIR)
	$(CC) $(OBJS) -o $@ $(LDLIBS)
	
.PHONY: all clean

all: $(BUILD_DIR)/$(TARGET_EXEC)

clean:
	rm -rf $(BUILD_DIR)

cppcheck:
	@$(CPPCHECK) --quiet --enable=all --error-exitcode=1 --inline-suppr \
	$(CPPCHECK_SUPPRESS) -I$(SRC_DIR) --check-level=exhaustive \
	$(SRC_DIR)
