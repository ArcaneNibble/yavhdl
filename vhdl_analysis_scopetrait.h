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

#ifndef VHDL_ANALYSIS_SCOPETRAIT_H
#define VHDL_ANALYSIS_SCOPETRAIT_H

#include <string>
#include <unordered_map>
#include <vector>

#include "vhdl_analysis_identifier.h"
#include "vhdl_ast_abstractnode.h"

namespace YaVHDL::Analyser
{

// We use this to implement the shared functionality for an object that can be
// a scope and can contain internal objects. Note that here we are using the
// word "scope" in its "traditional" sense of "a region that can enclose a
// number of names that refer to objects" rather than the "VHDL" sense of
// "a region that the name of an object exists in." The definition we are
// using here is what VHDL calls a "declarative region." Note that character
// literals and string literals can be overloaded and thus return a list.
// However, identifiers cannot be overloaded.
class ScopeTrait {
public:
    virtual void AddItem(Identifier name, AST::AbstractNode *node);
    virtual void AddItem(char name, AST::AbstractNode *node);
    virtual void AddItem(std::string name, AST::AbstractNode *node);

    virtual AST::AbstractNode *FindItem(Identifier name);
    virtual std::vector<AST::AbstractNode *> FindItem(char name);
    virtual std::vector<AST::AbstractNode *> FindItem(std::string name);

protected:
    // We don't want to make this constructable by itself, but we have no
    // pure virtual methods so we make the constructor protected instead.
    ScopeTrait();

    std::unordered_map<Identifier, AST::AbstractNode *> items_id;
    std::unordered_map<char, std::vector<AST::AbstractNode *>> items_char;
    std::unordered_map<std::string, std::vector<AST::AbstractNode *>> items_str;

    // Whether or not this item owns its children depends on where it is used.
    // For most of the AST nodes, it will own its children, and so derived
    // classes need to call this. However, if (when?) this gets used to
    // implement scope chains, scope chains do _not_ own their items so this
    // function MUST NOT be called.
    void _DeleteScopedSubitems();
};

}

#endif
