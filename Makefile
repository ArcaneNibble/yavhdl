CXX ?= g++
CXXFLAGS += -Wall -ggdb3

TARGETS = vhdl_analyser vhdl_parser

FLEXFILES = $(wildcard *.l)
BISONFILES = $(wildcard *.y)
CFLEX = $(patsubst %.l, %_ll.c, $(FLEXFILES))
CBISON = $(patsubst %.y, %_yy.c, $(BISONFILES))
SOURCES = $(CFLEX) $(CBISON) $(filter-out $(patsubst %, %.cpp, $(TARGETS)),$(wildcard *.cpp))

.PHONY: all clean

all: $(TARGETS)

%: %.cpp $(SOURCES)
	$(CXX) $(CXXFLAGS) -o $@ $^

$(CFLEX): $(CBISON)

%_ll.c: %.l
	flex -o $@ $<

%_yy.c: %.y
	bison -v -d -o $@ $<

clean:
	rm -f $(CFLEX) $(CBISON) $(TARGETS) *_ll.* *_yy.*
