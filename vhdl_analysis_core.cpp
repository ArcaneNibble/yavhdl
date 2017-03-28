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

#include "vhdl_analysis_core.h"

#include <cassert>
#include <iostream>

#include "vhdl_ast_entity.h"

using namespace std;
using namespace YaVHDL::Analyser;
using namespace YaVHDL::Parser;

Identifier *analyze_identifier(VhdlParseTreeNode *pt) {
    switch (pt->type) {
        case PT_BASIC_ID:
            return Identifier::FromLatin1(pt->str->c_str(), false);

        case PT_EXT_ID:
            return Identifier::FromLatin1(pt->str->c_str(), true);

        default:
            assert(!"Don't know how to handle this parse tree node!");
    }
}

AST::Entity *analyze_entity(
    DesignDatabase *design_db, Library *work_lib, VhdlParseTreeNode *pt,
    std::string &errors, std::string &warnings) {

    AST::Entity *ret = new AST::Entity();

    ret->id = analyze_identifier(pt->pieces[0]);

    // TODO

    return ret;
}

// Analyzes PT_DESIGN_UNIT
static bool analyze_design_unit(
    DesignDatabase *design_db, Library *work_lib, VhdlParseTreeNode *pt,
    std::string &errors, std::string &warnings) {

    // Not implemented
    assert(pt->pieces[1] == nullptr);

    AST::AbstractNode *node_to_add;
    Identifier *name_of_node;

    switch (pt->pieces[0]->type) {
        case PT_ENTITY: {
            AST::Entity *entity = analyze_entity(
                design_db, work_lib, pt->pieces[0], errors, warnings);
            node_to_add = entity;
            name_of_node = entity->id;
            break;
        }

        default:
            assert(!"Don't know how to handle this parse tree node!");
    }

    if (work_lib->FindDesignUnit(*name_of_node)) {
        errors += "ERROR: Design unit ";
        errors += name_of_node->pretty_name;
        errors += " already exists!";
        return false;
    }

    // Add the thing we analyzed to the library
    work_lib->AddDesignUnit(*name_of_node, node_to_add);

    return true;
}

// Analyzes PT_DESIGN_FILE or PT_DESIGN_UNIT
bool do_vhdl_analysis(
    YaVHDL::Analyser::DesignDatabase *design_db,
    YaVHDL::Analyser::Library *work_lib,
    YaVHDL::Parser::VhdlParseTreeNode *pt,
    std::string &errors,
    std::string &warnings) {

    bool no_errors = true;

    switch (pt->type) {
        case PT_DESIGN_UNIT:
            no_errors &= analyze_design_unit(
                design_db, work_lib, pt, errors, warnings);
            break;

        case PT_DESIGN_FILE:
            no_errors &= do_vhdl_analysis(
                design_db, work_lib, pt->pieces[0], errors, warnings);
            no_errors &= analyze_design_unit(
                design_db, work_lib, pt->pieces[1], errors, warnings);
            break;

        default:
            assert(!"Don't know how to handle this parse tree node!");
    }

    return no_errors;
}
