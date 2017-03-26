CXX ?= g++
CXXFLAGS += -std=c++11 -Wall -ggdb3

TARGETS = vhdl_analyser vhdl_parser

FLEXFILES = $(wildcard *.l)
BISONFILES = $(wildcard *.y)
CXXFLEX = $(patsubst %.l, %_ll.cpp, $(FLEXFILES))
CXXBISON = $(patsubst %.y, %_yy.cpp, $(BISONFILES))
SOURCES = $(CXXFLEX) $(CXXBISON) $(filter-out $(patsubst %, %.cpp, $(TARGETS)),$(wildcard *.cpp))
OBJECTS = $(patsubst %.cpp, %.o, $(SOURCES))

.PHONY: all clean test

all: $(TARGETS)

%: %.cpp $(OBJECTS)
	$(CXX) $(CXXFLAGS) -o $@ $^

vhdl_analyser_bits.a: $(OBJECTS)
	ar ruv $@ $^

$(CXXFLEX): $(CXXBISON)

%_ll.cpp: %.l
	flex -o $@ $<

%_yy.cpp: %.y
	bison -v -d -o $@ $<

clean:
	rm -f $(TARGETS) *_ll.* *_yy.* *.o *.a

test: $(TARGETS) vhdl_analyser_bits.a
	./test.py
