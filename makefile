.PHONY: all clean test format

SHELL := /bin/bash

# ENVIRONMENT VARIABLES FOR THE COMPILERS ======================================================================================================================

export GHCUP_INSTALL_BASE_PREFIX := $(CURDIR)
export CABAL_DIR                 := $(CURDIR)/.cabal-bin
export STACK_ROOT                := $(CURDIR)/.stack-bin
export RUSTUP_HOME               := $(CURDIR)/.rust-bin
export CARGO_HOME                := $(CURDIR)/.cargo-bin

# OUTPUT DIRECTORIES ===========================================================================================================================================

BUILD_DIR := build
BIN_DIR   := bin

# SYSTEM INFORMATION ===========================================================================================================================================

ARCH := $(if $(filter $(OS),Windows_NT),x86_64,$(shell uname -m | tr '[:upper:]' '[:lower:]' | sed 's/arm64/aarch64/'))
OS   := $(if $(filter $(OS),Windows_NT),windows,$(shell uname -s | tr '[:upper:]' '[:lower:]' | sed 's/darwin/macos/'))

# COMPILER VERSIONS ============================================================================================================================================

GHC_VERSION  := 9.14.1
ZIG_VERSION  := 0.16.0
RUST_VERSION := 1.99.0

# ADDITIONAL ENVIRONMENT VARIABLES =============================================================================================================================

export BOOTSTRAP_HASKELL_NONINTERACTIVE   := 1
export BOOTSTRAP_HASKELL_INSTALL_NO_STACK := 1
export BOOTSTRAP_HASKELL_GHC_VERSION      := $(GHC_VERSION)

# COMPILER COMMANDS AND FLAGS ==================================================================================================================================

CC          := gcc
CFLAGS      := -O3
CXX         := g++
CXXFLAGS    := -O3
FC          := gfortran
FCFLAGS     := -O3
GHC         := $(if $(filter $(OS),windows),./ghcup/bin/ghc.exe,./.ghcup/bin/ghc)
GHCFLAGS    := -O3
GO          := go
GOFLAGS     :=
PYTHON      := python3
PYTHONFLAGS :=
RUSTC       := ./.cargo-bin/bin/rustc$(if $(filter $(OS),windows),.exe)
RUSTFLAGS   := -C opt-level=3
ZIG         := ./.zig-bin/zig$(if $(filter $(OS),windows),.exe)
ZIGFLAGS    := -O ReleaseFast

# FORMATTER COMMANDS ===========================================================================================================================================

CLANG_FORMAT := clang-format
FPRETTIFY    := $(if $(filter $(OS),windows),.venv/Scripts/fprettify.exe,.venv/bin/fprettify)
GOFMT        := gofmt
ORMOLU       := ormolu
RUFF         := $(if $(filter $(OS),windows),.venv/Scripts/ruff.exe,.venv/bin/ruff)
RUSTFMT      := ./.cargo-bin/bin/rustfmt$(if $(filter $(OS),windows),.exe)
ZIG_FMT      := $(ZIG) fmt

FORMATS := $(patsubst src/%/,format-%,$(dir $(wildcard src/*/)))

# PROBLEM RESULTS ==============================================================================================================================================

RESULTS = \
    233168 \
    4613732 \
    6857 \
    906609

# GLOBAL TARGETS ===============================================================================================================================================

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

$(BIN_DIR)/haskell-%: src/haskell/%/main.hs | $(BIN_DIR) $(BUILD_DIR) $(GHC)
	$(GHC) $(GHCFLAGS) -outputdir $(BUILD_DIR)/.ghc-$* -o $@ $<

$(BIN_DIR)/python-%: src/python/%/main.py | $(BIN_DIR)
	cp $< $@ && chmod +x $@

$(BIN_DIR)/rust-%: src/rust/%/main.rs | $(BIN_DIR) $(RUSTC)
	$(RUSTC) $(RUSTFLAGS) -o $@ $<

$(BIN_DIR)/zig-%: src/zig/%/main.zig | $(BIN_DIR) $(ZIG)
	$(ZIG) build-exe $(ZIGFLAGS) -femit-bin=$@ $<

# FORMAT TARGETS ===============================================================================================================================================

format: $(FORMATS)

format-c:
	$(CLANG_FORMAT) -i src/c/*/*.c

format-cpp:
	$(CLANG_FORMAT) -i src/cpp/*/*.cpp

format-fortran: $(FPRETTIFY)
	$(FPRETTIFY) src/fortran/*/*.f90

format-go:
	$(GOFMT) -w src/go/*/*.go

format-haskell:
	$(ORMOLU) --mode inplace src/haskell/*/*.hs

format-python: $(RUFF)
	$(RUFF) format --no-cache src/python/*/*.py

format-rust: $(RUSTFMT)
	$(RUSTFMT) src/rust/*/*.rs

format-zig: $(ZIG)
	$(ZIG_FMT) src/zig/*/*.zig

# TEST TARGETS =================================================================================================================================================

test: $(TESTS)

$(TESTS): test-%: $(BIN_DIR)/%
	@[ "$$($<)" = "$(word $(lastword $(subst -, ,$*)),$(RESULTS))" ] && printf "\033[0;32mPASS %s\033[0m\n" "$<" || { printf "\033[0;31mFAIL %s\033[0m\n" "$<"; exit 1; }

# COMPILER DOWNLOAD TARGETS ====================================================================================================================================

ifeq ($(OS),windows)
$(GHC):
	@curl.exe -L# https://get-ghcup.haskell.org | BOOTSTRAP_HASKELL_GHC_VERSION=$(GHC_VERSION) sh
else
$(GHC):
	@curl -L# https://get-ghcup.haskell.org | BOOTSTRAP_HASKELL_GHC_VERSION=$(GHC_VERSION) sh
endif

ifeq ($(OS),windows)
$(RUSTC) $(RUSTFMT):
	@curl.exe -L# -o rustup-init.exe https://win.rustup.rs/$(ARCH) ; ./rustup-init.exe -y --default-toolchain $(RUST_VERSION) --no-modify-path ; rm rustup-init.exe
else
$(RUSTC) $(RUSTFMT):
	@curl -L# https://sh.rustup.rs | sh -s -- -y --default-toolchain $(RUST_VERSION) --no-modify-path
endif

ifeq ($(OS),windows)
$(ZIG): | .zig-bin
	@curl.exe -L# -o zig.zip https://ziglang.org/download/$(ZIG_VERSION)/zig-$(ARCH)-$(OS)-$(ZIG_VERSION).zip ; tar -xf zig.zip -C .zig-bin --strip-components=1 ; rm zig.zip
else
$(ZIG): | .zig-bin
	@curl --proto '=https' --tlsv1.2 -sSf https://ziglang.org/download/$(ZIG_VERSION)/zig-$(ARCH)-$(OS)-$(ZIG_VERSION).tar.xz | tar -Jx -C .zig-bin --strip-components=1
endif

# VIRTUAL ENVIRONMENT TARGETS ==================================================================================================================================

$(RUFF) $(FPRETTIFY): | .venv
	$(if $(filter $(OS),windows),.venv/Scripts/pip,.venv/bin/pip) install ruff fprettify

.venv:
	$(PYTHON) -m venv .venv

# AUXILIARY TARGETS ============================================================================================================================================

$(BUILD_DIR) $(BIN_DIR) .zig-bin:
	@mkdir -p $@

clean:
	@rm -rf $(BUILD_DIR) $(BIN_DIR) .zig-bin .rust-bin .cargo-bin .ghcup ghcup .cabal-bin .stack-bin .venv
