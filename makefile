.PHONY: all clean

SHELL:=/bin/bash

RESULTS = \
    233168 \
	4613732 \
	6857 \
	906609 \

C       := $(shell cd src/c       && ls)
CPP     := $(shell cd src/cpp     && ls)
GO      := $(shell cd src/go      && ls)
HASKELL := $(shell cd src/haskell && ls)
PYTHON  := $(shell cd src/python  && ls)
RUST    := $(shell cd src/rust    && ls)

all: init $(C:%=bin/c-%) $(CPP:%=bin/cpp-%) $(GO:%=bin/go-%) $(HASKELL:%=bin/haskell-%) $(PYTHON:%=bin/python-%) $(RUST:%=bin/rust-%)

init:
	@mkdir -p bin

bin/c-%: src/c/%/main.c
	gcc -o $@ $<

bin/cpp-%: src/cpp/%/main.cpp
	g++ -o $@ $<

bin/go-%: src/go/%/main.go
	go build -o $@ $<

bin/haskell-%: src/haskell/%/main.hs
	ghc -o $@ $<

bin/python-%: src/python/%/main.py
	cp $< $@

bin/rust-%: src/rust/%/main.rs
	rustc -o $@ $<

test:
	@for BIN in $$(ls bin); do \
		EXPECTED_OUTPUT=$$(echo $(RESULTS) | cut -d " " -f $$(echo $$BIN | cut -d "-" -f 2)); S_TIME=$$(date +%s%N); ACTUAL_OUTPUT=$$(./bin/$$BIN); \
		E_TIME=$$(date +%s%N); if [ $$ACTUAL_OUTPUT != $$EXPECTED_OUTPUT ]; then FAIL=1; COLOUR="\033[0;31m"; else FAIL=0; COLOUR="\033[0;32m"; fi; \
		printf "$$COLOUR$$BIN: ACTUAL=$$ACTUAL_OUTPUT, EXPECTED=$$EXPECTED_OUTPUT, TIME=$$(((E_TIME - S_TIME) / 1000000))ms\033[0m\n"; \
	done && if [ $$FAIL == 1 ]; then exit 1; fi
