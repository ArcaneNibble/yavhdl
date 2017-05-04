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

// GLR parser for (hopefully) all of VHDL. The parser should not actually
// require GLR, but it is definitely LR(k > 1). A TODO item is to fix this.
// This parser accepts a subset of what is permitted by the IEEE 1076-2008
// EBNF, but it should accept a superset of what is permitted by the
// combination of the EBNF and the semantic rules. Most of the difficultly
// lies in the "name" and "subtype_indication" rules.

// One of the design decisions in this parser was to have absolutely as little
// logic and processing in the Bison grammar as possible. This was done in the
// hopes that it makes it easier to ever reuse this grammar file in tools other
// than Bison. This is the reason why the parser e.g. returns nested node
// objects rather than a list object.

%{

#include <string>

#define VHDL_PARSER_IN_BISON
#include "vhdl_parser_glue.h"

// We seem to easily blow the parser stack in GLR mode, so set the maximum
// stack depth to something huge.
#define YYMAXDEPTH 10000000

// This macro stores line numbering information into the semantic value.
#define STORE_LOC(lval, lloc) do {              \
    lval->first_line = lloc.first_line;         \
    lval->first_column = lloc.first_column + 1; \
    lval->last_line = lloc.last_line;           \
    lval->last_column = lloc.last_column + 1;   \
} while(0)

%}

%name-prefix "frontend_vhdl_yy"

// Make the parser reentrant
%define api.pure
%lex-param {void *scanner} {std::string &errors}
    {std::set<VhdlParseTreeNode *> &to_delete_queue}
%parse-param {void *scanner} {VhdlParseTreeNode **parse_output}
    {std::string &errors} {std::set<VhdlParseTreeNode *> &to_delete_queue}
%locations

%glr-parser

// We get a decent number of "mysterious conflicts" the way the grammar is
// currently structured (mostly due to type_mark). IELR mode cuts down on
// conflicts significantly.
// FIXME: Explain where exactly conflicts come from.
%define lr.type ielr
%define parse.error verbose
%debug

%define api.value.type {struct VhdlParseTreeNode *}

%destructor {
    if ($$) {
        if (!(*parse_output) || $$ != *parse_output) {
            to_delete_queue.insert($$);
        }
    }
} <>

//////////////////////// Reserved words, section 15.10 ////////////////////////

%token KW_ABS
%token KW_ACCESS
%token KW_AFTER
%token KW_ALIAS
%token KW_ALL
%token KW_AND
%token KW_ARCHITECTURE
%token KW_ARRAY
%token KW_ASSERT
%token KW_ASSUME
%token KW_ASSUME_GUARANTEE
%token KW_ATTRIBUTE
%token KW_BEGIN
%token KW_BLOCK
%token KW_BODY
%token KW_BUFFER
%token KW_BUS
%token KW_CASE
%token KW_COMPONENT
%token KW_CONFIGURATION
%token KW_CONSTANT
%token KW_CONTEXT
%token KW_COVER
%token KW_DEFAULT
%token KW_DISCONNECT
%token KW_DOWNTO
%token KW_ELSE
%token KW_ELSIF
%token KW_END
%token KW_ENTITY
%token KW_EXIT
%token KW_FAIRNESS
%token KW_FILE
%token KW_FOR
%token KW_FORCE
%token KW_FUNCTION
%token KW_GENERATE
%token KW_GENERIC
%token KW_GROUP
%token KW_GUARDED
%token KW_IF
%token KW_IMPURE
%token KW_IN
%token KW_INERTIAL
%token KW_INOUT
%token KW_IS
%token KW_LABEL
%token KW_LIBRARY
%token KW_LINKAGE
%token KW_LITERAL
%token KW_LOOP
%token KW_MAP
%token KW_MOD
%token KW_NAND
%token KW_NEW
%token KW_NEXT
%token KW_NOR
%token KW_NOT
%token KW_NULL
%token KW_OF
%token KW_ON
%token KW_OPEN
%token KW_OR
%token KW_OTHERS
%token KW_OUT
%token KW_PACKAGE
%token KW_PARAMETER
%token KW_PORT
%token KW_POSTPONED
%token KW_PROCEDURE
%token KW_PROCESS
%token KW_PROPERTY
%token KW_PROTECTED
%token KW_PURE
%token KW_RANGE
%token KW_RECORD
%token KW_REGISTER
%token KW_REJECT
%token KW_RELEASE
%token KW_REM
%token KW_REPORT
%token KW_RESTRICT
%token KW_RESTRICT_GUARANTEE
%token KW_RETURN
%token KW_ROL
%token KW_ROR
%token KW_SELECT
%token KW_SEQUENCE
%token KW_SEVERITY
%token KW_SHARED
%token KW_SIGNAL
%token KW_SLA
%token KW_SLL
%token KW_SRA
%token KW_SRL
%token KW_STRONG
%token KW_SUBTYPE
%token KW_THEN
%token KW_TO
%token KW_TRANSPORT
%token KW_TYPE
%token KW_UNAFFECTED
%token KW_UNITS
%token KW_UNTIL
%token KW_USE
%token KW_VARIABLE
%token KW_VMODE
%token KW_VPROP
%token KW_VUNIT
%token KW_WAIT
%token KW_WHEN
%token KW_WHILE
%token KW_WITH
%token KW_XNOR
%token KW_XOR

////////////////// Multi-character delimiters, section 15.3 //////////////////

%token DL_ARR
%token DL_EXP
%token DL_ASS
%token DL_NEQ
%token DL_GEQ
%token DL_LEQ
%token DL_BOX
%token DL_QQ
%token DL_MEQ
%token DL_MNE
%token DL_MLT
%token DL_MLE
%token DL_MGT
%token DL_MGE
%token DL_LL
%token DL_RR

//////////////// Miscellaneous tokens for other lexer literals ////////////////

%token TOK_STRING
%token TOK_BITSTRING
%token TOK_DECIMAL
%token TOK_BASED
%token TOK_CHAR
%token TOK_BASIC_ID
%token TOK_EXT_ID

// This token is used to report lexer errors
%token LEXER_ERROR

%%

// Start token used for saving the parse tree
_toplevel_token:
    design_file { *parse_output = $1; }

//////////////// Design entities and configurations, section 3 ////////////////

/// Section 3.2
entity_declaration:
    _real_entity_declaration ';'
    | _real_entity_declaration KW_ENTITY ';'
    | _real_entity_declaration identifier ';' {
        $$ = $1;
        $$->pieces[4] = $2;
    }
    | _real_entity_declaration KW_ENTITY identifier ';' {
        $$ = $1;
        $$->pieces[4] = $3;
    }

_real_entity_declaration:
    KW_ENTITY identifier KW_IS entity_header entity_declarative_part KW_END {
        $$ = new VhdlParseTreeNode(PT_ENTITY);
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
        $$->pieces[2] = $5;
        $$->pieces[3] = nullptr;
        $$->pieces[4] = nullptr;
    }
    | KW_ENTITY identifier KW_IS entity_header entity_declarative_part
      KW_BEGIN entity_statement_part KW_END {
        $$ = new VhdlParseTreeNode(PT_ENTITY);
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
        $$->pieces[2] = $5;
        $$->pieces[3] = $7;
        $$->pieces[4] = nullptr;
    }

/// Section 3.2.2
entity_header:
    %empty {
        $$ = new VhdlParseTreeNode(PT_ENTITY_HEADER);
        $$->pieces[0] = nullptr;
        $$->pieces[1] = nullptr;
    }
    | KW_GENERIC '(' interface_list ')' ';' {
        $$ = new VhdlParseTreeNode(PT_ENTITY_HEADER);
        $$->pieces[0] = $3;
        $$->pieces[1] = nullptr;
    }
    | KW_PORT '(' interface_list ')' ';' {
        $$ = new VhdlParseTreeNode(PT_ENTITY_HEADER);
        $$->pieces[0] = nullptr;
        $$->pieces[1] = $3;
    }
    | KW_GENERIC '(' interface_list ')' ';'
      KW_PORT '(' interface_list ')' ';' {
        $$ = new VhdlParseTreeNode(PT_ENTITY_HEADER);
        $$->pieces[0] = $3;
        $$->pieces[1] = $8;
    }

/// Section 3.2.3
entity_declarative_part:
    %empty
    | _real_entity_declarative_part

_real_entity_declarative_part:
    entity_declarative_item
    | _real_entity_declarative_part entity_declarative_item {
        $$ = new VhdlParseTreeNode(PT_DECLARATION_LIST);
        $$->pieces[0] = $1;
        $$->pieces[1] = $2;
    }

// Store line number information
entity_declarative_item: _entity_declarative_item { STORE_LOC($$, @$); }

_entity_declarative_item:
    subprogram_declaration
    | subprogram_body
    | subprogram_instantiation_declaration
    | package_declaration
    | package_body
    | package_instantiation_declaration
    | type_declaration
    | subtype_declaration
    | constant_declaration
    | signal_declaration
    | variable_declaration
    | file_declaration
    | alias_declaration
    | attribute_declaration
    | attribute_specification
    | disconnection_specification
    | use_clause
    | group_template_declaration
    | group_declaration

/// Section 3.2.4
entity_statement_part:
    %empty
    | _real_entity_statement_part

// We need this or else the %empty can cause ambiguity.
_real_entity_statement_part:
    entity_statement
    | _real_entity_statement_part entity_statement {
        $$ = new VhdlParseTreeNode(PT_SEQUENCE_OF_STATEMENTS);
        $$->pieces[0] = $1;
        $$->pieces[1] = $2;
    }

entity_statement:
    concurrent_assertion_statement
    | concurrent_procedure_call_statement
    | process_statement

/// Section 3.3.1
architecture_body:
    _real_architecture_body ';'
    | _real_architecture_body KW_ARCHITECTURE ';'
    | _real_architecture_body identifier ';' {
        $$ = $1;
        $$->pieces[4] = $2;
    }
    | _real_architecture_body KW_ARCHITECTURE identifier ';' {
        $$ = $1;
        $$->pieces[4] = $3;
    }

_real_architecture_body:
    KW_ARCHITECTURE identifier KW_OF _simple_or_selected_name KW_IS
    block_declarative_part KW_BEGIN _sequence_of_concurrent_statements
    KW_END {
        $$ = new VhdlParseTreeNode(PT_ARCHITECTURE);
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
        $$->pieces[2] = $6;
        $$->pieces[3] = $8;
        $$->pieces[4] = nullptr;
    }

/// Section 3.3.2
// Store line number information
block_declarative_item: _block_declarative_item { STORE_LOC($$, @$); }

_block_declarative_item:
    subprogram_declaration
    | subprogram_body
    | subprogram_instantiation_declaration
    | package_declaration
    | package_body
    | package_instantiation_declaration
    | type_declaration
    | subtype_declaration
    | constant_declaration
    | signal_declaration
    | variable_declaration
    | file_declaration
    | alias_declaration
    | component_declaration
    | attribute_declaration
    | attribute_specification
    | configuration_specification
    | disconnection_specification
    | use_clause
    | group_template_declaration
    | group_declaration

/// Section 3.4.1
configuration_declaration:
    _real_configuration_declaration ';'
    | _real_configuration_declaration KW_CONFIGURATION ';'
    | _real_configuration_declaration identifier ';' {
        $$ = $1;
        $$->pieces[5] = $2;
    }
    | _real_configuration_declaration KW_CONFIGURATION identifier ';' {
        $$ = $1;
        $$->pieces[5] = $3;
    }

_real_configuration_declaration:
    KW_CONFIGURATION identifier KW_OF _simple_or_selected_name KW_IS
    configuration_declarative_part
    _zero_or_more_verification_unit_binding_indications
    block_configuration KW_END {
        $$ = new VhdlParseTreeNode(PT_CONFIGURATION_DECLARATION);
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
        $$->pieces[2] = $6;
        $$->pieces[3] = $7;
        $$->pieces[4] = $8;
        $$->pieces[5] = nullptr;
    }

_zero_or_more_verification_unit_binding_indications:
    %empty
    | _one_or_more_verification_unit_binding_indications

configuration_declarative_part:
    %empty
    | _real_configuration_declarative_part

_real_configuration_declarative_part:
    configuration_declarative_item
    | _real_configuration_declarative_part configuration_declarative_item {
        $$ = new VhdlParseTreeNode(PT_DECLARATION_LIST);
        $$->pieces[0] = $1;
        $$->pieces[1] = $2;
    }

// Store line number information
configuration_declarative_item:
    _configuration_declarative_item { STORE_LOC($$, @$); }

_configuration_declarative_item:
    use_clause
    | attribute_specification
    | group_declaration

/// Section 3.4.2
block_configuration:
    KW_FOR block_specification _zero_or_more_use_clauses
    _zero_or_more_configuration_items KW_END KW_FOR ';' {
        $$ = new VhdlParseTreeNode(PT_BLOCK_CONFIGURATION);
        $$->pieces[0] = $2;
        $$->pieces[1] = $3;
        $$->pieces[2] = $4;
    }

block_specification:
    _simple_or_selected_name {
        $$ = new VhdlParseTreeNode(PT_BLOCK_SPECIFICATION);
        $$->pieces[0] = $1;
    }
    | _simple_or_selected_name '(' generate_specification ')' {
        $$ = new VhdlParseTreeNode(PT_BLOCK_SPECIFICATION);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

generate_specification:
    _almost_discrete_range
    | expression
    // label is included in expression

configuration_item:
    block_configuration
    | component_configuration

_zero_or_more_use_clauses:
    %empty
    | _one_or_more_use_clauses

_one_or_more_use_clauses:
    use_clause
    | _one_or_more_use_clauses use_clause {
        $$ = new VhdlParseTreeNode(PT_USE_CLAUSE_LIST);
        $$->pieces[0] = $1;
        $$->pieces[1] = $2;
    }

_zero_or_more_configuration_items:
    %empty
    | _one_or_more_configuration_items

_one_or_more_configuration_items:
    configuration_item
    | _one_or_more_configuration_items configuration_item {
        $$ = new VhdlParseTreeNode(PT_CONFIGURATION_ITEM_LIST);
        $$->pieces[0] = $1;
        $$->pieces[1] = $2;
    }

/// Section 3.4.3
component_configuration:
    KW_FOR component_specification
    _zero_or_more_verification_unit_binding_indications KW_END KW_FOR ';' {
        $$ = new VhdlParseTreeNode(PT_COMPONENT_CONFIGURATION);
        $$->pieces[0] = $2;
        $$->pieces[1] = nullptr;
        $$->pieces[2] = $3;
        $$->pieces[3] = nullptr;
    }
    | KW_FOR component_specification binding_indication ';'
      _zero_or_more_verification_unit_binding_indications KW_END KW_FOR ';' {
        $$ = new VhdlParseTreeNode(PT_COMPONENT_CONFIGURATION);
        $$->pieces[0] = $2;
        $$->pieces[1] = $3;
        $$->pieces[2] = $5;
        $$->pieces[3] = nullptr;
    }
    | KW_FOR component_specification
      _zero_or_more_verification_unit_binding_indications
      block_configuration KW_END KW_FOR ';' {
        $$ = new VhdlParseTreeNode(PT_COMPONENT_CONFIGURATION);
        $$->pieces[0] = $2;
        $$->pieces[1] = nullptr;
        $$->pieces[2] = $3;
        $$->pieces[3] = $4;
    }
    | KW_FOR component_specification binding_indication ';'
      _zero_or_more_verification_unit_binding_indications
      block_configuration KW_END KW_FOR ';' {
        $$ = new VhdlParseTreeNode(PT_COMPONENT_CONFIGURATION);
        $$->pieces[0] = $2;
        $$->pieces[1] = $3;
        $$->pieces[2] = $5;
        $$->pieces[3] = $6;
    }

///////////////////// Subprograms and packages, section 4 /////////////////////

/// Section 4.2
subprogram_declaration:
    subprogram_specification ';' {
        $$ = new VhdlParseTreeNode(PT_SUBPROGRAM_DECLARATION);
        $$->pieces[0] = $1;
    }

subprogram_specification:
    procedure_specification
    | function_specification

procedure_specification:
    KW_PROCEDURE designator subprogram_header {
        $$ = new VhdlParseTreeNode(PT_PROCEDURE_SPECIFICATION);
        $$->pieces[0] = $2;
        $$->pieces[1] = $3;
    }
    | KW_PROCEDURE designator subprogram_header '(' interface_list ')' {
        $$ = new VhdlParseTreeNode(PT_PROCEDURE_SPECIFICATION);
        $$->pieces[0] = $2;
        $$->pieces[1] = $3;
        $$->pieces[2] = $5;
    }
    | KW_PROCEDURE designator subprogram_header
      KW_PARAMETER '(' interface_list ')' {
        $$ = new VhdlParseTreeNode(PT_PROCEDURE_SPECIFICATION);
        $$->pieces[0] = $2;
        $$->pieces[1] = $3;
        $$->pieces[2] = $6;
    }

function_specification:
    _real_function_specification
    | KW_PURE _real_function_specification {
        $$ = $2;
        $$->purity = PURITY_PURE;
    }
    | KW_IMPURE _real_function_specification {
        $$ = $2;
        $$->purity = PURITY_IMPURE;
    }

_real_function_specification:
    KW_FUNCTION designator subprogram_header KW_RETURN type_mark {
        $$ = new VhdlParseTreeNode(PT_FUNCTION_SPECIFICATION);
        $$->purity = PURITY_UNSPEC;
        $$->pieces[0] = $2;
        $$->pieces[1] = $5;
        $$->pieces[2] = $3;
    }
    | KW_FUNCTION designator subprogram_header '(' interface_list ')'
      KW_RETURN type_mark {
        $$ = new VhdlParseTreeNode(PT_FUNCTION_SPECIFICATION);
        $$->purity = PURITY_UNSPEC;
        $$->pieces[0] = $2;
        $$->pieces[1] = $8;
        $$->pieces[2] = $3;
        $$->pieces[3] = $5;
    }
    | KW_FUNCTION designator subprogram_header
      KW_PARAMETER '(' interface_list ')' KW_RETURN type_mark {
        $$ = new VhdlParseTreeNode(PT_FUNCTION_SPECIFICATION);
        $$->purity = PURITY_UNSPEC;
        $$->pieces[0] = $2;
        $$->pieces[1] = $9;
        $$->pieces[2] = $3;
        $$->pieces[3] = $6;
    }

subprogram_header:
    %empty
    | KW_GENERIC '(' interface_list ')' {
        $$ = new VhdlParseTreeNode(PT_SUBPROGRAM_HEADER);
        $$->pieces[0] = $3;
        $$->pieces[1] = nullptr;
    }
    | generic_map_aspect {
        $$ = new VhdlParseTreeNode(PT_SUBPROGRAM_HEADER);
        $$->pieces[0] = nullptr;
        $$->pieces[1] = $1;
    }
    | KW_GENERIC '(' interface_list ')' generic_map_aspect {
        $$ = new VhdlParseTreeNode(PT_SUBPROGRAM_HEADER);
        $$->pieces[0] = $3;
        $$->pieces[1] = $5;
    }

designator:
    identifier
    | string_literal    // was operator_symbol

/// Section 4.3
subprogram_body:
    _real_subprogram_body ';'
    | _real_subprogram_body KW_FUNCTION ';' {
        $$ = $1;
        $$->subprogram_kind = SUBPROGRAM_FUNCTION;
    }
    | _real_subprogram_body KW_PROCEDURE ';' {
        $$ = $1;
        $$->subprogram_kind = SUBPROGRAM_PROCEDURE;
    }
    | _real_subprogram_body designator ';' {
        $$ = $1;
        $$->pieces[3] = $2;
    }
    | _real_subprogram_body KW_FUNCTION designator ';' {
        $$ = $1;
        $$->subprogram_kind = SUBPROGRAM_FUNCTION;
        $$->pieces[3] = $3;
    }
    | _real_subprogram_body KW_PROCEDURE designator ';' {
        $$ = $1;
        $$->subprogram_kind = SUBPROGRAM_PROCEDURE;
        $$->pieces[3] = $3;
    }

_real_subprogram_body:
    subprogram_specification KW_IS subprogram_declarative_part
    KW_BEGIN sequence_of_statements KW_END {
        $$ = new VhdlParseTreeNode(PT_SUBPROGRAM_BODY);
        $$->subprogram_kind = SUBPROGRAM_UNSPEC;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
        $$->pieces[2] = $5;
        $$->pieces[3] = nullptr;
    }

subprogram_declarative_part:
    %empty
    | _real_subprogram_declarative_part

_real_subprogram_declarative_part:
    subprogram_declarative_item
    | _real_subprogram_declarative_part subprogram_declarative_item {
        $$ = new VhdlParseTreeNode(PT_DECLARATION_LIST);
        $$->pieces[0] = $1;
        $$->pieces[1] = $2;
    }

// Store line number information
subprogram_declarative_item:
    _subprogram_declarative_item { STORE_LOC($$, @$); }

_subprogram_declarative_item:
    subprogram_declaration
    | subprogram_body
    | subprogram_instantiation_declaration
    | package_declaration
    | package_body
    | package_instantiation_declaration
    | type_declaration
    | subtype_declaration
    | constant_declaration
    | variable_declaration
    | file_declaration
    | alias_declaration
    | attribute_declaration
    | attribute_specification
    | use_clause
    | group_template_declaration
    | group_declaration

/// Section 4.4
subprogram_instantiation_declaration:
    KW_PROCEDURE _real_subprogram_instantiation_declaration ';' {
        $$ = $2;
        $$->subprogram_kind = SUBPROGRAM_PROCEDURE;
    }
    | KW_FUNCTION _real_subprogram_instantiation_declaration ';' {
        $$ = $2;
        $$->subprogram_kind = SUBPROGRAM_FUNCTION;
    }

_real_subprogram_instantiation_declaration:
    designator KW_IS KW_NEW name {
        $$ = new VhdlParseTreeNode(PT_SUBPROGRAM_INSTANTIATION_DECLARATION);
        $$->pieces[0] = $1;
        $$->pieces[1] = $4;
        $$->pieces[2] = nullptr;
        $$->pieces[3] = nullptr;
    }
    | designator KW_IS KW_NEW name signature {
        $$ = new VhdlParseTreeNode(PT_SUBPROGRAM_INSTANTIATION_DECLARATION);
        $$->pieces[0] = $1;
        $$->pieces[1] = $4;
        $$->pieces[2] = $5;
        $$->pieces[3] = nullptr;
    }
    | designator KW_IS KW_NEW name generic_map_aspect {
        $$ = new VhdlParseTreeNode(PT_SUBPROGRAM_INSTANTIATION_DECLARATION);
        $$->pieces[0] = $1;
        $$->pieces[1] = $4;
        $$->pieces[2] = nullptr;
        $$->pieces[3] = $5;
    }
    | designator KW_IS KW_NEW name signature generic_map_aspect {
        $$ = new VhdlParseTreeNode(PT_SUBPROGRAM_INSTANTIATION_DECLARATION);
        $$->pieces[0] = $1;
        $$->pieces[1] = $4;
        $$->pieces[2] = $5;
        $$->pieces[3] = $6;
    }

/// Section 4.5.3
signature:
    '[' ']' {
        $$ = new VhdlParseTreeNode(PT_SIGNATURE);
        $$->pieces[0] = nullptr;
        $$->pieces[1] = nullptr;
    }
    | '[' _one_or_more_type_marks ']' {
        $$ = new VhdlParseTreeNode(PT_SIGNATURE);
        $$->pieces[0] = $2;
        $$->pieces[1] = nullptr;
    }
    | '[' KW_RETURN type_mark ']' {
        $$ = new VhdlParseTreeNode(PT_SIGNATURE);
        $$->pieces[0] = nullptr;
        $$->pieces[1] = $3;
    }
    | '[' _one_or_more_type_marks KW_RETURN type_mark ']' {
        $$ = new VhdlParseTreeNode(PT_SIGNATURE);
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
    }

_one_or_more_type_marks:
    type_mark
    | _one_or_more_type_marks ',' type_mark {
        $$ = new VhdlParseTreeNode(PT_TYPE_MARK_LIST);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

/// Section 4.7
package_declaration:
    _real_package_declaration ';'
    | _real_package_declaration KW_PACKAGE ';'
    | _real_package_declaration identifier ';' {
        $$ = $1;
        $$->pieces[3] = $2;
    }
    | _real_package_declaration KW_PACKAGE identifier ';' {
        $$ = $1;
        $$->pieces[3] = $3;
    }

_real_package_declaration:
    KW_PACKAGE identifier KW_IS
    package_header package_declarative_part KW_END {
        $$ = new VhdlParseTreeNode(PT_PACKAGE_DECLARATION);
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
        $$->pieces[2] = $5;
        $$->pieces[3] = nullptr;
    }

package_header:
    %empty
    // generic_clause got folded in because why not
    | KW_GENERIC '(' interface_list ')' ';' {
        $$ = new VhdlParseTreeNode(PT_PACKAGE_HEADER);
        $$->pieces[0] = $3;
        $$->pieces[1] = nullptr;
    }
    | KW_GENERIC '(' interface_list ')' ';' generic_map_aspect ';' {
        $$ = new VhdlParseTreeNode(PT_PACKAGE_HEADER);
        $$->pieces[0] = $3;
        $$->pieces[1] = $6;
    }

package_declarative_part:
    %empty
    | _real_package_declarative_part

_real_package_declarative_part:
    package_declarative_item
    | _real_package_declarative_part package_declarative_item {
        $$ = new VhdlParseTreeNode(PT_DECLARATION_LIST);
        $$->pieces[0] = $1;
        $$->pieces[1] = $2;
    }

// Store line number information
package_declarative_item: _package_declarative_item { STORE_LOC($$, @$); }

_package_declarative_item:
    subprogram_declaration
    | subprogram_instantiation_declaration
    | package_declaration
    | package_instantiation_declaration
    | type_declaration
    | subtype_declaration
    | constant_declaration
    | signal_declaration
    | variable_declaration
    | file_declaration
    | alias_declaration
    | component_declaration
    | attribute_declaration
    | attribute_specification
    | disconnection_specification
    | use_clause
    | group_template_declaration
    | group_declaration

/// Section 4.8
package_body:
    _real_package_body ';'
    | _real_package_body KW_PACKAGE KW_BODY ';'
    | _real_package_body identifier ';' {
        $$ = $1;
        $$->pieces[2] = $2;
    }
    | _real_package_body KW_PACKAGE KW_BODY identifier ';' {
        $$ = $1;
        $$->pieces[2] = $4;
    }

_real_package_body:
    KW_PACKAGE KW_BODY identifier KW_IS package_body_declarative_part KW_END {
        $$ = new VhdlParseTreeNode(PT_PACKAGE_BODY);
        $$->pieces[0] = $3;
        $$->pieces[1] = $5;
        $$->pieces[2] = nullptr;
    }

package_body_declarative_part:
    %empty
    | _real_package_body_declarative_part

_real_package_body_declarative_part:
    package_body_declarative_item
    | _real_package_body_declarative_part package_body_declarative_item {
        $$ = new VhdlParseTreeNode(PT_DECLARATION_LIST);
        $$->pieces[0] = $1;
        $$->pieces[1] = $2;
    }

// Store line number information
package_body_declarative_item:
    _package_body_declarative_item { STORE_LOC($$, @$); }

_package_body_declarative_item:
    subprogram_declaration
    | subprogram_body
    | subprogram_instantiation_declaration
    | package_declaration
    | package_body
    | package_instantiation_declaration
    | type_declaration
    | subtype_declaration
    | constant_declaration
    | variable_declaration
    | file_declaration
    | alias_declaration
    | attribute_declaration
    | attribute_specification
    | use_clause
    | group_template_declaration
    | group_declaration

/// Section 4.9
package_instantiation_declaration:
    KW_PACKAGE identifier KW_IS KW_NEW name ';' {
        $$ = new VhdlParseTreeNode(PT_PACKAGE_INSTANTIATION_DECLARATION);
        $$->pieces[0] = $2;
        $$->pieces[1] = $5;
    }
    | KW_PACKAGE identifier KW_IS KW_NEW name generic_map_aspect ';' {
        $$ = new VhdlParseTreeNode(PT_PACKAGE_INSTANTIATION_DECLARATION);
        $$->pieces[0] = $2;
        $$->pieces[1] = $5;
        $$->pieces[2] = $6;
    }

////////////////////////////// Types, section 5 //////////////////////////////

/// Section 5.2.1
scalar_type_definition:
    enumeration_type_definition
    // We cannot tell these apart at this stage
    | _integer_or_floating_type_definition
    | physical_type_definition

range_constraint:
    KW_RANGE range {
        $$ = $2;
    }

range:
    _almost_range
    | attribute_name

// We need this because of the "name" rule that cannot have an attribute_name
// here in order to avoid ambiguity.
_almost_range:
    simple_expression KW_DOWNTO simple_expression {
        $$ = new VhdlParseTreeNode(PT_RANGE);
        $$->range_dir = RANGE_DOWN;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }
    | simple_expression KW_TO simple_expression {
        $$ = new VhdlParseTreeNode(PT_RANGE);
        $$->range_dir = RANGE_UP;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

/// Section 5.2.2
enumeration_type_definition:
    '(' _one_or_more_enumeration_literals ')' {
        $$ = new VhdlParseTreeNode(PT_ENUMERATION_TYPE_DEFINITION);
        $$->pieces[0] = $2;
    }

_one_or_more_enumeration_literals:
    enumeration_literal
    | _one_or_more_enumeration_literals ',' enumeration_literal {
        $$ = new VhdlParseTreeNode(PT_ENUM_LITERAL_LIST);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

enumeration_literal:
    identifier
    | character_literal

/// Section 5.2.3, 5.2.5
_integer_or_floating_type_definition:
    range_constraint {
        $$ = new VhdlParseTreeNode(PT_INTEGER_FLOAT_TYPE_DEFINITION);
        $$->pieces[0] = $1;
    }

/// Section 5.2.4
physical_type_definition:
    _real_physical_type_definition
    | _real_physical_type_definition identifier {
        $$ = $1;
        $$->pieces[3] = $2;
    }

_real_physical_type_definition:
    range_constraint KW_UNITS identifier ';' KW_END KW_UNITS {
        $$ = new VhdlParseTreeNode(PT_PHYSICAL_TYPE_DEFINITION);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
        $$->pieces[2] = nullptr;
        $$->pieces[3] = nullptr;
    }
    | range_constraint KW_UNITS identifier ';'
      _one_or_more_secondary_unit_declarations KW_END KW_UNITS {
        $$ = new VhdlParseTreeNode(PT_PHYSICAL_TYPE_DEFINITION);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
        $$->pieces[2] = $5;
        $$->pieces[3] = nullptr;
    }

_one_or_more_secondary_unit_declarations:
    secondary_unit_declaration
    | _one_or_more_secondary_unit_declarations secondary_unit_declaration {
        $$ = new VhdlParseTreeNode(PT_SECONDARY_UNIT_DECLARATION_LIST);
        $$->pieces[0] = $1;
        $$->pieces[1] = $2;
    }

secondary_unit_declaration:
    identifier '=' physical_literal ';' {
        $$ = new VhdlParseTreeNode(PT_SECONDARY_UNIT_DECLARATION);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

physical_literal:
    _almost_physical_literal
    | _simple_or_selected_name

// This requires the abstract_literal otherwise it becomes ambiguous with just
// name.
_almost_physical_literal:
    abstract_literal _simple_or_selected_name {
        $$ = new VhdlParseTreeNode(PT_LIT_PHYS);
        $$->pieces[0] = $2;
        $$->pieces[1] = $1;
    }

/// Section 5.3.1
composite_type_definition:
    array_type_definition
    | record_type_definition

/// Section 5.3.2
// The way we've defined this causes a shift/reduce conflict.
array_type_definition:
    unbounded_array_definition
    | constrained_array_definition

unbounded_array_definition:
    KW_ARRAY '(' _one_or_more_index_subtype_definition ')'
    KW_OF subtype_indication {
        $$ = new VhdlParseTreeNode(PT_UNBOUNDED_ARRAY_DEFINITION);
        $$->pieces[0] = $3;
        $$->pieces[1] = $6;
    }

constrained_array_definition:
    KW_ARRAY index_constraint KW_OF subtype_indication {
        $$ = new VhdlParseTreeNode(PT_CONSTRAINED_ARRAY_DEFINITION);
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
    }

_one_or_more_index_subtype_definition:
    index_subtype_definition
    | _one_or_more_index_subtype_definition ',' index_subtype_definition {
        $$ = new VhdlParseTreeNode(PT_INDEX_SUBTYPE_DEFINITION_LIST);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

index_subtype_definition:
    type_mark KW_RANGE DL_BOX {
        $$ = $1;
    }

array_constraint:
    _array_constraint_open
    | '(' KW_OPEN ')' element_constraint {
        $$ = new VhdlParseTreeNode(PT_ARRAY_CONSTRAINT);
        $$->pieces[0] = nullptr;
        $$->pieces[1] = $4;
    }
    | index_constraint {
        $$ = new VhdlParseTreeNode(PT_ARRAY_CONSTRAINT);
        $$->pieces[0] = $1;
        $$->pieces[1] = nullptr;
    }
    | index_constraint element_constraint {
        $$ = new VhdlParseTreeNode(PT_ARRAY_CONSTRAINT);
        $$->pieces[0] = $1;
        $$->pieces[1] = $2;
    }

// We need this for association list disambiguation with name
_definitely_not_name_array_constraint:
    _array_constraint_open_and_element_constraint
    | _array_constraint_definitely_multiple_ranges

_array_constraint_open:
    '(' KW_OPEN ')' {
        $$ = new VhdlParseTreeNode(PT_ARRAY_CONSTRAINT);
        $$->pieces[0] = nullptr;
        $$->pieces[1] = nullptr;
    }

_array_constraint_open_and_element_constraint:
    '(' KW_OPEN ')' _morph_name_into_subtype_indication_constraint {
        $$ = new VhdlParseTreeNode(PT_ARRAY_CONSTRAINT);
        $$->pieces[0] = nullptr;
        $$->pieces[1] = $4;
    }

// TODO: WTF is going on here?
// This is the "stuff that can come after a name involving parentheses" that
// ensures that it is for certain a subtype_indication.
_morph_name_into_subtype_indication_constraint:
    _definitely_further_element_constraint
    | _array_constraint_open
    // A function cannot return a function, so (open)(open) is definitely an
    // array constraint and an array element constraint
    | '(' KW_OPEN ')' element_constraint {
        $$ = new VhdlParseTreeNode(PT_ARRAY_CONSTRAINT);
        $$->pieces[0] = nullptr;
        $$->pieces[1] = $4;
    }

_array_constraint_definitely_multiple_ranges:
    _definitely_index_constraint {
        $$ = new VhdlParseTreeNode(PT_ARRAY_CONSTRAINT);
        $$->pieces[0] = $1;
        $$->pieces[1] = nullptr;
    }
    | _definitely_index_constraint element_constraint {
        $$ = new VhdlParseTreeNode(PT_ARRAY_CONSTRAINT);
        $$->pieces[0] = $1;
        $$->pieces[1] = $2;
    }

index_constraint:
    '(' _one_or_more_discrete_range ')' {
        $$ = $2;
    }

_definitely_index_constraint:
    '(' _two_or_more_discrete_range ')' {
        $$ = $2;
    }

_one_or_more_discrete_range:
    discrete_range
    | _one_or_more_discrete_range ',' discrete_range {
        $$ = new VhdlParseTreeNode(PT_INDEX_CONSTRAINT);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

// Really hacked up, must have two or more and not be a bare name
_two_or_more_discrete_range:
    _almost_discrete_range ',' discrete_range {
        $$ = new VhdlParseTreeNode(PT_INDEX_CONSTRAINT);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }
    // HACK
    | _one_or_more_expressions ',' _almost_discrete_range {
        $$ = new VhdlParseTreeNode(PT_INDEX_CONSTRAINT);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }
    | _two_or_more_discrete_range ',' discrete_range {
        $$ = new VhdlParseTreeNode(PT_INDEX_CONSTRAINT);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

// Rather chopped up for use in name and aggregates
_almost_discrete_range:
    _almost_discrete_subtype_indication
    | _almost_range

// Re-allow the forbidden attribute name and single type_mark
discrete_range:
    discrete_subtype_indication
    | range

/// Section 5.3.3
record_type_definition:
    _real_record_type_definition
    | _real_record_type_definition identifier {
        $$ = $1;
        $$->pieces[1] = $2;
    }

_real_record_type_definition:
    KW_RECORD _one_or_more_element_declarations KW_END KW_RECORD {
        $$ = new VhdlParseTreeNode(PT_RECORD_TYPE_DEFINITION);
        $$->pieces[0] = $2;
        $$->pieces[1] = nullptr;
    }

_one_or_more_element_declarations:
    element_declaration
    | _one_or_more_element_declarations element_declaration {
        $$ = new VhdlParseTreeNode(PT_ELEMENT_DECLARATION_LIST);
        $$->pieces[0] = $1;
        $$->pieces[1] = $2;
    }

element_declaration:
    identifier_list ':' subtype_indication ';' {
        $$ = new VhdlParseTreeNode(PT_ELEMENT_DECLARATION);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

identifier_list:
    identifier
    | identifier_list ',' identifier {
        $$ = new VhdlParseTreeNode(PT_ID_LIST_REAL);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

record_constraint:
    '(' _one_or_more_record_element_constraint ')' {
        $$ = $2;
    }

_one_or_more_record_element_constraint:
    record_element_constraint
    | _one_or_more_record_element_constraint ',' record_element_constraint {
        $$ = new VhdlParseTreeNode(PT_RECORD_CONSTRAINT);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

record_element_constraint:
    identifier element_constraint {
        $$ = new VhdlParseTreeNode(PT_RECORD_ELEMENT_CONSTRAINT);
        $$->pieces[0] = $1;
        $$->pieces[1] = $2;
    }

// FIXME: Ugly hack to make association_list work
_definitely_not_name_record_constraint:
    '(' _one_or_more_association_list_record_element_constraint ')' {
        $$ = $2;
    }

_one_or_more_association_list_record_element_constraint:
    _association_list_record_element_constraint
    | _one_or_more_association_list_record_element_constraint ','
      record_element_constraint {
        $$ = new VhdlParseTreeNode(PT_RECORD_CONSTRAINT);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }
    // HACK
    | _one_or_more_expressions ','
      _association_list_record_element_constraint {
        $$ = new VhdlParseTreeNode(PT_RECORD_CONSTRAINT);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

_association_list_record_element_constraint:
    identifier _definitely_further_element_constraint {
        $$ = new VhdlParseTreeNode(PT_RECORD_ELEMENT_CONSTRAINT);
        $$->pieces[0] = $1;
        $$->pieces[1] = $2;
    }
    // HACK, FIXME
    | _hack_name_for_association_list
      _morph_name_into_subtype_indication_constraint {
        $$ = new VhdlParseTreeNode(PT_SUBTYPE_INDICATION_AMBIG_WTF);
        $$->pieces[0] = new VhdlParseTreeNode(PT_ARRAY_CONSTRAINT);
        $$->pieces[0]->pieces[0] = $1;
        $$->pieces[0]->pieces[1] = $2;
    }

/// Section 5.4
access_type_definition:
    KW_ACCESS subtype_indication {
        $$ = new VhdlParseTreeNode(PT_ACCESS_TYPE_DEFINITION);
        $$->pieces[0] = $2;
    }

incomplete_type_declaration:
    KW_TYPE identifier ';' {
        $$ = new VhdlParseTreeNode(PT_INCOMPLETE_TYPE_DECLARATION);
        $$->pieces[0] = $2;
    }

/// Section 5.5
file_type_definition:
    KW_FILE KW_OF type_mark {
        $$ = new VhdlParseTreeNode(PT_FILE_TYPE_DEFINITION);
        $$->pieces[0] = $3;

    }

/// Section 5.6
protected_type_definition:
    protected_type_declaration
    | protected_type_body

/// Section 5.6.2
protected_type_declaration:
    _real_protected_type_declaration
    | _real_protected_type_declaration identifier {
        $$ = $1;
        $$->pieces[1] = $2;
    }

_real_protected_type_declaration:
    KW_PROTECTED protected_type_declarative_part KW_END KW_PROTECTED {
        $$ = new VhdlParseTreeNode(PT_PROTECTED_TYPE_DECLARATION);
        $$->pieces[0] = $2;
        $$->pieces[1] = nullptr;
    }

protected_type_declarative_part:
    %empty
    | _real_protected_type_declarative_part

_real_protected_type_declarative_part:
    protected_type_declarative_item
    | _real_protected_type_declarative_part protected_type_declarative_item {
        $$ = new VhdlParseTreeNode(PT_DECLARATION_LIST);
        $$->pieces[0] = $1;
        $$->pieces[1] = $2;
    }

// Store line number information
protected_type_declarative_item:
    _protected_type_declarative_item { STORE_LOC($$, @$); }

_protected_type_declarative_item:
    subprogram_declaration
    | subprogram_instantiation_declaration
    | attribute_specification
    | use_clause

/// Section 5.6.3
protected_type_body:
    _real_protected_type_body
    | _real_protected_type_body identifier {
        $$ = $1;
        $$->pieces[1] = $2;
    }

_real_protected_type_body:
    KW_PROTECTED KW_BODY protected_type_body_declarative_part
    KW_END KW_PROTECTED KW_BODY {
        $$ = new VhdlParseTreeNode(PT_PROTECTED_TYPE_BODY);
        $$->pieces[0] = $3;
        $$->pieces[1] = nullptr;
    }

protected_type_body_declarative_part:
    %empty
    | _real_protected_type_body_declarative_part

_real_protected_type_body_declarative_part:
    protected_type_body_declarative_item
    | _real_protected_type_body_declarative_part
      protected_type_body_declarative_item {
        $$ = new VhdlParseTreeNode(PT_DECLARATION_LIST);
        $$->pieces[0] = $1;
        $$->pieces[1] = $2;
    }

// Store line number information
protected_type_body_declarative_item:
    _protected_type_body_declarative_item { STORE_LOC($$, @$); }

_protected_type_body_declarative_item:
    subprogram_declaration
    | subprogram_body
    | subprogram_instantiation_declaration
    | package_declaration
    | package_body
    | package_instantiation_declaration
    | type_declaration
    | subtype_declaration
    | constant_declaration
    | variable_declaration
    | file_declaration
    | alias_declaration
    | attribute_declaration
    | attribute_specification
    | use_clause
    | group_template_declaration
    | group_declaration

/////////////////////////// Declarations, section 6 ///////////////////////////

/// Section 6.2
type_declaration:
    full_type_declaration
    | incomplete_type_declaration

full_type_declaration:
    KW_TYPE identifier KW_IS type_definition ';' {
        $$ = new VhdlParseTreeNode(PT_FULL_TYPE_DECLARATION);
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
    }

type_definition:
    scalar_type_definition
    | composite_type_definition
    | access_type_definition
    | file_type_definition
    | protected_type_definition

/// Section 6.3
subtype_declaration:
    KW_SUBTYPE identifier KW_IS subtype_indication ';' {
        $$ = new VhdlParseTreeNode(PT_SUBTYPE_DECLARATION);
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
    }

subtype_indication:
    type_mark {
        $$ = new VhdlParseTreeNode(PT_SUBTYPE_INDICATION);
        $$->pieces[0] = $1;
        $$->pieces[1] = nullptr;
        $$->pieces[2] = nullptr;
    }
    | resolution_indication type_mark {
        $$ = new VhdlParseTreeNode(PT_SUBTYPE_INDICATION);
        $$->pieces[0] = $2;
        $$->pieces[1] = $1;
        $$->pieces[2] = nullptr;
    }
    | type_mark constraint {
        $$ = new VhdlParseTreeNode(PT_SUBTYPE_INDICATION);
        $$->pieces[0] = $1;
        $$->pieces[1] = nullptr;
        $$->pieces[2] = $2;
    }
    | resolution_indication type_mark constraint {
        $$ = new VhdlParseTreeNode(PT_SUBTYPE_INDICATION);
        $$->pieces[0] = $2;
        $$->pieces[1] = $1;
        $$->pieces[2] = $3;
    }

// Does not handle the case of only a type_mark because that can cause
// ambiguities. Does not allow a resolution indication because that isn't
// actually permitted (see 5.3.2.1).
_almost_discrete_subtype_indication:
    type_mark _discrete_constraint {
        $$ = new VhdlParseTreeNode(PT_SUBTYPE_INDICATION);
        $$->pieces[0] = $1;
        $$->pieces[1] = nullptr;
        $$->pieces[2] = $2;
    }

// Reallow identifiers (a plain type_mark but not an attribute)
// FIXME: Ugly, the reason attribute isn't allowed is because this is used in
// discrete_range which can also be range which can be an attribute.
discrete_subtype_indication:
    _simple_or_selected_name
    | _almost_discrete_subtype_indication

_allocator_subtype_indication:
    // Resolution indications not allowed
    type_mark {
        $$ = new VhdlParseTreeNode(PT_SUBTYPE_INDICATION);
        $$->pieces[0] = $1;
        $$->pieces[1] = nullptr;
        $$->pieces[2] = nullptr;
    }
    | type_mark _allocator_constraint {
        $$ = new VhdlParseTreeNode(PT_SUBTYPE_INDICATION);
        $$->pieces[0] = $1;
        $$->pieces[1] = nullptr;
        $$->pieces[2] = $2;
    }

// This is an attempt to cover exactly those things that are subtype_indication
// but not a name. When we know we have a resolution_indication this is easy,
// but when we don't we might have no idea. The disambiguation is done by
// trying to look for either "stuff in parentheses" that cannot be a function
// call or a slice or "stuff after the parentheses" that cannot come after
// a function call or a slice. Does not have a bare name because that's
// ambiguous.
_association_list_subtype_indication:
    resolution_indication type_mark {
        $$ = new VhdlParseTreeNode(PT_SUBTYPE_INDICATION);
        $$->pieces[0] = $2;
        $$->pieces[1] = $1;
        $$->pieces[2] = nullptr;
    }
    | type_mark _association_list_definitely_constraint {
        $$ = new VhdlParseTreeNode(PT_SUBTYPE_INDICATION);
        $$->pieces[0] = $1;
        $$->pieces[1] = nullptr;
        $$->pieces[2] = $2;
    }
    | resolution_indication type_mark constraint {
        $$ = new VhdlParseTreeNode(PT_SUBTYPE_INDICATION);
        $$->pieces[0] = $2;
        $$->pieces[1] = $1;
        $$->pieces[2] = $3;
    }
    // HACK, FIXME
    | _hack_name_for_association_list
      _morph_name_into_subtype_indication_constraint {
        $$ = new VhdlParseTreeNode(PT_SUBTYPE_INDICATION_AMBIG_WTF);
        $$->pieces[0] = new VhdlParseTreeNode(PT_ARRAY_CONSTRAINT);
        $$->pieces[0]->pieces[0] = $1;
        $$->pieces[0]->pieces[1] = $2;
    }

resolution_indication:
    // The following two are for function names
    function_name
    | _parens_element_resolution

// Folding in the element_resolution eliminates a reduce/reduce conflict.
_parens_element_resolution:
    '(' function_name ')' {
        $$ = new VhdlParseTreeNode(PT_ELEMENT_RESOLUTION_NEST);
        $$->pieces[0] = $2;
    }
    | '(' _parens_element_resolution ')' {
        $$ = new VhdlParseTreeNode(PT_ELEMENT_RESOLUTION_NEST);
        $$->pieces[0] = $2;
    }
    | '(' record_resolution ')' {
        $$ = new VhdlParseTreeNode(PT_ELEMENT_RESOLUTION_NEST);
        $$->pieces[0] = $2;
    }

record_resolution:
    record_element_resolution
    | record_resolution ',' record_element_resolution {
        $$ = new VhdlParseTreeNode(PT_RECORD_RESOLUTION);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

record_element_resolution:
    identifier resolution_indication {
        $$ = new VhdlParseTreeNode(PT_RECORD_ELEMENT_RESOLUTION);
        $$->pieces[0] = $1;
        $$->pieces[1] = $2;
    }

// A type can be the special attributes 'subtype or 'element (but not an
// attribute with parentheses, because functions can't return types).
type_mark:
    _simple_or_selected_name
    | _almost_attribute_name

// FIXME: explain why there is a S/R conflict here
constraint:
    range_constraint
    | array_constraint
    | record_constraint

_association_list_definitely_constraint:
    range_constraint
    | _definitely_further_element_constraint

// When a "discrete" subtype indication is needed, the _only_ type of
// constraint we can have is a range constraint. Arrays and records aren't
// discrete.
_discrete_constraint:
    range_constraint

_allocator_constraint:
    // Can only be an array or record constraint
    array_constraint
    | record_constraint

element_constraint:
    array_constraint
    | record_constraint

_definitely_further_element_constraint:
    _definitely_not_name_array_constraint
    | _definitely_not_name_record_constraint

/// Section 6.4.2.2
constant_declaration:
    KW_CONSTANT identifier_list ':' subtype_indication ';' {
        $$ = new VhdlParseTreeNode(PT_CONSTANT_DECLARATION);
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
    }
    | KW_CONSTANT identifier_list ':' subtype_indication
      DL_ASS expression ';' {
        $$ = new VhdlParseTreeNode(PT_CONSTANT_DECLARATION);
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
        $$->pieces[2] = $6;
    }

/// Section 6.4.2.3
signal_declaration:
    KW_SIGNAL identifier_list ':' subtype_indication ';' {
        $$ = new VhdlParseTreeNode(PT_SIGNAL_DECLARATION);
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
        $$->pieces[2] = nullptr;
        $$->pieces[3] = nullptr;
    }
    | KW_SIGNAL identifier_list ':' subtype_indication
      DL_ASS expression ';' {
        $$ = new VhdlParseTreeNode(PT_SIGNAL_DECLARATION);
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
        $$->pieces[2] = nullptr;
        $$->pieces[3] = $6;
    }
    | KW_SIGNAL identifier_list ':' subtype_indication signal_kind ';' {
        $$ = new VhdlParseTreeNode(PT_SIGNAL_DECLARATION);
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
        $$->pieces[2] = $5;
        $$->pieces[3] = nullptr;
    }
    | KW_SIGNAL identifier_list ':' subtype_indication signal_kind
      DL_ASS expression ';' {
        $$ = new VhdlParseTreeNode(PT_SIGNAL_DECLARATION);
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
        $$->pieces[2] = $5;
        $$->pieces[3] = $7;
    }

signal_kind:
    KW_REGISTER {
        $$ = new VhdlParseTreeNode(PT_SIGNAL_KIND);
        $$->signal_kind = SIGKIND_REGISTER;
    }
    | KW_BUS {
        $$ = new VhdlParseTreeNode(PT_SIGNAL_KIND);
        $$->signal_kind = SIGKIND_BUS;
    }

/// Section 6.4.2.4
variable_declaration:
    _real_variable_declaration
    | KW_SHARED _real_variable_declaration {
        $$ = $2;
        $$->boolean = true;
    }

_real_variable_declaration:
    KW_VARIABLE identifier_list ':' subtype_indication ';' {
        $$ = new VhdlParseTreeNode(PT_VARIABLE_DECLARATION);
        $$->boolean = false;
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
    }
    | KW_VARIABLE identifier_list ':' subtype_indication
      DL_ASS expression ';' {
        $$ = new VhdlParseTreeNode(PT_VARIABLE_DECLARATION);
        $$->boolean = false;
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
        $$->pieces[2] = $6;
    }

/// Section 6.4.2.5
file_declaration:
    KW_FILE identifier_list ':' subtype_indication ';' {
        $$ = new VhdlParseTreeNode(PT_FILE_DECLARATION);
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
    }
    | KW_FILE identifier_list ':' subtype_indication
      file_open_information ';' {
        $$ = new VhdlParseTreeNode(PT_FILE_DECLARATION);
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
        $$->pieces[2] = $5;
    }

file_open_information:
    KW_IS expression {
        $$ = new VhdlParseTreeNode(PT_FILE_OPEN_INFORMATION);
        $$->pieces[0] = $2;
    }
    | KW_OPEN expression KW_IS expression {
        $$ = new VhdlParseTreeNode(PT_FILE_OPEN_INFORMATION);
        $$->pieces[0] = $4;
        $$->pieces[1] = $2;
    }

/// Section 6.5
interface_declaration:
    interface_object_declaration
    | interface_type_declaration
    | interface_subprogram_declaration
    | interface_package_declaration

/// Section 6.5.2
interface_object_declaration:
    _interface_ambig_obj_declaration
    | _definitely_interface_constant_declaration
    | _definitely_interface_signal_declaration
    | _definitely_interface_variable_declaration
    | interface_file_declaration

_definitely_interface_constant_declaration:
    KW_CONSTANT _interface_ambig_obj_declaration {
        $$ = $2;
        $$->type = PT_INTERFACE_CONSTANT_DECLARATION;
    }

_definitely_interface_signal_declaration:
    KW_SIGNAL _interface_ambig_obj_declaration {
        $$ = $2;
        $$->boolean = false;
        $$->type = PT_INTERFACE_SIGNAL_DECLARATION;
    }
    | _interface_signal_bus_declaration
    | KW_SIGNAL _interface_signal_bus_declaration {
        $$ = $2;
    }

_definitely_interface_variable_declaration:
    KW_VARIABLE _interface_ambig_obj_declaration {
        $$ = $2;
        $$->type = PT_INTERFACE_VARIABLE_DECLARATION;
    }

// Handles all the cases where there is no explicit type
_interface_ambig_obj_declaration:
    identifier_list ':' subtype_indication {
        $$ = new VhdlParseTreeNode(PT_INTERFACE_AMBIG_OBJ_DECLARATION);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
        $$->pieces[2] = nullptr;
        $$->pieces[3] = nullptr;
    }
    | identifier_list ':' mode subtype_indication {
        $$ = new VhdlParseTreeNode(PT_INTERFACE_AMBIG_OBJ_DECLARATION);
        $$->pieces[0] = $1;
        $$->pieces[1] = $4;
        $$->pieces[2] = nullptr;
        $$->pieces[3] = $3;
    }
    | identifier_list ':' subtype_indication DL_ASS expression {
        $$ = new VhdlParseTreeNode(PT_INTERFACE_AMBIG_OBJ_DECLARATION);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
        $$->pieces[2] = $5;
        $$->pieces[3] = nullptr;
    }
    | identifier_list ':' mode subtype_indication DL_ASS expression {
        $$ = new VhdlParseTreeNode(PT_INTERFACE_AMBIG_OBJ_DECLARATION);
        $$->pieces[0] = $1;
        $$->pieces[1] = $4;
        $$->pieces[2] = $6;
        $$->pieces[3] = $3;
    }

// Has the keyword "bus" in it
_interface_signal_bus_declaration:
    identifier_list ':' subtype_indication KW_BUS {
        $$ = new VhdlParseTreeNode(PT_INTERFACE_SIGNAL_DECLARATION);
        $$->boolean = true;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
        $$->pieces[2] = nullptr;
        $$->pieces[3] = nullptr;
    }
    | identifier_list ':' mode subtype_indication KW_BUS {
        $$ = new VhdlParseTreeNode(PT_INTERFACE_SIGNAL_DECLARATION);
        $$->boolean = true;
        $$->pieces[0] = $1;
        $$->pieces[1] = $4;
        $$->pieces[2] = nullptr;
        $$->pieces[3] = $3;
    }
    | identifier_list ':' subtype_indication KW_BUS DL_ASS expression {
        $$ = new VhdlParseTreeNode(PT_INTERFACE_SIGNAL_DECLARATION);
        $$->boolean = true;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
        $$->pieces[2] = $6;
        $$->pieces[3] = nullptr;
    }
    | identifier_list ':' mode subtype_indication KW_BUS DL_ASS expression {
        $$ = new VhdlParseTreeNode(PT_INTERFACE_SIGNAL_DECLARATION);
        $$->boolean = true;
        $$->pieces[0] = $1;
        $$->pieces[1] = $4;
        $$->pieces[2] = $7;
        $$->pieces[3] = $3;
    }

mode:
    KW_IN {
        $$ = new VhdlParseTreeNode(PT_INTERFACE_MODE);
        $$->interface_mode = MODE_IN;
    }
    | KW_OUT {
        $$ = new VhdlParseTreeNode(PT_INTERFACE_MODE);
        $$->interface_mode = MODE_OUT;
    }
    | KW_INOUT {
        $$ = new VhdlParseTreeNode(PT_INTERFACE_MODE);
        $$->interface_mode = MODE_INOUT;
    }
    | KW_BUFFER {
        $$ = new VhdlParseTreeNode(PT_INTERFACE_MODE);
        $$->interface_mode = MODE_BUFFER;
    }
    | KW_LINKAGE {
        $$ = new VhdlParseTreeNode(PT_INTERFACE_MODE);
        $$->interface_mode = MODE_LINKAGE;
    }

interface_file_declaration:
    KW_FILE identifier_list ':' subtype_indication {
        $$ = new VhdlParseTreeNode(PT_INTERFACE_FILE_DECLARATION);
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
    }

/// Section 6.5.3
interface_type_declaration:
    KW_TYPE identifier {
        $$ = new VhdlParseTreeNode(PT_INTERFACE_TYPE_DECLARATION);
        $$->pieces[0] = $2;
    }

/// Section 6.5.4
interface_subprogram_declaration:
    interface_subprogram_specification {
        $$ = new VhdlParseTreeNode(PT_INTERFACE_SUBPROGRAM_DECLARATION);
        $$->pieces[0] = $1;
    }
    | interface_subprogram_specification KW_IS name {
        $$ = new VhdlParseTreeNode(PT_INTERFACE_SUBPROGRAM_DECLARATION);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }
    | interface_subprogram_specification KW_IS DL_BOX {
        $$ = new VhdlParseTreeNode(PT_INTERFACE_SUBPROGRAM_DECLARATION);
        $$->pieces[0] = $1;
        $$->pieces[1] =
            new VhdlParseTreeNode(PT_INTERFACE_SUBPROGRAM_DEFAULT_BOX);
    }

interface_subprogram_specification:
    interface_procedure_specification
    | interface_function_specification

interface_procedure_specification:
    KW_PROCEDURE designator {
        $$ = new VhdlParseTreeNode(PT_INTERFACE_PROCEDURE_SPECIFICATION);
        $$->pieces[0] = $2;
    }
    | KW_PROCEDURE designator '(' interface_list ')' {
        $$ = new VhdlParseTreeNode(PT_INTERFACE_PROCEDURE_SPECIFICATION);
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
    }
    | KW_PROCEDURE designator KW_PARAMETER '(' interface_list ')' {
        $$ = new VhdlParseTreeNode(PT_INTERFACE_PROCEDURE_SPECIFICATION);
        $$->pieces[0] = $2;
        $$->pieces[1] = $5;
    }

interface_function_specification:
    _real_interface_function_specification
    | KW_PURE _real_interface_function_specification {
        $$ = $2;
        $$->purity = PURITY_PURE;
    }
    | KW_IMPURE _real_interface_function_specification {
        $$ = $2;
        $$->purity = PURITY_IMPURE;
    }

_real_interface_function_specification:
    KW_FUNCTION designator KW_RETURN type_mark {
        $$ = new VhdlParseTreeNode(PT_INTERFACE_FUNCTION_SPECIFICATION);
        $$->purity = PURITY_UNSPEC;
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
    }
    | KW_FUNCTION designator '(' interface_list ')' KW_RETURN type_mark {
        $$ = new VhdlParseTreeNode(PT_INTERFACE_FUNCTION_SPECIFICATION);
        $$->purity = PURITY_UNSPEC;
        $$->pieces[0] = $2;
        $$->pieces[1] = $7;
        $$->pieces[2] = $4;
    }
    | KW_FUNCTION designator KW_PARAMETER '(' interface_list ')'
      KW_RETURN type_mark {
        $$ = new VhdlParseTreeNode(PT_INTERFACE_FUNCTION_SPECIFICATION);
        $$->purity = PURITY_UNSPEC;
        $$->pieces[0] = $2;
        $$->pieces[1] = $8;
        $$->pieces[2] = $5;
    }

/// Section 6.5.5
interface_package_declaration:
    KW_PACKAGE identifier
    KW_IS KW_NEW name interface_package_generic_map_aspect {
        $$ = new VhdlParseTreeNode(PT_INTERFACE_PACKAGE_DECLARATION);
        $$->pieces[0] = $2;
        $$->pieces[1] = $5;
        $$->pieces[2] = $6;
    }

interface_package_generic_map_aspect:
    generic_map_aspect
    | KW_GENERIC KW_MAP '(' DL_BOX ')' {
        $$ = new VhdlParseTreeNode(PT_INTERFACE_PACKAGE_GENERIC_MAP_BOX);
    }
    | KW_GENERIC KW_MAP '(' KW_DEFAULT ')' {
        $$ = new VhdlParseTreeNode(PT_INTERFACE_PACKAGE_GENERIC_MAP_DEFAULT);
    }

/// Section 6.5.6
interface_list:
    interface_declaration
    | interface_list ';' interface_declaration {
        $$ = new VhdlParseTreeNode(PT_INTERFACE_LIST);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

/// Section 6.5.7
// FIXME ugly: If we see a bare "open", we know we're going to be a
// function call and cannot hit ambiguities with _ambig_name_parens.
_definitely_parameter_association_list:
    _definitely_parameter_association_element
    | KW_OPEN {
        $$ = new VhdlParseTreeNode(PT_TOK_OPEN);
    }
    | _one_or_more_expressions ',' _definitely_parameter_association_element {
        $$ = new VhdlParseTreeNode(PT_PARAMETER_ASSOCIATION_LIST);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }
    // HACK
    | _one_or_more_expressions ',' KW_OPEN {
        $$ = new VhdlParseTreeNode(PT_PARAMETER_ASSOCIATION_LIST);
        $$->pieces[0] = $1;
        $$->pieces[1] = new VhdlParseTreeNode(PT_TOK_OPEN);
    }
    | _definitely_parameter_association_list ','
      _definitely_parameter_association_element {
        $$ = new VhdlParseTreeNode(PT_PARAMETER_ASSOCIATION_LIST);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }
    // HACK
    | _definitely_parameter_association_list ',' _function_actual_part {
        $$ = new VhdlParseTreeNode(PT_PARAMETER_ASSOCIATION_LIST);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

// Must have => in it
_definitely_parameter_association_element:
    name DL_ARR _function_actual_part {
        $$ = new VhdlParseTreeNode(PT_PARAMETER_ASSOCIATION_ELEMENT);
        $$->pieces[0] = $3;
        $$->pieces[1] = $1;
    }

// By accepting expression we already accept all the possible types of names.
// We cannot accept a type (subtype_indication). We can additionally accept
// "open" however. "inertial" is not allowed for functions.
_function_actual_part:
    expression
    | KW_OPEN {
        $$ = new VhdlParseTreeNode(PT_TOK_OPEN);
    }

// Here are the non-hacked versions
association_list:
    association_element
    | association_list ',' association_element {
        $$ = new VhdlParseTreeNode(PT_ASSOCIATION_LIST);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

association_element:
    actual_part {
        $$ = new VhdlParseTreeNode(PT_ASSOCIATION_ELEMENT);
        $$->pieces[0] = $1;
    }
    | name DL_ARR actual_part {
        $$ = new VhdlParseTreeNode(PT_ASSOCIATION_ELEMENT);
        $$->pieces[0] = $3;
        $$->pieces[1] = $1;
    }

actual_part:
    // actual_designator is folded in
    expression
    | KW_INERTIAL expression {
        $$ = new VhdlParseTreeNode(PT_INERTIAL_EXPRESSION);
        $$->pieces[0] = $2;
    }
    // expression includes all the possible types of names
    | _association_list_subtype_indication
    | KW_OPEN {
        $$ = new VhdlParseTreeNode(PT_TOK_OPEN);
    }

generic_map_aspect:
    KW_GENERIC KW_MAP '(' association_list ')' {
        $$ = new VhdlParseTreeNode(PT_GENERIC_MAP_ASPECT);
        $$->pieces[0] = $4;
    }

port_map_aspect:
    KW_PORT KW_MAP '(' association_list ')' {
        $$ = new VhdlParseTreeNode(PT_PORT_MAP_ASPECT);
        $$->pieces[0] = $4;
    }

/// Section 6.6
alias_declaration:
    KW_ALIAS alias_designator KW_IS name ';' {
        $$ = new VhdlParseTreeNode(PT_ALIAS_DECLARATION);
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
        $$->pieces[2] = nullptr;
        $$->pieces[3] = nullptr;
    }
    | KW_ALIAS alias_designator ':' subtype_indication KW_IS name ';' {
        $$ = new VhdlParseTreeNode(PT_ALIAS_DECLARATION);
        $$->pieces[0] = $2;
        $$->pieces[1] = $6;
        $$->pieces[2] = $4;
        $$->pieces[3] = nullptr;
    }
    | KW_ALIAS alias_designator KW_IS name signature ';' {
        $$ = new VhdlParseTreeNode(PT_ALIAS_DECLARATION);
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
        $$->pieces[2] = nullptr;
        $$->pieces[3] = $5;
    }
    | KW_ALIAS alias_designator ':' subtype_indication
      KW_IS name signature ';' {
        $$ = new VhdlParseTreeNode(PT_ALIAS_DECLARATION);
        $$->pieces[0] = $2;
        $$->pieces[1] = $6;
        $$->pieces[2] = $4;
        $$->pieces[3] = $7;
    }

alias_designator:
    identifier
    | character_literal
    | string_literal        // was operator_symbol

/// Section 6.7
attribute_declaration:
    KW_ATTRIBUTE identifier ':' type_mark ';' {
        $$ = new VhdlParseTreeNode(PT_ATTRIBUTE_DECLARATION);
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
    }

/// Section 6.8
// generic_clause is expanded because why not, and port_clause is following
component_declaration:
    _real_component_declaration ';'
    | _real_component_declaration identifier ';' {
        $$ = $1;
        $$->pieces[3] = $2;
    }

_real_component_declaration:
    KW_COMPONENT identifier __maybe_is KW_END KW_COMPONENT {
        $$ = new VhdlParseTreeNode(PT_COMPONENT_DECLARATION);
        $$->pieces[0] = $2;
        $$->pieces[1] = nullptr;
        $$->pieces[2] = nullptr;
        $$->pieces[3] = nullptr;
    }
    | KW_COMPONENT identifier __maybe_is
      KW_GENERIC '(' interface_list ')' ';'
      KW_END KW_COMPONENT {
        $$ = new VhdlParseTreeNode(PT_COMPONENT_DECLARATION);
        $$->pieces[0] = $2;
        $$->pieces[1] = $6;
        $$->pieces[2] = nullptr;
        $$->pieces[3] = nullptr;
    }
    | KW_COMPONENT identifier __maybe_is
      KW_PORT '(' interface_list ')' ';'
      KW_END KW_COMPONENT {
        $$ = new VhdlParseTreeNode(PT_COMPONENT_DECLARATION);
        $$->pieces[0] = $2;
        $$->pieces[1] = nullptr;
        $$->pieces[2] = $6;
        $$->pieces[3] = nullptr;
    }
    | KW_COMPONENT identifier __maybe_is
      KW_GENERIC '(' interface_list ')' ';'
      KW_PORT '(' interface_list ')' ';'
      KW_END KW_COMPONENT {
        $$ = new VhdlParseTreeNode(PT_COMPONENT_DECLARATION);
        $$->pieces[0] = $2;
        $$->pieces[1] = $6;
        $$->pieces[2] = $11;
        $$->pieces[3] = nullptr;
    }

/// Section 6.9
group_template_declaration:
    KW_GROUP identifier KW_IS '(' entity_class_entry_list ')' ';' {
        $$ = new VhdlParseTreeNode(PT_GROUP_TEMPLATE_DECLARATION);
        $$->pieces[0] = $2;
        $$->pieces[1] = $5;
    }

entity_class_entry_list:
    entity_class_entry
    | entity_class_entry_list ',' entity_class_entry {
        $$ = new VhdlParseTreeNode(PT_ENTITY_CLASS_ENTRY_LIST);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

entity_class_entry:
    entity_class {
        $$ = new VhdlParseTreeNode(PT_ENTITY_CLASS_ENTRY);
        $$->boolean = false;
        $$->pieces[0] = $1;
    }
    | entity_class DL_BOX {
        $$ = new VhdlParseTreeNode(PT_ENTITY_CLASS_ENTRY);
        $$->boolean = true;
        $$->pieces[0] = $1;
    }

/// Section 6.10
group_declaration:
    KW_GROUP identifier ':' _simple_or_selected_name
    '(' _list_of_names ')' ';' {
        $$ = new VhdlParseTreeNode(PT_GROUP_DECLARATION);
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
        $$->pieces[2] = $6;
    }

////////////////////////// Specifications, section 7 //////////////////////////

/// Section 7.2
attribute_specification:
    KW_ATTRIBUTE identifier KW_OF entity_specification KW_IS expression ';' {
        $$ = new VhdlParseTreeNode(PT_ATTRIBUTE_SPECIFICATION);
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
        $$->pieces[2] = $6;
    }

entity_specification:
    entity_name_list ':' entity_class {
        $$ = new VhdlParseTreeNode(PT_ENTITY_SPECIFICATION);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

entity_class:
    KW_ENTITY {
        $$ = new VhdlParseTreeNode(PT_ENTITY_CLASS);
        $$->entity_class = ENTITY_ENTITY;
    }
    | KW_ARCHITECTURE {
        $$ = new VhdlParseTreeNode(PT_ENTITY_CLASS);
        $$->entity_class = ENTITY_ARCHITECTURE;
    }
    | KW_CONFIGURATION {
        $$ = new VhdlParseTreeNode(PT_ENTITY_CLASS);
        $$->entity_class = ENTITY_CONFIGURATION;
    }
    | KW_PROCEDURE {
        $$ = new VhdlParseTreeNode(PT_ENTITY_CLASS);
        $$->entity_class = ENTITY_PROCEDURE;
    }
    | KW_FUNCTION {
        $$ = new VhdlParseTreeNode(PT_ENTITY_CLASS);
        $$->entity_class = ENTITY_FUNCTION;
    }
    | KW_PACKAGE {
        $$ = new VhdlParseTreeNode(PT_ENTITY_CLASS);
        $$->entity_class = ENTITY_PACKAGE;
    }
    | KW_TYPE {
        $$ = new VhdlParseTreeNode(PT_ENTITY_CLASS);
        $$->entity_class = ENTITY_TYPE;
    }
    | KW_SUBTYPE {
        $$ = new VhdlParseTreeNode(PT_ENTITY_CLASS);
        $$->entity_class = ENTITY_SUBTYPE;
    }
    | KW_CONSTANT {
        $$ = new VhdlParseTreeNode(PT_ENTITY_CLASS);
        $$->entity_class = ENTITY_CONSTANT;
    }
    | KW_SIGNAL {
        $$ = new VhdlParseTreeNode(PT_ENTITY_CLASS);
        $$->entity_class = ENTITY_SIGNAL;
    }
    | KW_VARIABLE {
        $$ = new VhdlParseTreeNode(PT_ENTITY_CLASS);
        $$->entity_class = ENTITY_VARIABLE;
    }
    | KW_COMPONENT {
        $$ = new VhdlParseTreeNode(PT_ENTITY_CLASS);
        $$->entity_class = ENTITY_COMPONENT;
    }
    | KW_LABEL {
        $$ = new VhdlParseTreeNode(PT_ENTITY_CLASS);
        $$->entity_class = ENTITY_LABEL;
    }
    | KW_LITERAL {
        $$ = new VhdlParseTreeNode(PT_ENTITY_CLASS);
        $$->entity_class = ENTITY_LITERAL;
    }
    | KW_UNITS {
        $$ = new VhdlParseTreeNode(PT_ENTITY_CLASS);
        $$->entity_class = ENTITY_UNITS;
    }
    | KW_GROUP {
        $$ = new VhdlParseTreeNode(PT_ENTITY_CLASS);
        $$->entity_class = ENTITY_GROUP;
    }
    | KW_FILE {
        $$ = new VhdlParseTreeNode(PT_ENTITY_CLASS);
        $$->entity_class = ENTITY_FILE;
    }
    | KW_PROPERTY {
        $$ = new VhdlParseTreeNode(PT_ENTITY_CLASS);
        $$->entity_class = ENTITY_PROPERTY;
    }
    | KW_SEQUENCE {
        $$ = new VhdlParseTreeNode(PT_ENTITY_CLASS);
        $$->entity_class = ENTITY_SEQUENCE;
    }

entity_name_list:
    _one_or_more_entity_designators
    | KW_OTHERS {
        $$ = new VhdlParseTreeNode(PT_ENTITY_NAME_LIST_OTHERS);
    }
    | KW_ALL {
        $$ = new VhdlParseTreeNode(PT_ENTITY_NAME_LIST_ALL);
    }

_one_or_more_entity_designators:
    entity_designator
    | _one_or_more_entity_designators ',' entity_designator {
        $$ = new VhdlParseTreeNode(PT_ENTITY_NAME_LIST);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

entity_designator:
    entity_tag {
        $$ = new VhdlParseTreeNode(PT_ENTITY_DESIGNATOR);
        $$->pieces[0] = $1;
    }
    | entity_tag signature {
        $$ = new VhdlParseTreeNode(PT_ENTITY_DESIGNATOR);
        $$->pieces[0] = $1;
        $$->pieces[1] = $2;
    }

entity_tag:
    identifier
    | character_literal
    | string_literal

/// Section 7.3
configuration_specification:
    simple_configuration_specification
    | compound_configuration_specification

simple_configuration_specification:
    KW_FOR component_specification binding_indication ';' {
        $$ = new VhdlParseTreeNode(PT_SIMPLE_CONFIGURATION_SPECIFICATION);
        $$->pieces[0] = $2;
        $$->pieces[1] = $3;
    }
    | KW_FOR component_specification binding_indication ';' 
      KW_END KW_FOR ';' {
        $$ = new VhdlParseTreeNode(PT_SIMPLE_CONFIGURATION_SPECIFICATION);
        $$->pieces[0] = $2;
        $$->pieces[1] = $3;
    }

compound_configuration_specification:
    KW_FOR component_specification binding_indication ';' 
    _one_or_more_verification_unit_binding_indications
    KW_END KW_FOR ';' {
        $$ = new VhdlParseTreeNode(PT_COMPOUND_CONFIGURATION_SPECIFICATION);
        $$->pieces[0] = $2;
        $$->pieces[1] = $3;
        $$->pieces[2] = $5;
    }

component_specification:
    instantiation_list ':' name {
        $$ = new VhdlParseTreeNode(PT_COMPONENT_SPECIFICATION);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

instantiation_list:
    identifier_list     // was instantiation_label
    | KW_OTHERS {
        $$ = new VhdlParseTreeNode(PT_INSTANTIATION_LIST_OTHERS);
    }
    | KW_ALL {
        $$ = new VhdlParseTreeNode(PT_INSTANTIATION_LIST_ALL);
    }

binding_indication:
    %empty {
        $$ = new VhdlParseTreeNode(PT_BINDING_INDICATION);
        $$->pieces[0] = nullptr;
        $$->pieces[1] = nullptr;
        $$->pieces[2] = nullptr;
    }
    | KW_USE entity_aspect {
        $$ = new VhdlParseTreeNode(PT_BINDING_INDICATION);
        $$->pieces[0] = $2;
        $$->pieces[1] = nullptr;
        $$->pieces[2] = nullptr;
    }
    | generic_map_aspect {
        $$ = new VhdlParseTreeNode(PT_BINDING_INDICATION);
        $$->pieces[0] = nullptr;
        $$->pieces[1] = $1;
        $$->pieces[2] = nullptr;
    }
    | KW_USE entity_aspect generic_map_aspect {
        $$ = new VhdlParseTreeNode(PT_BINDING_INDICATION);
        $$->pieces[0] = $2;
        $$->pieces[1] = $3;
        $$->pieces[2] = nullptr;
    }
    | port_map_aspect {
        $$ = new VhdlParseTreeNode(PT_BINDING_INDICATION);
        $$->pieces[0] = nullptr;
        $$->pieces[1] = nullptr;
        $$->pieces[2] = $1;
    }
    | KW_USE entity_aspect port_map_aspect {
        $$ = new VhdlParseTreeNode(PT_BINDING_INDICATION);
        $$->pieces[0] = $2;
        $$->pieces[1] = nullptr;
        $$->pieces[2] = $3;
    }
    | generic_map_aspect port_map_aspect {
        $$ = new VhdlParseTreeNode(PT_BINDING_INDICATION);
        $$->pieces[0] = nullptr;
        $$->pieces[1] = $1;
        $$->pieces[2] = $2;
    }
    | KW_USE entity_aspect generic_map_aspect port_map_aspect {
        $$ = new VhdlParseTreeNode(PT_BINDING_INDICATION);
        $$->pieces[0] = $2;
        $$->pieces[1] = $3;
        $$->pieces[2] = $4;
    }

entity_aspect:
    _entity_aspect_entity
    | _entity_aspect_configuration
    | KW_OPEN {
        $$ = new VhdlParseTreeNode(PT_ENTITY_ASPECT_OPEN);
    }

_entity_aspect_entity:
    KW_ENTITY _simple_or_selected_name {
        $$ = new VhdlParseTreeNode(PT_ENTITY_ASPECT_ENTITY);
        $$->pieces[0] = $2;
    }
    | KW_ENTITY _simple_or_selected_name '(' identifier ')' {
        $$ = new VhdlParseTreeNode(PT_ENTITY_ASPECT_ENTITY);
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
    }

_entity_aspect_configuration:
    KW_CONFIGURATION _simple_or_selected_name {
        $$ = new VhdlParseTreeNode(PT_ENTITY_ASPECT_CONFIGURATION);
        $$->pieces[0] = $2;
    }

_one_or_more_verification_unit_binding_indications:
    verification_unit_binding_indication
    | _one_or_more_verification_unit_binding_indications
      verification_unit_binding_indication {
        $$ = new VhdlParseTreeNode(
            PT_VERIFICATION_UNIT_BINDING_INDICATION_LIST);
        $$->pieces[0] = $1;
        $$->pieces[1] = $2;
    }

verification_unit_binding_indication:
    KW_USE KW_VUNIT _list_of_names ';' {
        $$ = new VhdlParseTreeNode(PT_VERIFICATION_UNIT_BINDING_INDICATION);
        $$->pieces[0] = $3;
    }

/// Section 7.4
disconnection_specification:
    KW_DISCONNECT guarded_signal_specification KW_AFTER expression ';' {
        $$ = new VhdlParseTreeNode(PT_DISCONNECTION_SPECIFICATION);
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
    }

guarded_signal_specification:
    signal_list ':' type_mark {
        $$ = new VhdlParseTreeNode(PT_GUARDED_SIGNAL_SPECIFICATION);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

signal_list:
    _list_of_names
    | KW_OTHERS {
        $$ = new VhdlParseTreeNode(PT_SIGNAL_LIST_OTHERS);
    }
    | KW_ALL {
        $$ = new VhdlParseTreeNode(PT_SIGNAL_LIST_ALL);
    }

////////////////////////////// Names, section 8 //////////////////////////////

// This is a super hacked up version of the name grammar production
// It accepts far more than it should. This will be disambiguated in a second
// pass that is not part of the (generated) parser.
name:
    // We need to use this specialization rather than duplicating the contents
    // in order to make the grammar not have some reduce/reduce conflicts.
    function_name     
    | character_literal
    | _hack_name_for_association_list
    | _almost_attribute_name
    | external_name

// We need this in order to be able to slice/select after a function call
// with => in it
prefix:
    name
    | _definitely_function_call

_hack_name_for_association_list:
    // This handles anything that involves parentheses, including some things
    // that are actually a "primary." It needs to be disambiguated later in
    // second-stage parsing. However, it notably includes indexed and slice
    // names.
    prefix '(' _ambig_name_parens ')' {
        $$ = new VhdlParseTreeNode(PT_NAME_AMBIG_PARENS);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }
    | slice_name

// A number of things require a list of names
_list_of_names:
    name
    | _list_of_names ',' name {
        $$ = new VhdlParseTreeNode(PT_NAME_LIST);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

// This is a specialization of "name" because a number of other rules do need
// to refer to only function names and not all sorts of other ridiculous
// maybe-a-names.
function_name:
    _simple_or_selected_name
    | string_literal        // was operator_symbol

// This specialization is used for many <foo>_names in the grammar that refer
// to some type/entity/similar thing but not any arbitrary type of name.
// FIXME: This causes a whole bunch of shift/reduce conflicts
_simple_or_selected_name:
    identifier              // was simple_name
    | selected_name

/// Section 8.3
selected_name:
    prefix '.' suffix {
        $$ = new VhdlParseTreeNode(PT_NAME_SELECTED);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

suffix:
    identifier              // was simple_name
    | character_literal
    | string_literal        // was operator_symbol
    | KW_ALL    { $$ = new VhdlParseTreeNode(PT_TOK_ALL); }

/// Section 8.5
slice_name:
    prefix '(' _almost_discrete_range ')' {
        $$ = new VhdlParseTreeNode(PT_NAME_SLICE);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

/// Section 8.6
// Note that we do not handle the possible occurrence of (expression) at the
// end because it is ambiguous with function calls. _ambig_name_parens should
// pick that up.
_almost_attribute_name:
    prefix '\'' __attribute_kw_identifier_hack {
        $$ = new VhdlParseTreeNode(PT_NAME_ATTRIBUTE);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }
    | prefix signature '\'' __attribute_kw_identifier_hack {
        $$ = new VhdlParseTreeNode(PT_NAME_ATTRIBUTE);
        $$->pieces[0] = $1;
        $$->pieces[1] = $4;
        $$->pieces[2] = $2;
    }

// Apparently these keywords are possible names of attributes
__attribute_kw_identifier_hack:
    identifier
    | KW_RANGE {
        $$ = new VhdlParseTreeNode(PT_BASIC_ID);
        $$->str = new std::string("range");
    }
    | KW_SUBTYPE{
        $$ = new VhdlParseTreeNode(PT_BASIC_ID);
        $$->str = new std::string("subtype");
    }

// We need the actual attribute_name for range constraints. This introduces a
// S/R conflict.
attribute_name:
    _almost_attribute_name
    | _almost_attribute_name '(' expression ')' {
        $$ = $1;
        $$->pieces[3] = $3;
    }

/// Section 8.7
external_name:
    external_constant_name
    | external_signal_name
    | external_variable_name

external_constant_name:
    DL_LL KW_CONSTANT external_pathname ':' subtype_indication DL_RR {
        $$ = new VhdlParseTreeNode(PT_NAME_EXT_CONST);
        $$->pieces[0] = $3;
        $$->pieces[1] = $5;
    }

external_signal_name:
    DL_LL KW_SIGNAL external_pathname ':' subtype_indication DL_RR {
        $$ = new VhdlParseTreeNode(PT_NAME_EXT_SIG);
        $$->pieces[0] = $3;
        $$->pieces[1] = $5;
    }

external_variable_name:
    DL_LL KW_VARIABLE external_pathname ':' subtype_indication DL_RR {
        $$ = new VhdlParseTreeNode(PT_NAME_EXT_VAR);
        $$->pieces[0] = $3;
        $$->pieces[1] = $5;
    }

external_pathname:
    package_pathname
    | absolute_pathname
    | relative_pathname

package_pathname:
    '@' identifier '.' _one_or_more_ids_dots '.' identifier {
        $$ = new VhdlParseTreeNode(PT_PACKAGE_PATHNAME);
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
        $$->pieces[2] = $6;
    }

_one_or_more_ids_dots:
    identifier
    | _one_or_more_ids_dots '.' identifier {
        $$ = new VhdlParseTreeNode(PT_ID_LIST_REAL);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

absolute_pathname:
    '.' partial_pathname {
        $$ = new VhdlParseTreeNode(PT_ABSOLUTE_PATHNAME);
        $$->pieces[0] = $2;
    }

relative_pathname:
    partial_pathname {
        $$ = new VhdlParseTreeNode(PT_RELATIVE_PATHNAME);
        $$->pieces[0] = $1;
        $$->integer = 0;
    }
    | '^' '.' relative_pathname {
        $$ = $3;
        $$->integer++;
    }

partial_pathname:
    identifier {
        $$ = new VhdlParseTreeNode(PT_PARTIAL_PATHNAME);
        $$->pieces[0] = $1;
    }
    | _one_or_more_pathname_elements '.' identifier {
        $$ = new VhdlParseTreeNode(PT_PARTIAL_PATHNAME);
        $$->pieces[0] = $3;
        $$->pieces[1] = $1;
    }

_one_or_more_pathname_elements:
    pathname_element
    | _one_or_more_pathname_elements '.' pathname_element {
        $$ = new VhdlParseTreeNode(PT_PATHNAME_ELEMENT);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

pathname_element:
    identifier
    | identifier '(' expression ')' {
        $$ = new VhdlParseTreeNode(PT_PATHNAME_ELEMENT_GENERATE_LABEL);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

_ambig_name_parens:
    // This should handle indexed names, type conversions, some cases of
    // function calls, and very few cases of slice names (subtype indications
    // with neither a resolution indication nor a constraint?)
    _one_or_more_expressions

_one_or_more_expressions:
    expression
    | _one_or_more_expressions ',' expression {
        $$ = new VhdlParseTreeNode(PT_EXPRESSION_LIST);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

/////////////////////////// Expressions, section 9 ///////////////////////////

expression:
    logical_expression
    /// Section 9.2.9
    | DL_QQ primary {
        $$ = new VhdlParseTreeNode(PT_UNARY_OPERATOR);
        $$->op_type = OP_COND;
        $$->pieces[0] = $2;
    }

/// Section 9.2.2
logical_expression:
    relation
    | logical_expression KW_AND relation {
        $$ = new VhdlParseTreeNode(PT_BINARY_OPERATOR);
        $$->op_type = OP_AND;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }
    | logical_expression KW_OR relation {
        $$ = new VhdlParseTreeNode(PT_BINARY_OPERATOR);
        $$->op_type = OP_OR;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }
    | logical_expression KW_XOR relation {
        $$ = new VhdlParseTreeNode(PT_BINARY_OPERATOR);
        $$->op_type = OP_XOR;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }
    | relation KW_NAND relation {
        $$ = new VhdlParseTreeNode(PT_BINARY_OPERATOR);
        $$->op_type = OP_NAND;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }
    | relation KW_NOR relation {
        $$ = new VhdlParseTreeNode(PT_BINARY_OPERATOR);
        $$->op_type = OP_NOR;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }
    | logical_expression KW_XNOR relation {
        $$ = new VhdlParseTreeNode(PT_BINARY_OPERATOR);
        $$->op_type = OP_XNOR;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

/// Section 9.2.3
relation:
    shift_expression
    | shift_expression '=' shift_expression {
        $$ = new VhdlParseTreeNode(PT_BINARY_OPERATOR);
        $$->op_type = OP_EQ;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }
    | shift_expression DL_NEQ shift_expression {
        $$ = new VhdlParseTreeNode(PT_BINARY_OPERATOR);
        $$->op_type = OP_NEQ;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

    | shift_expression '<' shift_expression {
        $$ = new VhdlParseTreeNode(PT_BINARY_OPERATOR);
        $$->op_type = OP_LT;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

    | shift_expression DL_LEQ shift_expression {
        $$ = new VhdlParseTreeNode(PT_BINARY_OPERATOR);
        $$->op_type = OP_LTE;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

    | shift_expression '>' shift_expression {
        $$ = new VhdlParseTreeNode(PT_BINARY_OPERATOR);
        $$->op_type = OP_GT;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

    | shift_expression DL_GEQ shift_expression {
        $$ = new VhdlParseTreeNode(PT_BINARY_OPERATOR);
        $$->op_type = OP_GTE;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

    | shift_expression DL_MEQ shift_expression {
        $$ = new VhdlParseTreeNode(PT_BINARY_OPERATOR);
        $$->op_type = OP_MEQ;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

    | shift_expression DL_MNE shift_expression {
        $$ = new VhdlParseTreeNode(PT_BINARY_OPERATOR);
        $$->op_type = OP_MNE;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

    | shift_expression DL_MLT shift_expression {
        $$ = new VhdlParseTreeNode(PT_BINARY_OPERATOR);
        $$->op_type = OP_MLT;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

    | shift_expression DL_MLE shift_expression {
        $$ = new VhdlParseTreeNode(PT_BINARY_OPERATOR);
        $$->op_type = OP_MLE;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

    | shift_expression DL_MGT shift_expression {
        $$ = new VhdlParseTreeNode(PT_BINARY_OPERATOR);
        $$->op_type = OP_MGT;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

    | shift_expression DL_MGE shift_expression {
        $$ = new VhdlParseTreeNode(PT_BINARY_OPERATOR);
        $$->op_type = OP_MGE;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

/// Section 9.2.4
shift_expression:
    simple_expression
    | simple_expression KW_SLL simple_expression {
        $$ = new VhdlParseTreeNode(PT_BINARY_OPERATOR);
        $$->op_type = OP_SLL;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }
    | simple_expression KW_SRL simple_expression {
        $$ = new VhdlParseTreeNode(PT_BINARY_OPERATOR);
        $$->op_type = OP_SRL;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }
    | simple_expression KW_SLA simple_expression {
        $$ = new VhdlParseTreeNode(PT_BINARY_OPERATOR);
        $$->op_type = OP_SLA;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }
    | simple_expression KW_SRA simple_expression {
        $$ = new VhdlParseTreeNode(PT_BINARY_OPERATOR);
        $$->op_type = OP_SRA;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }
    | simple_expression KW_ROL simple_expression {
        $$ = new VhdlParseTreeNode(PT_BINARY_OPERATOR);
        $$->op_type = OP_ROL;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }
    | simple_expression KW_ROR simple_expression {
        $$ = new VhdlParseTreeNode(PT_BINARY_OPERATOR);
        $$->op_type = OP_ROR;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

/// Section 9.2.5
simple_expression:
    _term_with_sign
    | simple_expression '+' term {
        $$ = new VhdlParseTreeNode(PT_BINARY_OPERATOR);
        $$->op_type = OP_ADD;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }
    | simple_expression '-' term {
        $$ = new VhdlParseTreeNode(PT_BINARY_OPERATOR);
        $$->op_type = OP_SUB;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }
    | simple_expression '&' term {
        $$ = new VhdlParseTreeNode(PT_BINARY_OPERATOR);
        $$->op_type = OP_CONCAT;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

/// Section 9.2.6
// FIXME: Check if this precedence is right
_term_with_sign:
    term
    | '+' term {
        $$ = new VhdlParseTreeNode(PT_UNARY_OPERATOR);
        $$->op_type = OP_ADD;
        $$->pieces[0] = $2;
    }
    | '-' term {
        $$ = new VhdlParseTreeNode(PT_UNARY_OPERATOR);
        $$->op_type = OP_SUB;
        $$->pieces[0] = $2;
    }

/// Section 9.2.7
term:
    factor
    | term '*' factor {
        $$ = new VhdlParseTreeNode(PT_BINARY_OPERATOR);
        $$->op_type = OP_MUL;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }
    | term '/' factor {
        $$ = new VhdlParseTreeNode(PT_BINARY_OPERATOR);
        $$->op_type = OP_DIV;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }
    | term KW_MOD factor {
        $$ = new VhdlParseTreeNode(PT_BINARY_OPERATOR);
        $$->op_type = OP_MOD;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }
    | term KW_REM factor {
        $$ = new VhdlParseTreeNode(PT_BINARY_OPERATOR);
        $$->op_type = OP_REM;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

/// Section 9.2.2, 9.2.8
factor:
    primary
    | primary DL_EXP primary {
        $$ = new VhdlParseTreeNode(PT_BINARY_OPERATOR);
        $$->op_type = OP_EXP;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }
    | KW_ABS primary {
        $$ = new VhdlParseTreeNode(PT_UNARY_OPERATOR);
        $$->op_type = OP_ABS;
        $$->pieces[0] = $2;
    }
    | KW_NOT primary {
        $$ = new VhdlParseTreeNode(PT_UNARY_OPERATOR);
        $$->op_type = OP_NOT;
        $$->pieces[0] = $2;
    }
    | KW_AND primary {
        $$ = new VhdlParseTreeNode(PT_UNARY_OPERATOR);
        $$->op_type = OP_AND;
        $$->pieces[0] = $2;
    }
    | KW_OR primary {
        $$ = new VhdlParseTreeNode(PT_UNARY_OPERATOR);
        $$->op_type = OP_OR;
        $$->pieces[0] = $2;
    }
    | KW_NAND primary {
        $$ = new VhdlParseTreeNode(PT_UNARY_OPERATOR);
        $$->op_type = OP_NAND;
        $$->pieces[0] = $2;
    }
    | KW_NOR primary {
        $$ = new VhdlParseTreeNode(PT_UNARY_OPERATOR);
        $$->op_type = OP_NOR;
        $$->pieces[0] = $2;
    }
    | KW_XOR primary {
        $$ = new VhdlParseTreeNode(PT_UNARY_OPERATOR);
        $$->op_type = OP_XOR;
        $$->pieces[0] = $2;
    }
    | KW_XNOR primary {
        $$ = new VhdlParseTreeNode(PT_UNARY_OPERATOR);
        $$->op_type = OP_XNOR;
        $$->pieces[0] = $2;
    }

/// Section 9.3
// Here is a hacked "primary" rule that relies on "name" to parse a bunch of
// stuff that will be disambiguated later
primary:
    name
    // literal is folded in
    | numeric_literal
    // enumeration and string literals already happen because of name
    | bit_string_literal
    | KW_NULL   { $$ = new VhdlParseTreeNode(PT_LIT_NULL); }
    | aggregate
    // Some function_calls are handled by name
    | _definitely_function_call
    | qualified_expression
    // type_conversion is caught by name
    | allocator
    | '(' expression ')' {
        $$ = $2;
    }

/// Section 9.3.2
numeric_literal:
    abstract_literal
    | _almost_physical_literal

/// Section 9.3.3
aggregate:
    '(' _two_or_more_element_association ')' {
        $$ = $2;
    }
    | '(' _must_have_choice_element_association ')' {
        $$ = new VhdlParseTreeNode(PT_AGGREGATE);
        $$->pieces[0] = nullptr;
        $$->pieces[1] = $2;
    }

_two_or_more_element_association:
    element_association ',' element_association {
        $$ = new VhdlParseTreeNode(PT_AGGREGATE);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }
    | _two_or_more_element_association ',' element_association {
        $$ = new VhdlParseTreeNode(PT_AGGREGATE);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

element_association:
    expression {
        $$ = new VhdlParseTreeNode(PT_ELEMENT_ASSOCIATION);
        $$->pieces[0] = $1;
    }
    | _must_have_choice_element_association

_must_have_choice_element_association:
    choices DL_ARR expression {
        $$ = new VhdlParseTreeNode(PT_ELEMENT_ASSOCIATION);
        $$->pieces[0] = $3;
        $$->pieces[1] = $1;
    }

choices:
    choice
    | choices '|' choice {
        $$ = new VhdlParseTreeNode(PT_CHOICES);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

choice:
    simple_expression
    | _almost_discrete_range
    // simple_name is included in simple_expression
    | KW_OTHERS {
        $$ = new VhdlParseTreeNode(PT_CHOICES_OTHER);
    }

/// Section 9.3.4
// Handles only function calls that contain "=>" in the parameters. Other ones
// are caught by "name".
_definitely_function_call:
    function_name '(' _definitely_parameter_association_list ')' {
        $$ = new VhdlParseTreeNode(PT_FUNCTION_CALL);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

/// Section 9.3.5
qualified_expression:
    type_mark '\'' '(' expression ')' {
        $$ = new VhdlParseTreeNode(PT_QUALIFIED_EXPRESSION);
        $$->pieces[0] = $1;
        $$->pieces[1] = $4;
    }
    | type_mark '\'' aggregate {
        $$ = new VhdlParseTreeNode(PT_QUALIFIED_EXPRESSION);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

/// Section 9.3.7
allocator:
    KW_NEW _allocator_subtype_indication {
        $$ = new VhdlParseTreeNode(PT_ALLOCATOR);
        $$->pieces[0] = $2;
    }
    | KW_NEW qualified_expression {
        $$ = new VhdlParseTreeNode(PT_ALLOCATOR);
        $$->pieces[0] = $2;
    }

////////////////////// Sequential statements, section 10 //////////////////////

sequence_of_statements:
    %empty
    | _real_sequence_of_statements

// We need this or else the %empty can cause ambiguity.
_real_sequence_of_statements:
    sequential_statement
    | _real_sequence_of_statements sequential_statement {
        $$ = new VhdlParseTreeNode(PT_SEQUENCE_OF_STATEMENTS);
        $$->pieces[0] = $1;
        $$->pieces[1] = $2;
    }

// Store line number information
sequential_statement: _sequential_statement { STORE_LOC($$, @$); }

_sequential_statement:
    _real_sequential_statement ';'
    | identifier ':' _real_sequential_statement ';' {
        $$ = new VhdlParseTreeNode(PT_STATEMENT_LABEL);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

_real_sequential_statement:
    wait_statement
    | assertion_statement
    | report_statement
    | signal_assignment_statement
    | variable_assignment_statement
    | procedure_call_statement
    | if_statement
    | case_statement
    | loop_statement
    | next_statement
    | exit_statement
    | return_statement
    | null_statement

/// Section 10.2
wait_statement:
    KW_WAIT sensitivity_clause condition_clause timeout_clause {
        $$ = new VhdlParseTreeNode(PT_WAIT_STATEMENT);
        $$->pieces[0] = $2;
        $$->pieces[1] = $3;
        $$->pieces[2] = $4;
    }

sensitivity_clause:
    %empty
    | KW_ON _list_of_names {
        $$ = $2;
    }

condition_clause:
    %empty
    | KW_UNTIL expression {
        $$ = $2;
    }

timeout_clause:
    %empty
    | KW_FOR expression {
        $$ = $2;
    }

/// Section 10.3
// Label and semicolon factored out
assertion_statement:
    assertion

assertion:
    KW_ASSERT expression {
        $$ = new VhdlParseTreeNode(PT_ASSERTION_STATEMENT);
        $$->pieces[0] = $2;
        $$->pieces[1] = nullptr;
        $$->pieces[2] = nullptr;
    }
    | KW_ASSERT expression KW_REPORT expression {
        $$ = new VhdlParseTreeNode(PT_ASSERTION_STATEMENT);
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
        $$->pieces[2] = nullptr;
    }
    | KW_ASSERT expression KW_SEVERITY expression {
        $$ = new VhdlParseTreeNode(PT_ASSERTION_STATEMENT);
        $$->pieces[0] = $2;
        $$->pieces[1] = nullptr;
        $$->pieces[2] = $4;
    }
    | KW_ASSERT expression KW_REPORT expression KW_SEVERITY expression {
        $$ = new VhdlParseTreeNode(PT_ASSERTION_STATEMENT);
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
        $$->pieces[2] = $6;
    }

/// Section 10.4
report_statement:
    KW_REPORT expression {
        $$ = new VhdlParseTreeNode(PT_REPORT_STATEMENT);
        $$->pieces[0] = $2;
        $$->pieces[1] = nullptr;
    }
    | KW_REPORT expression KW_SEVERITY expression {
        $$ = new VhdlParseTreeNode(PT_REPORT_STATEMENT);
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
    }

/// Section 10.5
signal_assignment_statement:
    simple_signal_assignment
    | conditional_signal_assignment
    | selected_signal_assignment

/// Section 10.5.2
simple_signal_assignment:
    simple_waveform_assignment
    | simple_force_assignment
    | simple_release_assignment

simple_waveform_assignment:
    target DL_LEQ waveform {
        $$ = new VhdlParseTreeNode(PT_SIMPLE_WAVEFORM_ASSIGNMENT);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
        $$->pieces[2] = nullptr;
    }
    | target DL_LEQ delay_mechanism waveform {
        $$ = new VhdlParseTreeNode(PT_SIMPLE_WAVEFORM_ASSIGNMENT);
        $$->pieces[0] = $1;
        $$->pieces[1] = $4;
        $$->pieces[2] = $3;
    }

simple_force_assignment:
    target DL_LEQ KW_FORCE expression {
        $$ = new VhdlParseTreeNode(PT_SIMPLE_FORCE_ASSIGNMENT);
        $$->force_mode = FORCE_UNSPEC;
        $$->pieces[0] = $1;
        $$->pieces[1] = $4;
    }
    | target DL_LEQ KW_FORCE KW_IN expression {
        $$ = new VhdlParseTreeNode(PT_SIMPLE_FORCE_ASSIGNMENT);
        $$->force_mode = FORCE_IN;
        $$->pieces[0] = $1;
        $$->pieces[1] = $5;
    }
    | target DL_LEQ KW_FORCE KW_OUT expression {
        $$ = new VhdlParseTreeNode(PT_SIMPLE_FORCE_ASSIGNMENT);
        $$->force_mode = FORCE_OUT;
        $$->pieces[0] = $1;
        $$->pieces[1] = $5;
    }

simple_release_assignment:
    target DL_LEQ KW_RELEASE {
        $$ = new VhdlParseTreeNode(PT_SIMPLE_RELEASE_ASSIGNMENT);
        $$->force_mode = FORCE_UNSPEC;
        $$->pieces[0] = $1;
    }
    | target DL_LEQ KW_RELEASE KW_IN {
        $$ = new VhdlParseTreeNode(PT_SIMPLE_RELEASE_ASSIGNMENT);
        $$->force_mode = FORCE_IN;
        $$->pieces[0] = $1;
    }
    | target DL_LEQ KW_RELEASE KW_OUT {
        $$ = new VhdlParseTreeNode(PT_SIMPLE_RELEASE_ASSIGNMENT);
        $$->force_mode = FORCE_OUT;
        $$->pieces[0] = $1;
    }

delay_mechanism:
    KW_TRANSPORT {
        $$ = new VhdlParseTreeNode(PT_DELAY_TRANSPORT);
    }
    | KW_INERTIAL {
        $$ = new VhdlParseTreeNode(PT_DELAY_INERTIAL);
        $$->pieces[0] = nullptr;
    }
    | KW_REJECT expression KW_INERTIAL {
        $$ = new VhdlParseTreeNode(PT_DELAY_INERTIAL);
        $$->pieces[0] = $2;
    }

target:
    name 
    | aggregate

waveform:
    KW_UNAFFECTED {
        $$ = new VhdlParseTreeNode(PT_WAVEFORM_UNAFFECTED);
    }
    | _one_or_more_waveform_elements

_one_or_more_waveform_elements:
    waveform_element
    | _one_or_more_waveform_elements ',' waveform_element {
        $$ = new VhdlParseTreeNode(PT_WAVEFORM);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

waveform_element:
    expression {
        $$ = new VhdlParseTreeNode(PT_WAVEFORM_ELEMENT);
        $$->pieces[0] = $1;
        $$->pieces[1] = nullptr;
    }
    | expression KW_AFTER expression {
        $$ = new VhdlParseTreeNode(PT_WAVEFORM_ELEMENT);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }
    // null gets included in expression

/// Section 10.5.3
conditional_signal_assignment:
    conditional_waveform_assignment
    | conditional_force_assignment

conditional_waveform_assignment:
    target DL_LEQ conditional_waveforms {
        $$ = new VhdlParseTreeNode(PT_CONDITIONAL_WAVEFORM_ASSIGNMENT);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
        $$->pieces[2] = nullptr;
    }
    | target DL_LEQ delay_mechanism conditional_waveforms {
        $$ = new VhdlParseTreeNode(PT_CONDITIONAL_WAVEFORM_ASSIGNMENT);
        $$->pieces[0] = $1;
        $$->pieces[1] = $4;
        $$->pieces[2] = $3;
    }

conditional_waveforms:
    waveform KW_WHEN expression {
        $$ = new VhdlParseTreeNode(PT_CONDITIONAL_WAVEFORMS);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
        $$->pieces[2] = nullptr;
        $$->pieces[3] = nullptr;
    }
    | waveform KW_WHEN expression KW_ELSE waveform {
        $$ = new VhdlParseTreeNode(PT_CONDITIONAL_WAVEFORMS);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
        $$->pieces[2] = nullptr;
        $$->pieces[3] = $5;
    }
    | waveform KW_WHEN expression _one_or_more_conditional_waveform_elses
      KW_ELSE waveform {
        $$ = new VhdlParseTreeNode(PT_CONDITIONAL_WAVEFORMS);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
        $$->pieces[2] = $4;
        $$->pieces[3] = $6;
    }

_one_or_more_conditional_waveform_elses:
    _conditional_waveform_else
    | _one_or_more_conditional_waveform_elses _conditional_waveform_else {
        $$ = new VhdlParseTreeNode(PT_CONDITIONAL_WAVEFORM_ELSE_LIST);
        $$->pieces[0] = $1;
        $$->pieces[1] = $2;
    }

_conditional_waveform_else:
    KW_ELSE waveform KW_WHEN expression {
        $$ = new VhdlParseTreeNode(PT_CONDITIONAL_WAVEFORM_ELSE);
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
    }

conditional_force_assignment:
    target DL_LEQ KW_FORCE conditional_expressions {
        $$ = new VhdlParseTreeNode(PT_CONDITIONAL_FORCE_ASSIGNMENT);
        $$->force_mode = FORCE_UNSPEC;
        $$->pieces[0] = $1;
        $$->pieces[1] = $4;
    }
    | target DL_LEQ KW_FORCE KW_IN conditional_expressions {
        $$ = new VhdlParseTreeNode(PT_CONDITIONAL_FORCE_ASSIGNMENT);
        $$->force_mode = FORCE_IN;
        $$->pieces[0] = $1;
        $$->pieces[1] = $5;
    }
    | target DL_LEQ KW_FORCE KW_OUT conditional_expressions {
        $$ = new VhdlParseTreeNode(PT_CONDITIONAL_FORCE_ASSIGNMENT);
        $$->force_mode = FORCE_OUT;
        $$->pieces[0] = $1;
        $$->pieces[1] = $5;
    }

conditional_expressions:
    expression KW_WHEN expression {
        $$ = new VhdlParseTreeNode(PT_CONDITIONAL_EXPRESSIONS);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
        $$->pieces[2] = nullptr;
        $$->pieces[3] = nullptr;
    }
    | expression KW_WHEN expression KW_ELSE expression {
        $$ = new VhdlParseTreeNode(PT_CONDITIONAL_EXPRESSIONS);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
        $$->pieces[2] = nullptr;
        $$->pieces[3] = $5;
    }
    | expression KW_WHEN expression _one_or_more_conditional_expression_elses
      KW_ELSE expression {
        $$ = new VhdlParseTreeNode(PT_CONDITIONAL_EXPRESSIONS);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
        $$->pieces[2] = $4;
        $$->pieces[3] = $6;
    }

_one_or_more_conditional_expression_elses:
    _conditional_expression_else
    | _one_or_more_conditional_expression_elses _conditional_expression_else {
        $$ = new VhdlParseTreeNode(PT_CONDITIONAL_EXPRESSION_ELSE_LIST);
        $$->pieces[0] = $1;
        $$->pieces[1] = $2;
    }

_conditional_expression_else:
    KW_ELSE expression KW_WHEN expression {
        $$ = new VhdlParseTreeNode(PT_CONDITIONAL_EXPRESSION_ELSE);
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
    }

/// Section 10.5.4
selected_signal_assignment:
    selected_waveform_assignment
    | selected_force_assignment

selected_waveform_assignment:
    KW_WITH expression KW_SELECT target DL_LEQ selected_waveforms {
        $$ = new VhdlParseTreeNode(PT_SELECTED_WAVEFORM_ASSIGNMENT);
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
        $$->pieces[2] = $6;
        $$->pieces[3] = nullptr;
        $$->boolean = false;
    }
    | KW_WITH expression KW_SELECT '?' target DL_LEQ selected_waveforms {
        $$ = new VhdlParseTreeNode(PT_SELECTED_WAVEFORM_ASSIGNMENT);
        $$->pieces[0] = $2;
        $$->pieces[1] = $5;
        $$->pieces[2] = $7;
        $$->pieces[3] = nullptr;
        $$->boolean = true;
    }
    | KW_WITH expression KW_SELECT
      target DL_LEQ delay_mechanism selected_waveforms {
        $$ = new VhdlParseTreeNode(PT_SELECTED_WAVEFORM_ASSIGNMENT);
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
        $$->pieces[2] = $7;
        $$->pieces[3] = $6;
        $$->boolean = false;
    }
    | KW_WITH expression KW_SELECT '?'
      target DL_LEQ delay_mechanism selected_waveforms {
        $$ = new VhdlParseTreeNode(PT_SELECTED_WAVEFORM_ASSIGNMENT);
        $$->pieces[0] = $2;
        $$->pieces[1] = $5;
        $$->pieces[2] = $8;
        $$->pieces[3] = $7;
        $$->boolean = true;
    }

selected_waveforms:
    _selected_waveform
    | selected_waveforms ',' _selected_waveform {
        $$ = new VhdlParseTreeNode(PT_SELECTED_WAVEFORMS);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

_selected_waveform:
    waveform KW_WHEN choices {
        $$ = new VhdlParseTreeNode(PT_SELECTED_WAVEFORM);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

selected_force_assignment:
    KW_WITH expression KW_SELECT target DL_LEQ KW_FORCE selected_expressions {
        $$ = new VhdlParseTreeNode(PT_SELECTED_FORCE_ASSIGNMENT);
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
        $$->pieces[2] = $7;
        $$->force_mode = FORCE_UNSPEC;
        $$->boolean = false;
    }
    | KW_WITH expression KW_SELECT target
      DL_LEQ KW_FORCE KW_IN selected_expressions {
        $$ = new VhdlParseTreeNode(PT_SELECTED_FORCE_ASSIGNMENT);
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
        $$->pieces[2] = $8;
        $$->force_mode = FORCE_IN;
        $$->boolean = false;
    }
    | KW_WITH expression KW_SELECT target
      DL_LEQ KW_FORCE KW_OUT selected_expressions {
        $$ = new VhdlParseTreeNode(PT_SELECTED_FORCE_ASSIGNMENT);
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
        $$->pieces[2] = $8;
        $$->force_mode = FORCE_OUT;
        $$->boolean = false;
    }
    | KW_WITH expression KW_SELECT '?' target
      DL_LEQ KW_FORCE selected_expressions {
        $$ = new VhdlParseTreeNode(PT_SELECTED_FORCE_ASSIGNMENT);
        $$->pieces[0] = $2;
        $$->pieces[1] = $5;
        $$->pieces[2] = $8;
        $$->force_mode = FORCE_UNSPEC;
        $$->boolean = true;
    }
    | KW_WITH expression KW_SELECT '?' target
      DL_LEQ KW_FORCE KW_IN selected_expressions {
        $$ = new VhdlParseTreeNode(PT_SELECTED_FORCE_ASSIGNMENT);
        $$->pieces[0] = $2;
        $$->pieces[1] = $5;
        $$->pieces[2] = $9;
        $$->force_mode = FORCE_IN;
        $$->boolean = true;
    }
    | KW_WITH expression KW_SELECT '?' target
      DL_LEQ KW_FORCE KW_OUT selected_expressions {
        $$ = new VhdlParseTreeNode(PT_SELECTED_FORCE_ASSIGNMENT);
        $$->pieces[0] = $2;
        $$->pieces[1] = $5;
        $$->pieces[2] = $9;
        $$->force_mode = FORCE_OUT;
        $$->boolean = true;
    }

selected_expressions:
    _selected_expression
    | selected_expressions ',' _selected_expression {
        $$ = new VhdlParseTreeNode(PT_SELECTED_EXPRESSIONS);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

_selected_expression:
    expression KW_WHEN choices {
        $$ = new VhdlParseTreeNode(PT_SELECTED_EXPRESSION);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

/// Section 10.6
variable_assignment_statement:
    simple_variable_assignment
    | conditional_variable_assignment
    | selected_variable_assignment

simple_variable_assignment:
    target DL_ASS expression {
        $$ = new VhdlParseTreeNode(PT_SIMPLE_VARIABLE_ASSIGNMENT);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

conditional_variable_assignment:
    target DL_ASS conditional_expressions {
        $$ = new VhdlParseTreeNode(PT_CONDITIONAL_VARIABLE_ASSIGNMENT);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

selected_variable_assignment:
    KW_WITH expression KW_SELECT target DL_ASS selected_expressions {
        $$ = new VhdlParseTreeNode(PT_SELECTED_VARIABLE_ASSIGNMENT);
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
        $$->pieces[2] = $6;
        $$->boolean = false;
    }
    | KW_WITH expression KW_SELECT '?' target DL_ASS selected_expressions {
        $$ = new VhdlParseTreeNode(PT_SELECTED_VARIABLE_ASSIGNMENT);
        $$->pieces[0] = $2;
        $$->pieces[1] = $5;
        $$->pieces[2] = $7;
        $$->boolean = true;
    }

/// Section 10.7
// Because of how we refactored the label logic out of statements, this is
// a direct passthrough
procedure_call_statement:
    procedure_call

procedure_call:
    // Fun, accepts lots of crap. Functions and procedures basically look
    // about the same though, so the hacks we have for functions should be
    // sufficient.
    name
    | _definitely_function_call

/// Section 10.8
if_statement:
    _real_if_statement
    | _real_if_statement identifier {
        $$ = $1;
        $$->pieces[4] = $2;
    }

_real_if_statement:
    KW_IF expression KW_THEN sequence_of_statements KW_END KW_IF {
        $$ = new VhdlParseTreeNode(PT_IF_STATEMENT);
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
        $$->pieces[2] = nullptr;
        $$->pieces[3] = nullptr;
        $$->pieces[4] = nullptr;
    }
    | KW_IF expression KW_THEN sequence_of_statements _one_or_more_elsifs
      KW_END KW_IF {
        $$ = new VhdlParseTreeNode(PT_IF_STATEMENT);
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
        $$->pieces[2] = $5;
        $$->pieces[3] = nullptr;
        $$->pieces[4] = nullptr;
    }
    | KW_IF expression KW_THEN sequence_of_statements
      KW_ELSE sequence_of_statements KW_END KW_IF {
        $$ = new VhdlParseTreeNode(PT_IF_STATEMENT);
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
        $$->pieces[2] = nullptr;
        $$->pieces[3] = $6;
        $$->pieces[4] = nullptr;
    }
    | KW_IF expression KW_THEN sequence_of_statements 
      _one_or_more_elsifs KW_ELSE sequence_of_statements KW_END KW_IF {
        $$ = new VhdlParseTreeNode(PT_IF_STATEMENT);
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
        $$->pieces[2] = $5;
        $$->pieces[3] = $7;
        $$->pieces[4] = nullptr;
    }

_one_or_more_elsifs:
    _elsif
    | _one_or_more_elsifs _elsif {
        $$ = new VhdlParseTreeNode(PT_ELSIF_LIST);
        $$->pieces[0] = $1;
        $$->pieces[1] = $2;
    }

_elsif:
    KW_ELSIF expression KW_THEN sequence_of_statements {
        $$ = new VhdlParseTreeNode(PT_ELSIF);
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
    }

/// Section 10.9
case_statement:
    _real_case_statement
    | _real_case_statement identifier {
        $$ = $1;
        $$->pieces[2] = $2;
    }

_real_case_statement:
    KW_CASE expression KW_IS _one_or_more_case_statement_alternatives
    KW_END KW_CASE {
        $$ = new VhdlParseTreeNode(PT_CASE_STATEMENT);
        $$->boolean = false;
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
        $$->pieces[2] = nullptr;
    }
    | KW_CASE '?' expression KW_IS _one_or_more_case_statement_alternatives
      KW_END KW_CASE '?' {
        $$ = new VhdlParseTreeNode(PT_CASE_STATEMENT);
        $$->boolean = true;
        $$->pieces[0] = $3;
        $$->pieces[1] = $5;
        $$->pieces[2] = nullptr;
    }

_one_or_more_case_statement_alternatives:
    case_statement_alternative
    | _one_or_more_case_statement_alternatives case_statement_alternative {
        $$ = new VhdlParseTreeNode(PT_CASE_STATEMENT_ALTERNATIVE_LIST);
        $$->pieces[0] = $1;
        $$->pieces[1] = $2;
    }

case_statement_alternative:
    KW_WHEN choices DL_ARR sequence_of_statements {
        $$ = new VhdlParseTreeNode(PT_CASE_STATEMENT_ALTERNATIVE);
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
    }

/// Section 10.10
loop_statement:
    _real_loop_statement
    | _real_loop_statement identifier {
        $$ = $1;
        $$->pieces[2] = $2;
    }

_real_loop_statement:
    KW_LOOP sequence_of_statements KW_END KW_LOOP {
        $$ = new VhdlParseTreeNode(PT_LOOP_STATEMENT);
        $$->pieces[0] = $2;
        $$->pieces[1] = nullptr;
        $$->pieces[2] = nullptr;
    }
    | iteration_scheme KW_LOOP sequence_of_statements KW_END KW_LOOP {
        $$ = new VhdlParseTreeNode(PT_LOOP_STATEMENT);
        $$->pieces[0] = $3;
        $$->pieces[1] = $1;
        $$->pieces[2] = nullptr;
    }

iteration_scheme:
    KW_WHILE expression {
        $$ = new VhdlParseTreeNode(PT_ITERATION_WHILE);
        $$->pieces[0] = $2;
    }
    | KW_FOR parameter_specification {
        $$ = new VhdlParseTreeNode(PT_ITERATION_FOR);
        $$->pieces[0] = $2;
    }

parameter_specification:
    identifier KW_IN discrete_range {
        $$ = new VhdlParseTreeNode(PT_PARAMETER_SPECIFICATION);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

/// Section 10.11
next_statement:
    KW_NEXT {
        $$ = new VhdlParseTreeNode(PT_NEXT_STATEMENT);
        $$->pieces[0] = nullptr;
        $$->pieces[1] = nullptr;
    }
    | KW_NEXT identifier {
        $$ = new VhdlParseTreeNode(PT_NEXT_STATEMENT);
        $$->pieces[0] = $2;
        $$->pieces[1] = nullptr;
    }
    | KW_NEXT KW_WHEN expression {
        $$ = new VhdlParseTreeNode(PT_NEXT_STATEMENT);
        $$->pieces[0] = nullptr;
        $$->pieces[1] = $3;
    }
    | KW_NEXT identifier KW_WHEN expression {
        $$ = new VhdlParseTreeNode(PT_NEXT_STATEMENT);
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
    }

/// Section 10.12
exit_statement:
    KW_EXIT {
        $$ = new VhdlParseTreeNode(PT_EXIT_STATEMENT);
        $$->pieces[0] = nullptr;
        $$->pieces[1] = nullptr;
    }
    | KW_EXIT identifier {
        $$ = new VhdlParseTreeNode(PT_EXIT_STATEMENT);
        $$->pieces[0] = $2;
        $$->pieces[1] = nullptr;
    }
    | KW_EXIT KW_WHEN expression {
        $$ = new VhdlParseTreeNode(PT_EXIT_STATEMENT);
        $$->pieces[0] = nullptr;
        $$->pieces[1] = $3;
    }
    | KW_EXIT identifier KW_WHEN expression {
        $$ = new VhdlParseTreeNode(PT_EXIT_STATEMENT);
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
    }

/// Section 10.13
return_statement:
    KW_RETURN {
        $$ = new VhdlParseTreeNode(PT_RETURN_STATEMENT);
    }
    | KW_RETURN expression {
        $$ = new VhdlParseTreeNode(PT_RETURN_STATEMENT);
        $$->pieces[0] = $2;
    }

/// Section 10.14
null_statement:
    KW_NULL {
        $$ = new VhdlParseTreeNode(PT_NULL_STATEMENT);
    }

////////////////////// Concurrent statements, section 11 //////////////////////

/// Section 11.1

// Store line number information
concurrent_statement: _concurrent_statement { STORE_LOC($$, @$); }

_concurrent_statement:
    block_statement
    | process_statement
    | concurrent_procedure_call_statement
    | concurrent_assertion_statement
    | concurrent_signal_assignment_statement
    | component_instantiation_statement
    | generate_statement

_sequence_of_concurrent_statements:
    %empty
    | _real_sequence_of_concurrent_statements

// We need this or else the %empty can cause ambiguity.
_real_sequence_of_concurrent_statements:
    concurrent_statement
    | _real_sequence_of_concurrent_statements concurrent_statement {
        $$ = new VhdlParseTreeNode(PT_SEQUENCE_OF_CONCURRENT_STATEMENTS);
        $$->pieces[0] = $1;
        $$->pieces[1] = $2;
    }

/// Section 11.2
block_statement:
    _real_block_statement ';'
    | _real_block_statement identifier ';' {
        $$ = $1;
        $$->pieces[5] = $2;
    }

_real_block_statement:
    identifier ':' KW_BLOCK __maybe_is
    block_header block_declarative_part KW_BEGIN
    _sequence_of_concurrent_statements KW_END KW_BLOCK {
        $$ = new VhdlParseTreeNode(PT_BLOCK);
        $$->pieces[0] = $1;
        $$->pieces[1] = $5;
        $$->pieces[2] = nullptr;
        $$->pieces[3] = $6;
        $$->pieces[4] = $8;
    }
    | identifier ':' KW_BLOCK '(' expression ')' __maybe_is
      block_header block_declarative_part KW_BEGIN
      _sequence_of_concurrent_statements KW_END KW_BLOCK {
        $$ = new VhdlParseTreeNode(PT_BLOCK);
        $$->pieces[0] = $1;
        $$->pieces[1] = $8;
        $$->pieces[2] = $5;
        $$->pieces[3] = $9;
        $$->pieces[4] = $11;
    }

block_declarative_part:
    %empty
    | _real_block_declarative_part

_real_block_declarative_part:
    block_declarative_item
    | _real_block_declarative_part block_declarative_item {
        $$ = new VhdlParseTreeNode(PT_DECLARATION_LIST);
        $$->pieces[0] = $1;
        $$->pieces[1] = $2;
    }

block_header:
    %empty
    | _block_header_generic_part
    | _block_header_port_part
    | _block_header_generic_part _block_header_port_part {
        // FIXME: Ugly
        $$ = $1;
        $$->pieces[2] = $2->pieces[2];
        $$->pieces[3] = $2->pieces[3];
        $2->pieces[2] = nullptr;
        $2->pieces[3] = nullptr;
        delete $2;
    }

_block_header_generic_part:
    KW_GENERIC '(' interface_list ')' ';' {
        $$ = new VhdlParseTreeNode(PT_BLOCK_HEADER);
        $$->pieces[0] = $3;
        $$->pieces[1] = nullptr;
        $$->pieces[2] = nullptr;
        $$->pieces[3] = nullptr;
    }
    | KW_GENERIC '(' interface_list ')' ';' generic_map_aspect ';' {
        $$ = new VhdlParseTreeNode(PT_BLOCK_HEADER);
        $$->pieces[0] = $3;
        $$->pieces[1] = $6;
        $$->pieces[2] = nullptr;
        $$->pieces[3] = nullptr;
    }

_block_header_port_part:
    KW_PORT '(' interface_list ')' ';' {
        $$ = new VhdlParseTreeNode(PT_BLOCK_HEADER);
        $$->pieces[0] = nullptr;
        $$->pieces[1] = nullptr;
        $$->pieces[2] = $3;
        $$->pieces[3] = nullptr;
    }
    | KW_PORT '(' interface_list ')' ';' port_map_aspect ';' {
        $$ = new VhdlParseTreeNode(PT_BLOCK_HEADER);
        $$->pieces[0] = nullptr;
        $$->pieces[1] = nullptr;
        $$->pieces[2] = $3;
        $$->pieces[3] = $6;
    }

/// Section 11.3
process_statement:
    _real_process_statement ';'
    | identifier ':' _real_process_statement ';' {
        $$ = $3;
        $$->pieces[0] = $1;
    }
    | _real_process_statement identifier ';' {
        $$ = $1;
        $$->pieces[3] = $2;
    }
    | identifier ':' _real_process_statement identifier ';' {
        $$ = $3;
        $$->pieces[0] = $1;
        $$->pieces[3] = $4;
    }

_real_process_statement:
    KW_PROCESS __maybe_is process_declarative_part KW_BEGIN
    sequence_of_statements KW_END KW_PROCESS {
        $$ = new VhdlParseTreeNode(PT_PROCESS);
        $$->boolean = false;
        $$->pieces[0] = nullptr;
        $$->pieces[1] = $3;
        $$->pieces[2] = $5;
        $$->pieces[3] = nullptr;
        $$->pieces[4] = nullptr;
    }
    | KW_PROCESS '(' process_sensitivity_list ')' __maybe_is
      process_declarative_part KW_BEGIN
      sequence_of_statements KW_END KW_PROCESS {
        $$ = new VhdlParseTreeNode(PT_PROCESS);
        $$->boolean = false;
        $$->pieces[0] = nullptr;
        $$->pieces[1] = $6;
        $$->pieces[2] = $8;
        $$->pieces[3] = nullptr;
        $$->pieces[4] = $3;
    }
    | KW_POSTPONED KW_PROCESS __maybe_is process_declarative_part KW_BEGIN
      sequence_of_statements KW_END KW_POSTPONED KW_PROCESS {
        $$ = new VhdlParseTreeNode(PT_PROCESS);
        $$->boolean = true;
        $$->pieces[0] = nullptr;
        $$->pieces[1] = $4;
        $$->pieces[2] = $6;
        $$->pieces[3] = nullptr;
        $$->pieces[4] = nullptr;
    }
    | KW_POSTPONED KW_PROCESS '(' process_sensitivity_list ')' __maybe_is
      process_declarative_part KW_BEGIN
      sequence_of_statements KW_END KW_POSTPONED KW_PROCESS {
        $$ = new VhdlParseTreeNode(PT_PROCESS);
        $$->boolean = true;
        $$->pieces[0] = nullptr;
        $$->pieces[1] = $7;
        $$->pieces[2] = $9;
        $$->pieces[3] = nullptr;
        $$->pieces[4] = $4;
    }

__maybe_is:
    %empty
    | KW_IS

process_sensitivity_list:
    KW_ALL  { $$ = new VhdlParseTreeNode(PT_TOK_ALL); }
    | _list_of_names

process_declarative_part:
    %empty
    | _real_process_declarative_part

_real_process_declarative_part:
    process_declarative_item
    | _real_process_declarative_part process_declarative_item {
        $$ = new VhdlParseTreeNode(PT_DECLARATION_LIST);
        $$->pieces[0] = $1;
        $$->pieces[1] = $2;
    }

process_declarative_item:
    subprogram_declaration
    | subprogram_body
    | subprogram_instantiation_declaration
    | package_declaration
    | package_body
    | package_instantiation_declaration
    | type_declaration
    | subtype_declaration
    | constant_declaration
    | variable_declaration
    | file_declaration
    | alias_declaration
    | attribute_declaration
    | attribute_specification
    | use_clause
    | group_template_declaration
    | group_declaration

/// Section 11.4
concurrent_procedure_call_statement:
    _real_concurrent_procedure_call_statement ';'
    | identifier ':' _real_concurrent_procedure_call_statement ';' {
        $$ = $3;
        $$->pieces[1] = $1;
    }

_real_concurrent_procedure_call_statement:
    procedure_call {
        $$ = new VhdlParseTreeNode(PT_CONCURRENT_PROCEDURE_CALL);
        $$->boolean = false;
        $$->pieces[0] = $1;
        $$->pieces[1] = nullptr;
    }
    | KW_POSTPONED procedure_call {
        $$ = new VhdlParseTreeNode(PT_CONCURRENT_PROCEDURE_CALL);
        $$->boolean = true;
        $$->pieces[0] = $2;
        $$->pieces[1] = nullptr;
    }

/// Section 11.5
concurrent_assertion_statement:
    _real_concurrent_assertion_statement ';'
    | identifier ':' _real_concurrent_assertion_statement ';' {
        $$ = $3;
        $$->pieces[1] = $1;
    }

_real_concurrent_assertion_statement:
    assertion {
        $$ = new VhdlParseTreeNode(PT_CONCURRENT_ASSERTION_STATEMENT);
        $$->boolean = false;
        $$->pieces[0] = $1;
        $$->pieces[1] = nullptr;
    }
    | KW_POSTPONED assertion {
        $$ = new VhdlParseTreeNode(PT_CONCURRENT_ASSERTION_STATEMENT);
        $$->boolean = true;
        $$->pieces[0] = $2;
        $$->pieces[1] = nullptr;
    }

/// Section 11.6
concurrent_signal_assignment_statement:
    _real_concurrent_signal_assignment_statement ';'
    | identifier ':' _real_concurrent_signal_assignment_statement ';' {
        $$ = $3;
        $$->pieces[3] = $1;
    }
    | KW_POSTPONED _real_concurrent_signal_assignment_statement ';' {
        $$ = $2;
        $$->boolean = true;
    }
    | identifier ':' KW_POSTPONED
      _real_concurrent_signal_assignment_statement ';' {
        $$ = $4;
        $$->boolean = true;
        $$->pieces[3] = $1;
    }

_real_concurrent_signal_assignment_statement:
    concurrent_simple_signal_assignment
    | concurrent_conditional_signal_assignment
    | concurrent_selected_signal_assignment

concurrent_simple_signal_assignment:
    target DL_LEQ waveform {
        $$ = new VhdlParseTreeNode(PT_CONCURRENT_SIMPLE_SIGNAL_ASSIGNMENT);
        $$->boolean = false;
        $$->boolean2 = false;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
        $$->pieces[2] = nullptr;
        $$->pieces[3] = nullptr;
    }
    | target DL_LEQ delay_mechanism waveform {
        $$ = new VhdlParseTreeNode(PT_CONCURRENT_SIMPLE_SIGNAL_ASSIGNMENT);
        $$->boolean = false;
        $$->boolean2 = false;
        $$->pieces[0] = $1;
        $$->pieces[1] = $4;
        $$->pieces[2] = $3;
        $$->pieces[3] = nullptr;
    }
    | target DL_LEQ KW_GUARDED waveform {
        $$ = new VhdlParseTreeNode(PT_CONCURRENT_SIMPLE_SIGNAL_ASSIGNMENT);
        $$->boolean = false;
        $$->boolean2 = true;
        $$->pieces[0] = $1;
        $$->pieces[1] = $4;
        $$->pieces[2] = nullptr;
        $$->pieces[3] = nullptr;
    }
    | target DL_LEQ KW_GUARDED delay_mechanism waveform {
        $$ = new VhdlParseTreeNode(PT_CONCURRENT_SIMPLE_SIGNAL_ASSIGNMENT);
        $$->boolean = false;
        $$->boolean2 = true;
        $$->pieces[0] = $1;
        $$->pieces[1] = $5;
        $$->pieces[2] = $4;
        $$->pieces[3] = nullptr;
    }

concurrent_conditional_signal_assignment:
    target DL_LEQ conditional_waveforms {
        $$ = new VhdlParseTreeNode(
            PT_CONCURRENT_CONDITIONAL_SIGNAL_ASSIGNMENT);
        $$->boolean = false;
        $$->boolean2 = false;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
        $$->pieces[2] = nullptr;
        $$->pieces[3] = nullptr;
    }
    | target DL_LEQ delay_mechanism conditional_waveforms {
        $$ = new VhdlParseTreeNode(
            PT_CONCURRENT_CONDITIONAL_SIGNAL_ASSIGNMENT);
        $$->boolean = false;
        $$->boolean2 = false;
        $$->pieces[0] = $1;
        $$->pieces[1] = $4;
        $$->pieces[2] = $3;
        $$->pieces[3] = nullptr;
    }
    | target DL_LEQ KW_GUARDED conditional_waveforms {
        $$ = new VhdlParseTreeNode(
            PT_CONCURRENT_CONDITIONAL_SIGNAL_ASSIGNMENT);
        $$->boolean = false;
        $$->boolean2 = true;
        $$->pieces[0] = $1;
        $$->pieces[1] = $4;
        $$->pieces[2] = nullptr;
        $$->pieces[3] = nullptr;
    }
    | target DL_LEQ KW_GUARDED delay_mechanism conditional_waveforms {
        $$ = new VhdlParseTreeNode(
            PT_CONCURRENT_CONDITIONAL_SIGNAL_ASSIGNMENT);
        $$->boolean = false;
        $$->boolean2 = true;
        $$->pieces[0] = $1;
        $$->pieces[1] = $5;
        $$->pieces[2] = $4;
        $$->pieces[3] = nullptr;
    }

concurrent_selected_signal_assignment:
    KW_WITH expression KW_SELECT target DL_LEQ selected_waveforms {
        $$ = new VhdlParseTreeNode(PT_CONCURRENT_SELECTED_SIGNAL_ASSIGNMENT);
        $$->boolean = false;
        $$->boolean2 = false;
        $$->boolean3 = false;
        $$->pieces[0] = $4;
        $$->pieces[1] = $6;
        $$->pieces[2] = nullptr;
        $$->pieces[3] = nullptr;
        $$->pieces[4] = $2;
    }
    | KW_WITH expression KW_SELECT target delay_mechanism
      DL_LEQ selected_waveforms {
        $$ = new VhdlParseTreeNode(PT_CONCURRENT_SELECTED_SIGNAL_ASSIGNMENT);
        $$->boolean = false;
        $$->boolean2 = false;
        $$->boolean3 = false;
        $$->pieces[0] = $4;
        $$->pieces[1] = $7;
        $$->pieces[2] = $5;
        $$->pieces[3] = nullptr;
        $$->pieces[4] = $2;
    }
    | KW_WITH expression KW_SELECT target KW_GUARDED
      DL_LEQ selected_waveforms {
        $$ = new VhdlParseTreeNode(PT_CONCURRENT_SELECTED_SIGNAL_ASSIGNMENT);
        $$->boolean = false;
        $$->boolean2 = true;
        $$->boolean3 = false;
        $$->pieces[0] = $4;
        $$->pieces[1] = $7;
        $$->pieces[2] = nullptr;
        $$->pieces[3] = nullptr;
        $$->pieces[4] = $2;
    }
    | KW_WITH expression KW_SELECT target KW_GUARDED delay_mechanism
      DL_LEQ selected_waveforms {
        $$ = new VhdlParseTreeNode(PT_CONCURRENT_SELECTED_SIGNAL_ASSIGNMENT);
        $$->boolean = false;
        $$->boolean2 = true;
        $$->boolean3 = false;
        $$->pieces[0] = $4;
        $$->pieces[1] = $8;
        $$->pieces[2] = $6;
        $$->pieces[3] = nullptr;
        $$->pieces[4] = $2;
    }
    | KW_WITH expression KW_SELECT '?' target DL_LEQ selected_waveforms {
        $$ = new VhdlParseTreeNode(PT_CONCURRENT_SELECTED_SIGNAL_ASSIGNMENT);
        $$->boolean = false;
        $$->boolean2 = false;
        $$->boolean3 = true;
        $$->pieces[0] = $5;
        $$->pieces[1] = $7;
        $$->pieces[2] = nullptr;
        $$->pieces[3] = nullptr;
        $$->pieces[4] = $2;
    }
    | KW_WITH expression KW_SELECT '?' target delay_mechanism
      DL_LEQ selected_waveforms {
        $$ = new VhdlParseTreeNode(PT_CONCURRENT_SELECTED_SIGNAL_ASSIGNMENT);
        $$->boolean = false;
        $$->boolean2 = false;
        $$->boolean3 = true;
        $$->pieces[0] = $5;
        $$->pieces[1] = $8;
        $$->pieces[2] = $6;
        $$->pieces[3] = nullptr;
        $$->pieces[4] = $2;
    }
    | KW_WITH expression KW_SELECT '?' target KW_GUARDED
      DL_LEQ selected_waveforms {
        $$ = new VhdlParseTreeNode(PT_CONCURRENT_SELECTED_SIGNAL_ASSIGNMENT);
        $$->boolean = false;
        $$->boolean2 = true;
        $$->boolean3 = true;
        $$->pieces[0] = $5;
        $$->pieces[1] = $8;
        $$->pieces[2] = nullptr;
        $$->pieces[3] = nullptr;
        $$->pieces[4] = $2;
    }
    | KW_WITH expression KW_SELECT '?' target KW_GUARDED delay_mechanism
      DL_LEQ selected_waveforms {
        $$ = new VhdlParseTreeNode(PT_CONCURRENT_SELECTED_SIGNAL_ASSIGNMENT);
        $$->boolean = false;
        $$->boolean2 = true;
        $$->boolean3 = true;
        $$->pieces[0] = $5;
        $$->pieces[1] = $9;
        $$->pieces[2] = $7;
        $$->pieces[3] = nullptr;
        $$->pieces[4] = $2;
    }

/// Section 11.7
// There is an ambiguity here when you have a bare name, so we are skipping
// that. That will unfortunately parse into a procedure call.
component_instantiation_statement:
    identifier ':' _definitely_instantiated_unit ';' {
        $$ = new VhdlParseTreeNode(PT_COMPONENT_INSTANTIATION);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
        $$->pieces[2] = nullptr;
        $$->pieces[3] = nullptr;
    }
    | identifier ':' instantiated_unit generic_map_aspect ';' {
        $$ = new VhdlParseTreeNode(PT_COMPONENT_INSTANTIATION);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
        $$->pieces[2] = $4;
        $$->pieces[3] = nullptr;
    }
    | identifier ':' instantiated_unit port_map_aspect ';' {
        $$ = new VhdlParseTreeNode(PT_COMPONENT_INSTANTIATION);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
        $$->pieces[2] = nullptr;
        $$->pieces[3] = $4;
    }
    | identifier ':' instantiated_unit generic_map_aspect port_map_aspect ';' {
        $$ = new VhdlParseTreeNode(PT_COMPONENT_INSTANTIATION);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
        $$->pieces[2] = $4;
        $$->pieces[3] = $5;
    }

instantiated_unit:
    _definitely_instantiated_unit
    | _simple_or_selected_name {
        $$ = new VhdlParseTreeNode(PT_INSTANTIATED_UNIT_COMPONENT);
        $$->pieces[0] = $1;
    }

_definitely_instantiated_unit:
    _component_instantiated_unit
    | _entity_instantiated_unit
    | _configuration_instantiated_unit

_component_instantiated_unit:
    KW_COMPONENT _simple_or_selected_name {
        $$ = new VhdlParseTreeNode(PT_INSTANTIATED_UNIT_COMPONENT);
        $$->pieces[0] = $2;
    }

_entity_instantiated_unit:
    KW_ENTITY _simple_or_selected_name {
        $$ = new VhdlParseTreeNode(PT_INSTANTIATED_UNIT_ENTITY);
        $$->pieces[0] = $2;
    }
    | KW_ENTITY _simple_or_selected_name '(' identifier ')' {
        $$ = new VhdlParseTreeNode(PT_INSTANTIATED_UNIT_ENTITY);
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
    }

_configuration_instantiated_unit:
    KW_CONFIGURATION _simple_or_selected_name {
        $$ = new VhdlParseTreeNode(PT_INSTANTIATED_UNIT_CONFIGURATION);
        $$->pieces[0] = $2;
    }

/// Section 11.8
generate_statement:
    for_generate_statement
    | if_generate_statement
    | case_generate_statement

for_generate_statement:
    _real_for_generate_statement ';'
    | _real_for_generate_statement identifier ';' {
        $$ = $1;
        $$->pieces[3] = $2;
    }

_real_for_generate_statement:
    identifier ':' KW_FOR parameter_specification KW_GENERATE
    generate_statement_body KW_END KW_GENERATE {
        $$ = new VhdlParseTreeNode(PT_FOR_GENERATE);
        $$->pieces[0] = $1;
        $$->pieces[1] = $4;
        $$->pieces[2] = $6;
        $$->pieces[3] = nullptr;
    }

if_generate_statement:
    _real_if_generate_statement ';'
    | _real_if_generate_statement identifier ';' {
        $$ = $1;
        $$->pieces[7] = $2;
    }

_real_if_generate_statement:
    identifier ':' KW_IF expression KW_GENERATE generate_statement_body
    _if_generate_elsifs _if_generate_else KW_END KW_GENERATE {
        $$ = new VhdlParseTreeNode(PT_IF_GENERATE);
        $$->pieces[0] = $1;
        $$->pieces[1] = $4;
        $$->pieces[2] = $6;
        $$->pieces[3] = nullptr;
        $$->pieces[4] = $7;
        // FIXME: Ugly wtf
        if ($8) {
            $$->pieces[5] = $8->pieces[1];
            $$->pieces[6] = $8->pieces[2];
            $8->pieces[1] = nullptr;
            $8->pieces[2] = nullptr;
            delete $8;
        }
        $$->pieces[7] = nullptr;
    }
    | identifier ':' KW_IF identifier ':' expression
      KW_GENERATE generate_statement_body
      _if_generate_elsifs _if_generate_else KW_END KW_GENERATE {
        $$ = new VhdlParseTreeNode(PT_IF_GENERATE);
        $$->pieces[0] = $1;
        $$->pieces[1] = $6;
        $$->pieces[2] = $8;
        $$->pieces[3] = $4;
        $$->pieces[4] = $9;
        // FIXME: Ugly wtf
        if ($10) {
            $$->pieces[5] = $10->pieces[1];
            $$->pieces[6] = $10->pieces[2];
            $10->pieces[1] = nullptr;
            $10->pieces[2] = nullptr;
            delete $10;
        }
        $$->pieces[7] = nullptr;
    }

_if_generate_elsifs:
    %empty
    | _real_if_generate_elsifs

_real_if_generate_elsifs:
    _if_generate_elsif
    | _real_if_generate_elsifs _if_generate_elsif {
        $$ = new VhdlParseTreeNode(PT_IF_GENERATE_ELSIF_LIST);
        $$->pieces[0] = $1;
        $$->pieces[1] = $2;
    }

_if_generate_elsif:
    KW_ELSIF expression KW_GENERATE generate_statement_body {
        $$ = new VhdlParseTreeNode(PT_IF_GENERATE_ELSIF);
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
        $$->pieces[2] = nullptr;
    }
    | KW_ELSIF identifier ':' expression KW_GENERATE generate_statement_body {
        $$ = new VhdlParseTreeNode(PT_IF_GENERATE_ELSIF);
        $$->pieces[0] = $4;
        $$->pieces[1] = $6;
        $$->pieces[2] = $2;
    }

_if_generate_else:
    %empty
    | KW_ELSE KW_GENERATE generate_statement_body {
        // FIXME: Hack
        $$ = new VhdlParseTreeNode(PT_IF_GENERATE_ELSIF);
        $$->pieces[0] = nullptr;
        $$->pieces[1] = $3;
        $$->pieces[2] = nullptr;
    }
    | KW_ELSE identifier ':' KW_GENERATE generate_statement_body {
        // FIXME: Hack
        $$ = new VhdlParseTreeNode(PT_IF_GENERATE_ELSIF);
        $$->pieces[0] = nullptr;
        $$->pieces[1] = $5;
        $$->pieces[2] = $2;
    }

case_generate_statement:
    _real_case_generate_statement ';'
    | _real_case_generate_statement identifier ';' {
        $$ = $1;
        $$->pieces[3] = $2;
    }

_real_case_generate_statement:
    identifier ':' KW_CASE expression KW_GENERATE
    _one_or_more_case_generate_alternatives KW_END KW_GENERATE {
        $$ = new VhdlParseTreeNode(PT_CASE_GENERATE);
        $$->pieces[0] = $1;
        $$->pieces[1] = $4;
        $$->pieces[2] = $6;
        $$->pieces[3] = nullptr;
    }

_one_or_more_case_generate_alternatives:
    case_generate_alternative
    | _one_or_more_case_generate_alternatives case_generate_alternative {
        $$ = new VhdlParseTreeNode(PT_CASE_GENERATE_ALTERNATIVE_LIST);
        $$->pieces[0] = $1;
        $$->pieces[1] = $2;
    }

case_generate_alternative:
    KW_WHEN choices DL_ARR generate_statement_body {
        $$ = new VhdlParseTreeNode(PT_CASE_GENERATE_ALTERNATIVE);
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
        $$->pieces[2] = nullptr;
    }
    | KW_WHEN identifier ':' choices DL_ARR generate_statement_body {
        $$ = new VhdlParseTreeNode(PT_CASE_GENERATE_ALTERNATIVE);
        $$->pieces[0] = $4;
        $$->pieces[1] = $6;
        $$->pieces[2] = $2;
    }

// FIXME: Presumably begin/end need to match?
generate_statement_body:
    _sequence_of_concurrent_statements {
        $$ = new VhdlParseTreeNode(PT_GENERATE_BODY);
        $$->pieces[0] = nullptr;
        $$->pieces[1] = $1;
        $$->pieces[2] = nullptr;
    }
    | block_declarative_part KW_BEGIN
      _sequence_of_concurrent_statements _generate_statement_body_end {
        $$ = new VhdlParseTreeNode(PT_GENERATE_BODY);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
        $$->pieces[2] = $4;
    }

_generate_statement_body_end:
    KW_END ';'              { $$ = nullptr; }
    | KW_END identifier ';' { $$ = $2; }

////////////////////// Scope and visibility, section 12 //////////////////////

use_clause:
    KW_USE _one_or_more_selected_names ';' {
        $$ = new VhdlParseTreeNode(PT_USE_CLAUSE);
        $$->pieces[0] = $2;
    }

_one_or_more_selected_names:
    selected_name
    | _one_or_more_selected_names ',' selected_name {
        $$ = new VhdlParseTreeNode(PT_SELECTED_NAME_LIST);
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

///////////////// Design units and their analysis, section 13 /////////////////

/// Section 13.1
design_file:
    design_unit
    | design_file design_unit {
        $$ = new VhdlParseTreeNode(PT_DESIGN_FILE);
        $$->pieces[0] = $1;
        $$->pieces[1] = $2;
    }

design_unit:
    context_clause library_unit {
        $$ = new VhdlParseTreeNode(PT_DESIGN_UNIT);
        $$->pieces[0] = $2;
        $$->pieces[1] = $1;
    }

// Store line number information
library_unit: _library_unit { STORE_LOC($$, @$); }

_library_unit:
    primary_unit
    | secondary_unit

primary_unit:
    entity_declaration
    | configuration_declaration
    | package_declaration
    | package_instantiation_declaration
    | context_declaration

secondary_unit:
    architecture_body
    | package_body

/// Section 13.2
library_clause:
    KW_LIBRARY identifier_list ';' {
        $$ = new VhdlParseTreeNode(PT_LIBRARY_CLAUSE);
        $$->pieces[0] = $2;
    }

/// Section 13.3
context_declaration:
    _real_context_declaration ';'
    | _real_context_declaration KW_CONTEXT ';'
    | _real_context_declaration identifier ';' {
        $$ = $1;
        $$->pieces[2] = $2;
    }
    | _real_context_declaration KW_CONTEXT identifier ';' {
        $$ = $1;
        $$->pieces[2] = $3;
    }

_real_context_declaration:
    KW_CONTEXT identifier KW_IS context_clause KW_END {
        $$ = new VhdlParseTreeNode(PT_CONTEXT_DECLARATION);
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
        $$->pieces[2] = nullptr;
    }

/// Section 13.4
context_clause:
    %empty
    | _real_context_clause

_real_context_clause:
    context_item
    | _real_context_clause context_item {
        $$ = new VhdlParseTreeNode(PT_CONTEXT_CLAUSE);
        $$->pieces[0] = $1;
        $$->pieces[1] = $2;
    }

context_item:
    library_clause
    | use_clause
    | context_reference

context_reference:
    KW_CONTEXT _one_or_more_selected_names ';' {
        $$ = new VhdlParseTreeNode(PT_CONTEXT_REFERENCE);
        $$->pieces[0] = $2;
    }

//////////////////////// Lexical elements, section 15 ////////////////////////

/// Section 15.4
identifier:
    basic_identifier
    | extended_identifier

basic_identifier: TOK_BASIC_ID
extended_identifier: TOK_EXT_ID

/// Section 15.5
abstract_literal:
    decimal_literal
    | based_literal

decimal_literal: TOK_DECIMAL
based_literal: TOK_BASED

/// Section 15.6
character_literal: TOK_CHAR

/// Section 15.7
string_literal: TOK_STRING

/// Section 15.8
bit_string_literal: TOK_BITSTRING

%%
