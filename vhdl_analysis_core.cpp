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
#include "vhdl_ast_enumerationtypedecl.h"
#include "vhdl_ast_isoverloadabletrait.h"

using namespace std;
using namespace YaVHDL::Analyser;
using namespace YaVHDL::Parser;

static void dump_current_location(
    VhdlParseTreeNode *pt, AnalyzerCoreStateBlob &s, bool err) {

    std::string &o = err ? *s.errors : *s.warnings;

    o += s.file_name;
    if (pt->first_line != -1) {
        o += ":";
        o += to_string(pt->first_line);
        o += ":";
        o += to_string(pt->first_column);
    }
    o += ":";
}

static void copy_line_no(AST::HasLinenoTrait *dest, VhdlParseTreeNode *src) {
    dest->first_line = src->first_line;
    dest->first_column = src->first_column;
    dest->last_line = src->last_line;
    dest->last_column = src->last_column;
}

// TODO: Move me?
static Identifier *analyze_identifier(VhdlParseTreeNode *pt) {
    switch (pt->type) {
        case PT_BASIC_ID:
            return Identifier::FromLatin1(pt->str->c_str(), false);

        case PT_EXT_ID:
            return Identifier::FromLatin1(pt->str->c_str(), true);

        default:
            assert(!"Don't know how to handle this parse tree node!");
    }
}

enum DeclarativePartType {
    ArchitectureDeclarativePart,
    BlockDeclarativePart,
    ConfigurationDeclarativePart,
    EntityDeclarativePart,
    GenerateStatementBody,
    PackageBodyDeclarativePart,
    PackageDeclarativePart,
    ProcessDeclarativePart,
    ProtectedTypeDeclarativePart,
    ProtectedTypeBodyDeclarativePart,
    SubprogramDeclarativePart,
};

static bool try_add_declaration(Identifier id, AST::AbstractNode *n,
    ScopeTrait *tgt) {

    auto existing = tgt->FindItem(id);
    if (existing.size() == 0) {
        // We are adding a new thing; this should always work
        tgt->AddItem(id, n);
        return true;
    } else {
        // Are the existing things overloadable? (Must always be the same)
        bool existing_overloadable = false;
        AST::IsOverloadableTrait *x =
            dynamic_cast<AST::IsOverloadableTrait *>(existing[0]);
        if (x) {
            existing_overloadable = true;
        }

        bool this_overloadable = false;
        x = dynamic_cast<AST::IsOverloadableTrait *>(n);
        if (x) {
            this_overloadable = true;
        }

        // TODO: Implicit declarations?

        if (!(existing_overloadable == true && this_overloadable == true)) {
            // Definitely fail
            return false;
        } else {
            // Both are overloadable
            // TODO: Type profile
            tgt->AddItem(id, n);
            return true;
        }
    }
}

static bool analyze_type_decl(VhdlParseTreeNode *pt, ScopeTrait *tgt,
    DeclarativePartType type, AnalyzerCoreStateBlob &s) {

    Identifier *type_name = analyze_identifier(pt->pieces[0]);
    
    switch(pt->pieces[1]->type) {
        case PT_ENUMERATION_TYPE_DEFINITION: {
            std::cout << "-----asdfasdf-----\n";

            AST::EnumerationTypeDecl *d = new AST::EnumerationTypeDecl();
            copy_line_no(d, pt);
            d->id = type_name;

            if (!try_add_declaration(*type_name, d, tgt)) {
                dump_current_location(pt, s, true);
                *s.errors += "ERROR: Duplicate declaration of type ";
                *s.errors += type_name->pretty_name;
                *s.errors += "!\n";
                delete d;
                return false;
            }

            // TODO

            break;
        }
        default:
            assert(!"Don't know how to handle this parse tree node!");
    }

    return true;
}

static bool analyze_declarative_item(VhdlParseTreeNode *pt, ScopeTrait *tgt,
    DeclarativePartType type, AnalyzerCoreStateBlob &s) {

    switch(pt->type) {
        case PT_FULL_TYPE_DECLARATION:
            return analyze_type_decl(pt, tgt, type, s);

        default:
            assert(!"Don't know how to handle this parse tree node!");
    }
};

static bool analyze_declaration_list(VhdlParseTreeNode *pt, ScopeTrait *tgt,
    DeclarativePartType type, AnalyzerCoreStateBlob &s) {

    bool no_errors = true;

    switch (pt->type) {
        case PT_DECLARATION_LIST:
            no_errors &= analyze_declaration_list(pt->pieces[0], tgt, type, s);
            no_errors &= analyze_declarative_item(pt->pieces[1], tgt, type, s);
            break;

        default:
            no_errors &= analyze_declarative_item(pt, tgt, type, s);
            break;
    }

    return no_errors;
}

static AST::Entity *analyze_entity(
    VhdlParseTreeNode *pt, AnalyzerCoreStateBlob &s) {

    AST::Entity *ret = new AST::Entity();

    // Location information
    copy_line_no(ret, pt);
    ret->file_name = s.file_name;

    // Our name
    ret->id = analyze_identifier(pt->pieces[0]);

    AST::AbstractNode *old_node;
    if ((old_node = s.work_lib->FindDesignUnit(*ret->id))) {

        dump_current_location(pt, s, true);
        *s.errors += "ERROR: Design unit ";
        *s.errors += ret->id->pretty_name;
        *s.errors += " already exists in library!\n";

        AST::HasLinenoTrait *old_node_;
        if ((old_node_ = dynamic_cast<AST::HasLinenoTrait *>(old_node))) {
            *s.errors += "\tPrevious version was at ";
            old_node_->FormatLocIntoString(*s.errors);
            *s.errors += "\n";
        }

        // FIXME: We're expected to take ownership of the root declarative
        // region, so now we need to free it.
        delete s.innermost_scope;
        delete ret;
        return nullptr;
    }

    s.work_lib->TentativeAddDesignUnit(*ret->id, ret);

    // Store the given root declarative region (owned by entity)
    ret->root_decl_region = s.innermost_scope;

    // Verify that the id at the end (if any) is the same as the one in the
    // beginning
    if (pt->pieces[4]) {
        Identifier *tail_id = analyze_identifier(pt->pieces[4]);
        if (tail_id != ret->id) {
            dump_current_location(pt, s, true);
            *s.errors +=
                "ERROR: Name at end of entity must match name at beginning\n";
            s.work_lib->DropTentativeDesignUnit();
            return nullptr;
        }
    }

    // TODO

    // Declarations
    if (pt->pieces[2]) {
        bool no_errors = analyze_declaration_list(
            pt->pieces[2], ret, EntityDeclarativePart, s);
        if (!no_errors) {
            s.work_lib->DropTentativeDesignUnit();
            return nullptr;
        }
    }

    // Add the thing we analyzed to the library for real
    s.work_lib->CommitTentativeDesignUnit();

    return ret;
}

// Analyzes PT_DESIGN_UNIT
static bool analyze_design_unit(
    VhdlParseTreeNode *pt, AnalyzerCoreStateBlob &s) {

    // Root declarative region
    ScopeChainNode *root_decl_region = new ScopeChainNode();
    s.innermost_scope = root_decl_region;

    // Not implemented
    assert(pt->pieces[1] == nullptr);

    switch (pt->pieces[0]->type) {
        case PT_ENTITY: {
            AST::Entity *entity = analyze_entity(pt->pieces[0], s);
            if (!entity) return false;
            break;
        }

        default:
            assert(!"Don't know how to handle this parse tree node!");
    }

    return true;
}

// Analyzes PT_DESIGN_FILE or PT_DESIGN_UNIT
static bool analyze_design_file(
    VhdlParseTreeNode *pt, AnalyzerCoreStateBlob &s) {

    bool no_errors = true;

    switch (pt->type) {
        case PT_DESIGN_UNIT:
            no_errors &= analyze_design_unit(pt, s);
            break;

        case PT_DESIGN_FILE:
            no_errors &= analyze_design_file(pt->pieces[0], s);
            no_errors &= analyze_design_unit(pt->pieces[1], s);
            break;

        default:
            assert(!"Don't know how to handle this parse tree node!");
    }

    return no_errors;
}

bool YaVHDL::Analyser::do_vhdl_analysis(
    YaVHDL::Analyser::DesignDatabase *design_db,
    YaVHDL::Analyser::Library *work_lib,
    YaVHDL::Parser::VhdlParseTreeNode *pt,
    std::string &errors,
    std::string &warnings,
    std::string file_name) {

    AnalyzerCoreStateBlob state;
    state.design_db = design_db;
    state.work_lib = work_lib;
    state.errors = &errors;
    state.warnings = &warnings;
    state.file_name = file_name;
    state.innermost_scope = nullptr;

    return analyze_design_file(pt, state);
}
