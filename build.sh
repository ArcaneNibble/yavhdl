#!/bin/bash

set -xeuo pipefail

cargo build
g++ -std=c++11 -Wall -ggdb3 -o vhdl_parser src/parser/demo/*.cpp
