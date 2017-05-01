#!/bin/bash

set -xeuo pipefail

# Bison part (including glue)
mkdir -p build
cd build
bison -v -d -o vhdl_parser_yy.cpp ../src/parser/bison/vhdl_parser.y
flex -o vhdl_lexer_ll.cpp ../src/parser/bison/vhdl_lexer.l
g++ -std=c++11 -Wall -ggdb3 -c -I ../src/parser/bison -I . vhdl_parser_yy.cpp
g++ -std=c++11 -Wall -ggdb3 -c -I ../src/parser/bison -I . vhdl_lexer_ll.cpp

g++ -std=c++11 -Wall -ggdb3 -c -I ../src/parser/bison -I . ../src/parser/bison/vhdl_parse_tree.cpp
g++ -std=c++11 -Wall -ggdb3 -c -I ../src/parser/bison -I . ../src/parser/bison/vhdl_parser_glue.cpp
g++ -std=c++11 -Wall -ggdb3 -c -I ../src/parser/bison -I . ../src/parser/bison/util.cpp

ar rcs yavhdl_bison.a *.o
cd ..

# Rust part
cargo build

# Demo parts (proving the C interface works)
g++ -std=c++11 -Wall -ggdb3 -I src/parser/bison -I build -o vhdl_parser src/parser/demo/*.cpp build/yavhdl_bison.a
