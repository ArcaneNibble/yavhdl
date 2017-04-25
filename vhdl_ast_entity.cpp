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

#include "vhdl_ast_entity.h"

#include <iostream>

using namespace YaVHDL::Analyser;
using namespace YaVHDL::Analyser::AST;

Entity::~Entity() {
    delete this->id;
    delete this->root_decl_region;
    this->_DeleteScopedSubitems();
}

void Entity::debug_print() {
    std::cout << "{\"type\": \"Entity\"";

    std::cout << ", \"id\": ";
    this->id->debug_print();

    this->debug_print_lineno();

    std::cout << ", \"decls\": [";
    std::cout << "\"__is_a_set\"";
    for (auto i = this->items_id.begin(); i != this->items_id.end(); i++) {
        for (auto j = i->second.begin(); j != i->second.end(); j++) {
            std::cout << ",";
            (*j)->debug_print();
        }
    }
    for (auto i = this->items_char.begin(); i != this->items_char.end(); i++) {
        for (auto j = i->second.begin(); j != i->second.end(); j++) {
            std::cout << ",";
            (*j)->debug_print();
        }
    }
    for (auto i = this->items_str.begin(); i != this->items_str.end(); i++) {
        for (auto j = i->second.begin(); j != i->second.end(); j++) {
            std::cout << ",";
            (*j)->debug_print();
        }
    }
    std::cout << "]";

    std::cout << "}";
}
