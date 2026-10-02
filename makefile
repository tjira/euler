.PHONY: all clean test format

SHELL := /bin/bash

BUILD_DIR := build
BIN_DIR   := bin

ARCH := $(if $(filter $(OS),Windows_NT),x86_64,$(shell uname -m | tr '[:upper:]' '[:lower:]' | sed 's/arm64/aarch64/'))
OS   := $(if $(filter $(OS),Windows_NT),windows,$(shell uname -s | tr '[:upper:]' '[:lower:]' | sed 's/darwin/macos/'))

ZIG_VERSION := 0.16.0

CC          := gcc
CFLAGS      := -O3
CXX         := g++
CXXFLAGS    := -O3
FC          := gfortran
FCFLAGS     := -O3
GHC         := ghc
GHCFLAGS    := -O3
GO          := go
GOFLAGS     :=
PYTHON      := python3
PYTHONFLAGS :=
RUSTC       := rustc
RUSTFLAGS   := -C opt-level=3
ZIG         := ./.zig-bin/zig$(if $(filter $(OS),windows),.exe)
ZIGFLAGS    := -O ReleaseFast

CLANG_FORMAT := clang-format
FPRETTIFY    := fprettify
GOFMT        := gofmt
ORMOLU       := ormolu
RUFF         := ruff
RUSTFMT      := rustfmt
ZIG_FMT      := $(ZIG) fmt

FORMATS := $(patsubst src/%/,format-%,$(dir $(wildcard src/*/)))

RESULTS = \
    233168 \
    4613732 \
    6857 \
    906609

TESTS := $(subst /,-,$(patsubst src/%/,test-%,$(dir $(wildcard src/*/*/main.*))))

.PHONY: $(FORMATS) $(TESTS)

all: $(TESTS:test-%=$(BIN_DIR)/%)

# BUILD TARGETS ================================================================================================================================================

$(BIN_DIR)/c-%: src/c/%/main.c | $(BIN_DIR)
	$(CC) $(CFLAGS) -o $@ $<

$(BIN_DIR)/cpp-%: src/cpp/%/main.cpp | $(BIN_DIR)
	$(CXX) $(CXXFLAGS) -o $@ $<

$(BIN_DIR)/fortran-%: src/fortran/%/main.f90 | $(BIN_DIR)
	$(FC) $(FCFLAGS) -o $@ $<

$(BIN_DIR)/go-%: src/go/%/main.go | $(BIN_DIR)
	$(GO) build $(GOFLAGS) -o $@ $<

$(BIN_DIR)/haskell-%: src/haskell/%/main.hs | $(BUILD_DIR) $(BIN_DIR)
	$(GHC) $(GHCFLAGS) -outputdir $(BUILD_DIR)/.ghc-$* -o $@ $<

$(BIN_DIR)/python-%: src/python/%/main.py | $(BIN_DIR)
	cp $< $@ && chmod +x $@

$(BIN_DIR)/rust-%: src/rust/%/main.rs | $(BIN_DIR)
	$(RUSTC) $(RUSTFLAGS) -o $@ $<

$(BIN_DIR)/zig-%: src/zig/%/main.zig | $(BIN_DIR) .zig-bin/zig$(if $(filter $(OS),windows),.exe)
	$(ZIG) build-exe $(ZIGFLAGS) -femit-bin=$@ $<

# FORMAT TARGETS ===============================================================================================================================================

format: $(FORMATS)

format-c:
	$(CLANG_FORMAT) -i src/c/*/*.c

format-cpp:
	$(CLANG_FORMAT) -i src/cpp/*/*.cpp

format-fortran:
	$(FPRETTIFY) src/fortran/*/*.f90

format-go:
	$(GOFMT) -w src/go/*/*.go

format-haskell:
	$(ORMOLU) --mode inplace src/haskell/*/*.hs

format-python:
	$(RUFF) format --no-cache src/python/*/*.py

format-rust:
	$(RUSTFMT) src/rust/*/*.rs

format-zig: .zig-bin/zig$(if $(filter $(OS),windows),.exe)
	$(ZIG_FMT) src/zig/*/*.zig

# TEST TARGETS =================================================================================================================================================

test: $(TESTS)

$(TESTS): test-%: $(BIN_DIR)/%
	@[ "$$($<)" = "$(word $(lastword $(subst -, ,$*)),$(RESULTS))" ] && printf "\033[0;32mPASS %s\033[0m\n" "$<" || { printf "\033[0;31mFAIL %s\033[0m\n" "$<"; exit 1; }

# COMPILER DOWNLOAD TARGETS =====================================================================================================================

ifeq ($(OS),windows)
.zig-bin/zig.exe: | .zig-bin
	@curl.exe -L# -o zig.zip https://ziglang.org/download/$(ZIG_VERSION)/zig-$(ARCH)-$(OS)-$(ZIG_VERSION).zip ; tar -xf zig.zip -C .zig-bin --strip-components=1 ; rm zig.zip
else
.zig-bin/zig: | .zig-bin
	@curl -L# https://ziglang.org/download/$(ZIG_VERSION)/zig-$(ARCH)-$(OS)-$(ZIG_VERSION).tar.xz | tar -Jx -C .zig-bin --strip-components=1
endif

# AUXILIARY TARGETS ============================================================================================================================================

$(BUILD_DIR) $(BIN_DIR) .zig-bin:
	@mkdir -p $@

clean:
	@rm -rf $(BUILD_DIR) $(BIN_DIR) .zig-bin
