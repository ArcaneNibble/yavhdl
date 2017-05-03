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

ar rcs libyavhdl_bison.a *.o
cd ..

# Rust part
cargo build

# Demo parts
ln -sf target/debug/vhdl_parser
ln -sf target/debug/vhdl_analyzer
