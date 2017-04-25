/*
Copyright (c) 2016-2017, Robert Ou <rqou@robertou.com>
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
   this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#include "vhdl_ast_haslinenotrait.h"

#include <iostream>
#include "util.h"

using namespace YaVHDL::Analyser::AST;

HasLinenoTrait::HasLinenoTrait() {
    this->first_line = -1;
    this->first_column = -1;
    this->last_line = -1;
    this->last_column = -1;
}

void HasLinenoTrait::FormatLocIntoString(std::string &s) {
    s += this->file_name;
    s += ":";
    s += std::to_string(this->first_line);
    s += ":";
    s += std::to_string(this->first_column);
}

void HasLinenoTrait::debug_print_lineno() {
    std::cout << ", \"first_line\": ";
    std::cout << this->first_line;
    std::cout << ", \"first_column\": ";
    std::cout << this->first_column;
    std::cout << ", \"last_line\": ";
    std::cout << this->last_line;
    std::cout << ", \"last_column\": ";
    std::cout << this->last_column;

    if (this->file_name.length()) {
        std::cout << ", \"file_name\": \"";
        YaVHDL::Util::print_string_escaped(&this->file_name);
        std::cout << "\"";
    }
}
