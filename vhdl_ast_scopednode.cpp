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

#include "vhdl_ast_scopednode.h"

using namespace std;
using namespace YaVHDL::Analyser;
using namespace YaVHDL::Analyser::AST;

ScopedNode::ScopedNode() {}

void ScopedNode::AddItem(Identifier name, AbstractNode *node) {
    this->items_id.insert({{name, node}});
}

void ScopedNode::AddItem(char name, AbstractNode *node) {
    auto vec = this->items_char.find(name);
    if (vec == this->items_char.end()) {
        // Didn't exist at all
        auto new_vec = vector<AbstractNode *>();
        new_vec.push_back(node);
        this->items_char.insert({{name, new_vec}});
    } else {
        // Add a new overloaded thing
        vec->second.push_back(node);
    }
}

void ScopedNode::AddItem(string name, AbstractNode *node) {
    auto vec = this->items_str.find(name);
    if (vec == this->items_str.end()) {
        // Didn't exist at all
        auto new_vec = vector<AbstractNode *>();
        new_vec.push_back(node);
        this->items_str.insert({{name, new_vec}});
    } else {
        // Add a new overloaded thing
        vec->second.push_back(node);
    }
}

AbstractNode *ScopedNode::FindItem(Identifier name) {
    auto found_obj = this->items_id.find(name);
    if (found_obj == this->items_id.end())
        return NULL;
    return found_obj->second;
}

vector<AbstractNode *> ScopedNode::FindItem(char name) {
    auto found_obj = this->items_char.find(name);
    if (found_obj == this->items_char.end()) {
        return vector<AbstractNode *>();
    }
    return found_obj->second;
}

vector<AbstractNode *> ScopedNode::FindItem(string name) {
    auto found_obj = this->items_str.find(name);
    if (found_obj == this->items_str.end()) {
        return vector<AbstractNode *>();
    }
    return found_obj->second;
}

void ScopedNode::_DeleteScopedSubitems() {
    for (auto i = this->items_id.begin(); i != this->items_id.end(); i++) {
        delete i->second;
    }
    for (auto i = this->items_char.begin(); i != this->items_char.end(); i++) {
        for (auto j = i->second.begin(); j != i->second.end(); j++) {
            delete *j;
        }
    }
    for (auto i = this->items_str.begin(); i != this->items_str.end(); i++) {
        for (auto j = i->second.begin(); j != i->second.end(); j++) {
            delete *j;
        }
    }
}
