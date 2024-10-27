.PHONY: all clean

CPP     := $(shell cd cpp     && ls)
HASKELL := $(shell cd haskell && ls)

all: init $(TARGETS:%=bin/cpp-%) $(HASKELL:%=bin/haskell-%)

init:
	@mkdir -p bin

bin/cpp-%: cpp/%/main.cpp
	g++ -o $@ $<

bin/haskell-%: haskell/%/main.hs
	ghc -o $@ $<
