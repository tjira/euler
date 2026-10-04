SHELL := $(if $(filter $(OS),Windows_NT),powershell.exe,sh)

.SHELLFLAGS := $(if $(filter $(OS),Windows_NT),-NoProfile -Command,-c)

# ENVIRONMENT VARIABLES ========================================================================================================================================

export GHCUP_INSTALL_BASE_PREFIX := $(CURDIR)
export MISE_DATA_DIR             := $(CURDIR)/.mise

# OUTPUT DIRECTORIES ===========================================================================================================================================

BUILD_DIR := build
BIN_DIR   := bin

# SYSTEM INFORMATION ===========================================================================================================================================

ARCH := $(if $(filter $(OS),Windows_NT),x86_64,$(shell uname -m | tr '[:upper:]' '[:lower:]' | sed 's/arm64/aarch64/'))
OS   := $(if $(filter $(OS),Windows_NT),windows,$(shell uname -s | tr '[:upper:]' '[:lower:]' | sed 's/darwin/macos/'))

EXE := $(if $(filter $(OS),windows),.exe)

# COMPILER VERSIONS ============================================================================================================================================

GHC_VERSION  := 9.14.1

# COMPILER COMMANDS AND FLAGS ==================================================================================================================================

GHCUP := .mise/shims/ghcup$(EXE)

CC          := gcc
CFLAGS      := -O3
CXX         := g++
CXXFLAGS    := -O3
FC          := gfortran
FCFLAGS     := -O3
GHC         := $(if $(filter $(OS),windows),./ghcup/bin/ghc.exe,./.ghcup/bin/ghc)
GHCFLAGS    := -O3
GO          := .mise/shims/go$(EXE)
GOFLAGS     :=
PYTHON      := .mise/shims/python$(EXE)
PYTHONFLAGS :=
RUSTC       := .mise/shims/rustc$(EXE)
RUSTFLAGS   := -C debuginfo=0 -C opt-level=3 $(if $(filter $(OS),windows),-C link-arg=/DEBUG:NONE)
ZIG         := .mise/shims/zig$(EXE)
ZIGFLAGS    := -O ReleaseFast -fstrip

# FORMATTER COMMANDS ===========================================================================================================================================

CLANG_FORMAT := .mise/shims/clang-format$(EXE)
FPRETTIFY    := .mise/shims/fprettify$(EXE)
GOFMT        := .mise/shims/gofmt$(EXE)
ORMOLU       := .mise/shims/ormolu$(EXE)
RUFF         := .mise/shims/ruff$(EXE)
RUSTFMT      := .mise/shims/rustfmt$(EXE)
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

$(BIN_DIR)/c-%$(EXE): src/c/%/main.c | $(BIN_DIR)
	$(CC) $(CFLAGS) -o $@ $<

$(BIN_DIR)/cpp-%$(EXE): src/cpp/%/main.cpp | $(BIN_DIR)
	$(CXX) $(CXXFLAGS) -o $@ $<

$(BIN_DIR)/fortran-%$(EXE): src/fortran/%/main.f90 | $(BIN_DIR)
	$(FC) $(FCFLAGS) -o $@ $<

$(BIN_DIR)/go-%$(EXE): src/go/%/main.go | $(BIN_DIR) $(GO)
	$(GO) build $(GOFLAGS) -o $@ $<

$(BIN_DIR)/haskell-%$(EXE): src/haskell/%/main.hs | $(BIN_DIR) $(BUILD_DIR) $(GHC)
	$(GHC) $(GHCFLAGS) -outputdir $(BUILD_DIR)/.ghc-$* -o $@ $<

$(BIN_DIR)/python-%$(EXE): src/python/%/main.py | $(BIN_DIR)
	cp $< $@ && chmod +x $@

$(BIN_DIR)/rust-%$(EXE): src/rust/%/main.rs | $(BIN_DIR) $(RUSTC)
	$(RUSTC) $(RUSTFLAGS) -o $@ $<

$(BIN_DIR)/zig-%$(EXE): src/zig/%/main.zig | $(BIN_DIR) $(ZIG)
	$(ZIG) build-exe $(ZIGFLAGS) -femit-bin="$@" $<

# FORMAT TARGETS ===============================================================================================================================================

format: $(FORMATS)

format-c: $(CLANG_FORMAT)
	$(CLANG_FORMAT) -i $(wildcard src/c/*/*.c)

format-cpp: $(CLANG_FORMAT)
	$(CLANG_FORMAT) -i $(wildcard src/cpp/*/*.cpp)

format-fortran: $(FPRETTIFY)
	$(FPRETTIFY) $(wildcard src/fortran/*/*.f90)

format-go: $(GOFMT)
	$(GOFMT) -w $(wildcard src/go/*/*.go)

format-haskell: $(ORMOLU)
	$(ORMOLU) --mode inplace $(wildcard src/haskell/*/*.hs)

format-python: $(RUFF)
	$(RUFF) format --no-cache $(wildcard src/python/*/*.py)

format-rust: $(RUSTFMT)
	$(RUSTFMT) $(wildcard src/rust/*/*.rs)

format-zig: $(ZIG)
	$(ZIG_FMT) $(wildcard src/zig/*/*.zig)

# TEST TARGETS =================================================================================================================================================

test: $(TESTS)

$(TESTS): test-%: $(BIN_DIR)/%
	@[ "$$($<)" = "$(word $(lastword $(subst -, ,$*)),$(RESULTS))" ] && printf "\033[0;32mPASS %s\033[0m\n" "$<" || { printf "\033[0;31mFAIL %s\033[0m\n" "$<"; exit 1; }

# COMPILER DOWNLOAD TARGETS ====================================================================================================================================

$(GHC): | $(GHCUP)
	@$(GHCUP) install ghc $(GHC_VERSION) --set

$(CLANG_FORMAT) $(FPRETTIFY) $(GHCUP) $(GO) $(GOFMT) $(ORMOLU) $(PYTHON) $(RUFF) $(RUSTC) $(RUSTFMT) $(ZIG): mise.toml
	@mise install

# DIRECTORY CREATION TARGETS ===================================================================================================================================

$(BUILD_DIR) $(BIN_DIR):
	@$(if $(filter windows,$(OS)),mkdir $@ -Force | Out-Null,mkdir -p $@)

# ADDITIONAL TARGETS ===========================================================================================================================================

clean:
	@git clean -dffx
