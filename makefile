SHELL := $(if $(filter $(OS),Windows_NT),powershell.exe,sh)

.SHELLFLAGS := $(if $(filter $(OS),Windows_NT),-NoProfile -Command,-c)

.SECONDEXPANSION:

# ENVIRONMENT VARIABLES ========================================================================================================================================

export GHCUP_INSTALL_BASE_PREFIX := $(CURDIR)

export MISE_CACHE_DIR := $(CURDIR)/.mise/cache
export MISE_STATE_DIR := $(CURDIR)/.mise/state

export NODE_DISABLE_COLORS := 1

MISE_EXEC ?= $(if $(__MISE_DIFF),,mise exec --)

export MISE_DATA_DIR := $(CURDIR)/.mise

export MISE_EXEC_AUTO_INSTALL := false

# OUTPUT DIRECTORIES ===========================================================================================================================================

BUILD_DIR := build
BIN_DIR   := bin

# SYSTEM INFORMATION ===========================================================================================================================================

ARCH := $(if $(filter $(OS),Windows_NT),x86_64,$(shell uname -m | tr '[:upper:]' '[:lower:]' | sed 's/arm64/aarch64/'))
OS   := $(if $(filter $(OS),Windows_NT),windows,$(shell uname -s | tr '[:upper:]' '[:lower:]' | sed 's/darwin/macos/'))

COMP_EXE := $(if $(filter $(OS),windows),.exe)
INTP_EXE := $(if $(filter $(OS),windows),.cmd)

# COMPILER VERSIONS ============================================================================================================================================

GHC_VERSION = $(shell mise config get env.GHC_VERSION)

# COMPILER COMMANDS AND FLAGS ==================================================================================================================================

GHCUP := $(MISE_EXEC) ghcup

CC          := gcc
CFLAGS      := -O3 -mtune=native $(if $(filter $(OS),macos),,-s)
CXX         := g++
CXXFLAGS    := -O3 -mtune=native $(if $(filter $(OS),macos),,-s)
FC          := gfortran
FCFLAGS     := -O3 -mtune=native $(if $(filter $(OS),macos),,-s)
GHC         := $(if $(filter $(OS),windows),ghcup/bin/ghc.exe,.ghcup/bin/ghc)
GHCFLAGS    := -O2 -optl-s -v0
GO          := $(MISE_EXEC) go
GOFLAGS     := -ldflags="-s -w"
JULIA       := $(MISE_EXEC) julia
JULIAFLAGS  := -O3
NIM         := $(MISE_EXEC) nim
NIMFLAGS    := --define:release --hints:off --opt:speed --passC:"-march=native"
NODE        := $(MISE_EXEC) node
NODEFLAGS   := --turbo-fast-api-calls
ODIN        := $(MISE_EXEC) odin
ODINFLAGS   := --microarch:native --o:speed
PYTHON      := $(MISE_EXEC) python
PYTHONFLAGS := -OOS
RUSTC       := $(MISE_EXEC) rustc
RUSTFLAGS   := -C opt-level=3 -C strip=symbols -C target-cpu=native$(if $(filter $(OS),windows), -C link-arg=/DEBUG:NONE)
ZIG         := $(MISE_EXEC) zig
ZIGFLAGS    := -O ReleaseFast -mcpu=native -fstrip --color off

# FORMATTER COMMANDS ===========================================================================================================================================

CLANG_FORMAT := $(MISE_EXEC) clang-format
FPRETTIFY    := $(MISE_EXEC) fprettify
GOFMT        := $(MISE_EXEC) gofmt
NIMPRETTY    := $(MISE_EXEC) nimpretty
ODINFMT      := $(MISE_EXEC) odinfmt
ORMOLU       := $(MISE_EXEC) ormolu
RUFF         := $(MISE_EXEC) ruff
RUSTFMT      := $(MISE_EXEC) rustfmt
ZIG_FMT      := $(MISE_EXEC) zig fmt

# BENCHMARK COMMANDS ===========================================================================================================================================

HYPERFINE       := $(MISE_EXEC) hyperfine
HYPERFINE_FLAGS := --min-runs 100 --shell=none --warmup=10

BENCHMARK_TARGETS := $(subst /,-,$(patsubst src/%/,benchmark-%,$(dir $(wildcard src/*/*/main.*))))

# PROBLEM RESULTS ==============================================================================================================================================

RESULTS = \
    233168 \
    4613732 \
    6857 \
    906609 \
	232792560

# GLOBAL TARGETS ===============================================================================================================================================

FORMATS := $(patsubst src/%/,format-%,$(dir $(wildcard src/*/)))

RUN_TARGETS := $(subst /,-,$(patsubst src/%/,run-%,$(dir $(wildcard src/*/*/main.*))))
TEST_TASKS := $(subst /,-,$(patsubst src/%/,test-%,$(dir $(wildcard src/*/*/main.*))))

BIN_TARGET = $(if $(filter javascript-% julia-% python-%,$1),$(BIN_DIR)/$1$(INTP_EXE),$(BIN_DIR)/$1$(COMP_EXE))

.PHONY: $(BENCHMARK_TARGETS) $(FORMATS) $(RUN_TARGETS) $(TEST_TASKS) benchmark

all: $(foreach t,$(TEST_TASKS:test-%=%),$(call BIN_TARGET,$(t)))

# BUILD TARGETS FOR PROJECTS WITH BUILT-IN COMPILERS ======================================================================================================-----

$(BIN_DIR)/c-%$(COMP_EXE): src/c/%/main.c | $(BIN_DIR) $(BUILD_DIR)/.c-%
	$(CC) $(CFLAGS) -o $@ $<

$(BIN_DIR)/cpp-%$(COMP_EXE): src/cpp/%/main.cpp | $(BIN_DIR) $(BUILD_DIR)/.cpp-%
	$(CXX) $(CXXFLAGS) -o $@ $<

$(BIN_DIR)/fortran-%$(COMP_EXE): src/fortran/%/main.f90 | $(BIN_DIR) $(BUILD_DIR)/.fortran-%
	$(FC) $(FCFLAGS) -J $(BUILD_DIR)/.fortran-$* -o $@ $<

# BUILD TARGETS FOR PROJECTS WITH MISE-EXECUTABLE COMPILERS ====================================================================================================

$(BIN_DIR)/go-%$(COMP_EXE): src/go/%/main.go | $(BIN_DIR) .mise/installs/go
	$(GO) build $(GOFLAGS) -o $@ $<

$(BIN_DIR)/nim-%$(COMP_EXE): src/nim/%/main.nim | $(BIN_DIR) $(BUILD_DIR)/.nim-% .mise/installs/nim
	$(NIM) c $(NIMFLAGS) --out:$@ $<

$(BIN_DIR)/odin-%$(COMP_EXE): src/odin/%/main.odin | $(BIN_DIR) $(BUILD_DIR)/.odin-% .mise/installs/odin
	$(ODIN) build $< -file --out:$@ $(ODINFLAGS)

$(BIN_DIR)/rust-%$(COMP_EXE): src/rust/%/main.rs | $(BIN_DIR) $(BUILD_DIR)/.rust-% .mise/installs/rust
	$(RUSTC) $(RUSTFLAGS) -o $@ $<

$(BIN_DIR)/zig-%$(COMP_EXE): src/zig/%/main.zig | $(BIN_DIR) $(BUILD_DIR)/.zig-% .mise/installs/zig
	$(ZIG) build-exe $(ZIGFLAGS) -femit-bin="$@" $<

# BUILD TARGETS FOR PROJECTS WITH EXTERNAL COMPILERS ===========================================================================================================

$(BIN_DIR)/haskell-%$(COMP_EXE): src/haskell/%/main.hs | $(BIN_DIR) $(BUILD_DIR)/.ghc-% $(GHC)
	$(GHC) $(GHCFLAGS) -outputdir $(BUILD_DIR)/.ghc-$* -o $@ $<

# BUILD TARGETS FOR PROJECTS WITH INTERPRETER SCRIPTS ==========================================================================================================

ifeq ($(OS),windows)
$(BIN_DIR)/javascript-%$(INTP_EXE): src/javascript/%/main.js | $(BIN_DIR) $(BUILD_DIR)/.javascript-% .mise/installs/node
	@Set-Content -Path $@ -Value '@"$(shell mise which node)" $(NODEFLAGS) "$<" %* & exit /b'

$(BIN_DIR)/julia-%$(INTP_EXE): src/julia/%/main.jl | $(BIN_DIR) $(BUILD_DIR)/.julia-% .mise/installs/julia
	@Set-Content -Path $@ -Value '@"$(shell mise which julia)" $(JULIAFLAGS) "$<" %* & exit /b'

$(BIN_DIR)/python-%$(INTP_EXE): src/python/%/main.py | $(BIN_DIR) $(BUILD_DIR)/.python-% .mise/installs/python
	@Set-Content -Path $@ -Value '@"$(shell mise which python)" $(PYTHONFLAGS) "$<" %* & exit /b'
else
$(BIN_DIR)/javascript-%$(INTP_EXE): src/javascript/%/main.js | $(BIN_DIR) $(BUILD_DIR)/.javascript-% .mise/installs/node
	@printf '%s\n\n' "#!$(shell mise which node) $(NODEFLAGS)" > $@ && cat $< >> $@ && chmod +x $@

$(BIN_DIR)/julia-%$(INTP_EXE): src/julia/%/main.jl | $(BIN_DIR) $(BUILD_DIR)/.julia-% .mise/installs/julia
	@printf '%s\n\n' "#!$(shell mise which julia) $(JULIAFLAGS)" > $@ && cat $< >> $@ && chmod +x $@

$(BIN_DIR)/python-%$(INTP_EXE): src/python/%/main.py | $(BIN_DIR) $(BUILD_DIR)/.python-% .mise/installs/python
	@printf '%s\n\n' "#!$(shell mise which python) $(PYTHONFLAGS)" > $@ && cat $< >> $@ && chmod +x $@
endif

# FORMAT TARGETS ===============================================================================================================================================

format: $(FORMATS)

format-c: | .mise/installs/clang-format
	$(CLANG_FORMAT) -i $(wildcard src/c/*/*.c)

format-cpp: | .mise/installs/clang-format
	$(CLANG_FORMAT) -i $(wildcard src/cpp/*/*.cpp)

format-fortran: | .mise/installs/conda-fprettify
	$(FPRETTIFY) $(wildcard src/fortran/*/*.f90)

format-go: | .mise/installs/go
	$(GOFMT) -w $(wildcard src/go/*/*.go)

format-haskell: | .mise/installs/ormolu
	$(ORMOLU) --mode inplace $(wildcard src/haskell/*/*.hs)

format-javascript: | .mise/installs/clang-format
	$(CLANG_FORMAT) -i $(wildcard src/javascript/*/*.js)

format-julia: | .mise/installs/julia
	$(JULIA) -e "using JuliaFormatter; foreach(format_file, ARGS)" $(wildcard src/julia/*/*.jl)

format-nim: | .mise/installs/nim
	$(NIMPRETTY) $(wildcard src/nim/*/*.nim)

format-odin: | .mise/installs/ols
	$(ODINFMT) -w $(wildcard src/odin/*/*.odin)

format-python: | .mise/installs/ruff
	$(RUFF) format --no-cache --quiet $(wildcard src/python/*/*.py)

format-rust: | .mise/installs/rust
	$(RUSTFMT) $(wildcard src/rust/*/*.rs)

format-zig: | .mise/installs/zig
	$(ZIG_FMT) $(wildcard src/zig/*/*.zig)

# EDITOR TARGETS ===============================================================================================================================================

nvim: $(sort $(wildcard src/*/*/*))
	@nvim $^

$(patsubst src/%/,nvim-%,$(dir $(wildcard src/*/))): nvim-%: $$(sort $$(wildcard src/%/*/*))
	@nvim $^

$(patsubst %,nvim-%,$(sort $(notdir $(patsubst %/,%,$(dir $(wildcard src/*/*/main.*)))))): nvim-%: $$(sort $$(wildcard src/*/%/*))
	@nvim $^

$(subst /,-,$(patsubst src/%/,nvim-%,$(dir $(wildcard src/*/*/main.*)))): nvim-%: $$(sort $$(wildcard src/$$(subst -,/,%)/*))
	@nvim $^

# RUN TARGETS ==================================================================================================================================================

run: $(RUN_TARGETS)

$(RUN_TARGETS): run-%: $$(call BIN_TARGET,%)
	@$<

# TEST TARGETS =================================================================================================================================================

test: $(TEST_TASKS)

ifeq ($(OS),windows)
$(TEST_TASKS): test-%: $$(call BIN_TARGET,%)
	@if ((& $<) -eq '$(word $(lastword $(subst -, ,$*)),$(RESULTS))') { Write-Host 'PASS $<' -ForegroundColor Green } else { Write-Host 'FAIL $<' -ForegroundColor Red; exit 1 }
else
$(TEST_TASKS): test-%: $$(call BIN_TARGET,%)
	@[ "$$($<)" = "$(word $(lastword $(subst -, ,$*)),$(RESULTS))" ] && printf "\033[0;32mPASS %s\033[0m\n" "$<" || { printf "\033[0;31mFAIL %s\033[0m\n" "$<"; exit 1; }
endif

# BENCHMARK TARGETS ============================================================================================================================================

benchmark: $(BENCHMARK_TARGETS)

benchmark-%: all .mise/installs/hyperfine
	@$(HYPERFINE) $(HYPERFINE_FLAGS) --sort mean-time $(sort $(wildcard $(BIN_DIR)/*-$*$(COMP_EXE) $(BIN_DIR)/*-$*$(INTP_EXE)))

$(BENCHMARK_TARGETS): benchmark-%: $$(call BIN_TARGET,%) .mise/installs/hyperfine
	@$(HYPERFINE) $(HYPERFINE_FLAGS) '$<'

# COMPILER DOWNLOAD TARGETS ====================================================================================================================================

setup: mise julia $(GHC)

.mise/installs/conda-%:
	@mise install conda:$*

.mise/installs/%:
	@mise install $*

$(GHC): | .mise/installs/ghcup
	@$(GHCUP) install ghc $(GHC_VERSION) --set

julia: | .mise/installs/julia
	@$(JULIA) -e 'import Pkg; Base.find_package(string(:JuliaFormatter)) !== nothing || Pkg.add(string(:JuliaFormatter))'

mise:
	@mise install

# DIRECTORY CREATION TARGETS ===================================================================================================================================

$(BUILD_DIR) $(BIN_DIR):
	@$(if $(filter windows,$(OS)),mkdir $@ -Force | Out-Null,mkdir -p $@)

.PRECIOUS: $(BUILD_DIR)/.%

$(BUILD_DIR)/.%:
	@$(if $(filter windows,$(OS)),mkdir $@ -Force | Out-Null,mkdir -p $@)

# ADDITIONAL TARGETS ===========================================================================================================================================

clean:
	@git clean -dffx -e .ghcup -e ghcup -e .mise
