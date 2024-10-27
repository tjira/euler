.PHONY: all clean

CPP     := $(shell cd cpp     && ls)
HASKELL := $(shell cd haskell && ls)
PYTHON  := $(shell cd python  && ls)

all: init $(TARGETS:%=bin/cpp-%) $(HASKELL:%=bin/haskell-%) $(PYTHON:%=bin/python-%)

init:
	@mkdir -p bin

bin/cpp-%: cpp/%/main.cpp
	g++ -o $@ $<

bin/haskell-%: haskell/%/main.hs
	ghc -o $@ $<

bin/python-%: python/%/main.py
	cp $< $@
