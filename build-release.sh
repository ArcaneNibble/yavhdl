#!/bin/bash

set -xeuo pipefail

# Bison part (including glue)
mkdir -p build
cd build
bison -v -d -o vhdl_parser_yy.cpp ../src/parser/bison/vhdl_parser.y
flex -o vhdl_lexer_ll.cpp ../src/parser/bison/vhdl_lexer.l
g++ -std=c++11 -Wall -ggdb3 -O2 -c -I ../src/parser/bison -I . vhdl_parser_yy.cpp
g++ -std=c++11 -Wall -ggdb3 -O2 -c -I ../src/parser/bison -I . vhdl_lexer_ll.cpp

g++ -std=c++11 -Wall -ggdb3 -O2 -c -I ../src/parser/bison -I . ../src/parser/bison/vhdl_parse_tree.cpp
g++ -std=c++11 -Wall -ggdb3 -O2 -c -I ../src/parser/bison -I . ../src/parser/bison/vhdl_parser_glue.cpp
g++ -std=c++11 -Wall -ggdb3 -O2 -c -I ../src/parser/bison -I . ../src/parser/bison/util.cpp

ar rcs libyavhdl_bison.a *.o
cd ..

# Rust part
cargo build --release

# Demo parts
ln -sf target/release/vhdl_parser
ln -sf target/release/vhdl_analyzer

strip -s -o vhdl_parser_stripped vhdl_parser
strip -s -o vhdl_analyzer_stripped vhdl_analyzer
