.PHONY: all clean test

SHELL := /bin/bash

BUILD_DIR ?= build
BIN_DIR   ?= bin

CC          ?= gcc
CFLAGS      ?= -O3
CXX         ?= g++
CXXFLAGS    ?= -O3
GHC         ?= ghc
GHCFLAGS    ?= -O3
RUSTC       ?= rustc
RUSTFLAGS   ?= -C opt-level=3
GO          ?= go
GOFLAGS     ?=
PYTHON      ?= python3
PYTHONFLAGS ?=

RESULTS = \
    233168 \
    4613732 \
    6857 \
    906609

TESTS := $(subst /,-,$(patsubst src/%/,test-%,$(dir $(wildcard src/*/*/main.*))))

.PHONY: $(TESTS)

all: $(TESTS:test-%=$(BIN_DIR)/%)

$(BUILD_DIR) $(BIN_DIR):
	@mkdir -p $@

$(BIN_DIR)/c-%: src/c/%/main.c | $(BIN_DIR)
	$(CC) $(CFLAGS) -o $@ $<

$(BIN_DIR)/cpp-%: src/cpp/%/main.cpp | $(BIN_DIR)
	$(CXX) $(CXXFLAGS) -o $@ $<

$(BIN_DIR)/go-%: src/go/%/main.go | $(BIN_DIR)
	$(GO) build $(GOFLAGS) -o $@ $<

$(BIN_DIR)/haskell-%: src/haskell/%/main.hs | $(BUILD_DIR) $(BIN_DIR)
	$(GHC) $(GHCFLAGS) -outputdir $(BUILD_DIR)/.ghc-$* -o $@ $<

$(BIN_DIR)/python-%: src/python/%/main.py | $(BIN_DIR)
	cp $< $@ && chmod +x $@

$(BIN_DIR)/rust-%: src/rust/%/main.rs | $(BIN_DIR)
	$(RUSTC) $(RUSTFLAGS) -o $@ $<

test: $(TESTS)

$(TESTS): test-%: $(BIN_DIR)/%
	@[ "$$($<)" = "$(word $(lastword $(subst -, ,$*)),$(RESULTS))" ] && printf "\033[0;32mPASS %s\033[0m\n" "$<" || { printf "\033[0;31mFAIL %s\033[0m\n" "$<"; exit 1; }

clean:
	@rm -rf $(BUILD_DIR) $(BIN_DIR)
