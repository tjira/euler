.PHONY: all clean

TARGETS = 1 2 3

all: init $(TARGETS:%=bin/haskell-%)

init:
	@mkdir -p bin

bin/haskell-%: haskell/%/main.hs
	ghc -o $@ $<
