SHELL := $(if $(filter $(OS),Windows_NT),powershell.exe,sh)

.SHELLFLAGS := $(if $(filter $(OS),Windows_NT),-NoProfile -Command,-c)

.SECONDEXPANSION:

# ENVIRONMENT VARIABLES ========================================================================================================================================

export GHCUP_INSTALL_BASE_PREFIX := $(CURDIR)
export MISE_DATA_DIR             := $(CURDIR)/.mise
export MISE_CACHE_DIR            := $(CURDIR)/.mise/cache
export MISE_STATE_DIR            := $(CURDIR)/.mise/state

export NODE_DISABLE_COLORS := 1

MISE_EXEC ?= $(if $(__MISE_DIFF),,mise exec --)

# OUTPUT DIRECTORIES ===========================================================================================================================================

BUILD_DIR := build
BIN_DIR   := bin

# SYSTEM INFORMATION ===========================================================================================================================================

ARCH := $(if $(filter $(OS),Windows_NT),x86_64,$(shell uname -m | tr '[:upper:]' '[:lower:]' | sed 's/arm64/aarch64/'))
OS   := $(if $(filter $(OS),Windows_NT),windows,$(shell uname -s | tr '[:upper:]' '[:lower:]' | sed 's/darwin/macos/'))

COMP_EXE := $(if $(filter $(OS),windows),.exe)
INTP_EXE := $(if $(filter $(OS),windows),.cmd)

# COMPILER VERSIONS ============================================================================================================================================

GHC_VERSION  := 9.14.1

# COMPILER COMMANDS AND FLAGS ==================================================================================================================================

GHCUP := $(MISE_EXEC) ghcup

CC          := gcc
CFLAGS      := -O3 -s
CXX         := g++
CXXFLAGS    := -O3 -s
FC          := gfortran
FCFLAGS     := -O3 -s
GHC         := $(if $(filter $(OS),windows),ghcup/bin/ghc.exe,.ghcup/bin/ghc)
GHCFLAGS    := -O3 -optl-s
GO          := $(MISE_EXEC) go
GOFLAGS     := -ldflags="-s -w"
NODE        := $(MISE_EXEC) node
NODEFLAGS   :=
PYTHON      := $(MISE_EXEC) python
PYTHONFLAGS := -O
RUSTC       := $(MISE_EXEC) rustc
RUSTFLAGS   := -C opt-level=3 -C strip=symbols $(if $(filter $(OS),windows),-C link-arg=/DEBUG:NONE)
ZIG         := $(MISE_EXEC) zig
ZIGFLAGS    := -O ReleaseFast -fstrip

# FORMATTER COMMANDS ===========================================================================================================================================

CLANG_FORMAT := $(MISE_EXEC) clang-format
FPRETTIFY    := $(MISE_EXEC) fprettify
GOFMT        := $(MISE_EXEC) gofmt
ORMOLU       := $(MISE_EXEC) ormolu
RUFF         := $(MISE_EXEC) ruff
RUSTFMT      := $(MISE_EXEC) rustfmt
ZIG_FMT      := $(MISE_EXEC) zig fmt

FORMATS := $(patsubst src/%/,format-%,$(dir $(wildcard src/*/)))

# PROBLEM RESULTS ==============================================================================================================================================

RESULTS = \
    233168 \
    4613732 \
    6857 \
    906609

# GLOBAL TARGETS ===============================================================================================================================================

TEST_TASKS := $(subst /,-,$(patsubst src/%/,test-%,$(dir $(wildcard src/*/*/main.*))))
RUN_TARGETS := $(subst /,-,$(patsubst src/%/,run-%,$(dir $(wildcard src/*/*/main.*))))

BIN_TARGET = $(if $(filter javascript-% python-%,$1),$(BIN_DIR)/$1$(INTP_EXE),$(BIN_DIR)/$1$(COMP_EXE))

.PHONY: $(FORMATS) $(RUN_TARGETS) $(TEST_TASKS)

all: $(foreach t,$(TEST_TASKS:test-%=%),$(call BIN_TARGET,$(t)))

# BUILD TARGETS ================================================================================================================================================

$(BIN_DIR)/c-%$(COMP_EXE): src/c/%/main.c | $(BIN_DIR)
	$(CC) $(CFLAGS) -o $@ $<

$(BIN_DIR)/cpp-%$(COMP_EXE): src/cpp/%/main.cpp | $(BIN_DIR)
	$(CXX) $(CXXFLAGS) -o $@ $<

$(BIN_DIR)/fortran-%$(COMP_EXE): src/fortran/%/main.f90 | $(BIN_DIR)
	$(FC) $(FCFLAGS) -o $@ $<

$(BIN_DIR)/go-%$(COMP_EXE): src/go/%/main.go | $(BIN_DIR)
	$(GO) build $(GOFLAGS) -o $@ $<

$(BIN_DIR)/haskell-%$(COMP_EXE): src/haskell/%/main.hs | $(BIN_DIR) $(BUILD_DIR) $(GHC)
	$(GHC) $(GHCFLAGS) -outputdir $(BUILD_DIR)/.ghc-$* -o $@ $<

$(BIN_DIR)/rust-%$(COMP_EXE): src/rust/%/main.rs | $(BIN_DIR)
	$(RUSTC) $(RUSTFLAGS) -o $@ $<

$(BIN_DIR)/zig-%$(COMP_EXE): src/zig/%/main.zig | $(BIN_DIR)
	$(ZIG) build-exe $(ZIGFLAGS) -femit-bin="$@" $<

ifeq ($(OS),windows)

$(BIN_DIR)/javascript-%$(INTP_EXE): src/javascript/%/main.js | $(BIN_DIR)
	@Set-Content -Path $@ -Value '// 2>nul & @"$(shell $(NODE) -e "console.log(process.execPath)")" $(NODEFLAGS) "%~f0" %* & exit /b', "", (Get-Content -Path $<)

$(BIN_DIR)/python-%$(INTP_EXE): src/python/%/main.py | $(BIN_DIR)
	@Set-Content -Path $@ -Value '@"$(shell $(PYTHON) -c "import sys; print(sys.executable)")" $(PYTHONFLAGS) -x "%~f0" %* & exit /b', "", (Get-Content -Path $<)

else

$(BIN_DIR)/javascript-%$(INTP_EXE): src/javascript/%/main.js | $(BIN_DIR)
	@printf '%s\n\n' "#!$(shell $(NODE) -e 'console.log(process.execPath)') $(NODEFLAGS)" > $@ && cat $< >> $@ && chmod +x $@

$(BIN_DIR)/python-%$(INTP_EXE): src/python/%/main.py | $(BIN_DIR)
	@printf '%s\n\n' "#!$(shell $(PYTHON) -c 'import sys; print(sys.executable)') $(PYTHONFLAGS)" > $@ && cat $< >> $@ && chmod +x $@

endif

# FORMAT TARGETS ===============================================================================================================================================

format: $(FORMATS)

format-c:
	$(CLANG_FORMAT) -i $(wildcard src/c/*/*.c)

format-cpp:
	$(CLANG_FORMAT) -i $(wildcard src/cpp/*/*.cpp)

format-fortran:
	$(FPRETTIFY) $(wildcard src/fortran/*/*.f90)

format-go:
	$(GOFMT) -w $(wildcard src/go/*/*.go)

format-haskell:
	$(ORMOLU) --mode inplace $(wildcard src/haskell/*/*.hs)

format-javascript:
	$(CLANG_FORMAT) -i $(wildcard src/javascript/*/*.js)

format-python:
	$(RUFF) format --no-cache $(wildcard src/python/*/*.py)

format-rust:
	$(RUSTFMT) $(wildcard src/rust/*/*.rs)

format-zig:
	$(ZIG_FMT) $(wildcard src/zig/*/*.zig)

# RUN TARGETS ==================================================================================================================================================

run: $(RUN_TARGETS)

$(RUN_TARGETS): run-%: $$(call BIN_TARGET,%)
	@$<

# TEST TARGETS =================================================================================================================================================

test: $(TEST_TASKS)

$(TEST_TASKS): test-%: $$(call BIN_TARGET,%)
	@[ "$$($<)" = "$(word $(lastword $(subst -, ,$*)),$(RESULTS))" ] && printf "\033[0;32mPASS %s\033[0m\n" "$<" || { printf "\033[0;31mFAIL %s\033[0m\n" "$<"; exit 1; }

# COMPILER DOWNLOAD TARGETS ====================================================================================================================================

$(GHC):
	@$(GHCUP) install ghc $(GHC_VERSION) --set

setup:
	@mise install

# DIRECTORY CREATION TARGETS ===================================================================================================================================

$(BUILD_DIR) $(BIN_DIR):
	@$(if $(filter windows,$(OS)),mkdir $@ -Force | Out-Null,mkdir -p $@)

# ADDITIONAL TARGETS ===========================================================================================================================================

clean:
	@git clean -dffx -e .ghcup -e ghcup -e .mise
