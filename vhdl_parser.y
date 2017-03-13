%{

#include <cstdio>
#include <iostream>
#include <string>
using namespace std;

#include "vhdl_parse_tree.h"

int frontend_vhdl_yylex(void);
void frontend_vhdl_yyerror(const char *msg);
int frontend_vhdl_yyget_lineno(void);
int frontend_vhdl_yylex_destroy(void);
extern FILE *frontend_vhdl_yyin;

struct VhdlParseTreeNode *parse_output;

%}

%name-prefix "frontend_vhdl_yy"

%glr-parser

// %define lr.type ielr
%define parse.error verbose
// %define parse.lac full
%debug

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

%define api.value.type {struct VhdlParseTreeNode *}

%%

// Start token used for saving the parse tree
_toplevel_token:
    not_actualy_design_file { parse_output = $1; }

// Fake start token for testing
not_actualy_design_file:
    process_statement

///////////////////// Subprograms and packages, section 4 /////////////////////

/// Section 4.5.3
signature:
    '[' ']' {
        $$ = new VhdlParseTreeNode(PT_SIGNATURE);
        $$->piece_count = 2;
        $$->pieces[0] = nullptr;
        $$->pieces[1] = nullptr;
    }
    | '[' _one_or_more_ids ']' {
        $$ = new VhdlParseTreeNode(PT_SIGNATURE);
        $$->piece_count = 2;
        $$->pieces[0] = $2;
        $$->pieces[1] = nullptr;
    }
    | '[' KW_RETURN _simple_or_selected_name ']' {
        $$ = new VhdlParseTreeNode(PT_SIGNATURE);
        $$->piece_count = 2;
        $$->pieces[0] = nullptr;
        $$->pieces[1] = $3;
    }
    | '[' _one_or_more_ids KW_RETURN _simple_or_selected_name ']' {
        $$ = new VhdlParseTreeNode(PT_SIGNATURE);
        $$->piece_count = 2;
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
    }

_one_or_more_ids:
    _simple_or_selected_name
    | _one_or_more_ids ',' _simple_or_selected_name {
        $$ = new VhdlParseTreeNode(PT_ID_LIST);
        $$->piece_count = 2;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
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
        $$->piece_count = 1;
        $$->pieces[0] = $2;
    }

_one_or_more_enumeration_literals:
    enumeration_literal
    | _one_or_more_enumeration_literals ',' enumeration_literal {
        $$ = new VhdlParseTreeNode(PT_ENUM_LITERAL_LIST);
        $$->piece_count = 2;
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
        $$->piece_count = 1;
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
        $$->piece_count = 4;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
        $$->pieces[2] = nullptr;
        $$->pieces[3] = nullptr;
    }
    | range_constraint KW_UNITS identifier ';'
      _one_or_more_secondary_unit_declarations KW_END KW_UNITS {
        $$ = new VhdlParseTreeNode(PT_PHYSICAL_TYPE_DEFINITION);
        $$->piece_count = 4;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
        $$->pieces[2] = $5;
        $$->pieces[3] = nullptr;
    }

_one_or_more_secondary_unit_declarations:
    secondary_unit_declaration
    | _one_or_more_secondary_unit_declarations secondary_unit_declaration {
        $$ = new VhdlParseTreeNode(PT_SECONDARY_UNIT_DECLARATION_LIST);
        $$->piece_count = 2;
        $$->pieces[0] = $1;
        $$->pieces[1] = $2;
    }

secondary_unit_declaration:
    identifier '=' physical_literal ';' {
        $$ = new VhdlParseTreeNode(PT_SECONDARY_UNIT_DECLARATION);
        $$->piece_count = 2;
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
        $$->piece_count = 2;
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
        $$->piece_count = 2;
        $$->pieces[0] = $3;
        $$->pieces[1] = $6;
    }

constrained_array_definition:
    KW_ARRAY index_constraint KW_OF subtype_indication {
        $$ = new VhdlParseTreeNode(PT_CONSTRAINED_ARRAY_DEFINITION);
        $$->piece_count = 2;
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
    }

_one_or_more_index_subtype_definition:
    index_subtype_definition
    | _one_or_more_index_subtype_definition ',' index_subtype_definition {
        $$ = new VhdlParseTreeNode(PT_INDEX_SUBTYPE_DEFINITION_LIST);
        $$->piece_count = 2;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

index_subtype_definition:
    _simple_or_selected_name KW_RANGE DL_BOX {
        $$ = $1;
    }

array_constraint:
    '(' KW_OPEN ')' {
        $$ = new VhdlParseTreeNode(PT_ARRAY_CONSTRAINT);
        $$->piece_count = 2;
        $$->pieces[0] = nullptr;
        $$->pieces[1] = nullptr;
    }
    | '(' KW_OPEN ')' element_constraint {
        $$ = new VhdlParseTreeNode(PT_ARRAY_CONSTRAINT);
        $$->piece_count = 2;
        $$->pieces[0] = nullptr;
        $$->pieces[1] = $4;
    }
    | index_constraint {
        $$ = new VhdlParseTreeNode(PT_ARRAY_CONSTRAINT);
        $$->piece_count = 2;
        $$->pieces[0] = $1;
        $$->pieces[1] = nullptr;
    }
    | index_constraint element_constraint {
        $$ = new VhdlParseTreeNode(PT_ARRAY_CONSTRAINT);
        $$->piece_count = 2;
        $$->pieces[0] = $1;
        $$->pieces[1] = $2;
    }

index_constraint:
    '(' _one_or_more_discrete_range ')' {
        $$ = $2;
    }

_one_or_more_discrete_range:
    discrete_range
    | _one_or_more_discrete_range ',' discrete_range {
        $$ = new VhdlParseTreeNode(PT_INDEX_CONSTRAINT);
        $$->piece_count = 2;
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
        $$->piece_count = 2;
        $$->pieces[0] = $2;
        $$->pieces[1] = nullptr;
    }

_one_or_more_element_declarations:
    element_declaration
    | _one_or_more_element_declarations element_declaration {
        $$ = new VhdlParseTreeNode(PT_ELEMENT_DECLARATION_LIST);
        $$->piece_count = 2;
        $$->pieces[0] = $1;
        $$->pieces[1] = $2;
    }

element_declaration:
    identifier_list ':' subtype_indication ';' {
        $$ = new VhdlParseTreeNode(PT_ELEMENT_DECLARATION);
        $$->piece_count = 2;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

identifier_list:
    identifier
    | identifier_list ',' identifier {
        $$ = new VhdlParseTreeNode(PT_ID_LIST_REAL);
        $$->piece_count = 2;
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
        $$->piece_count = 2;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

record_element_constraint:
    identifier element_constraint {
        $$ = new VhdlParseTreeNode(PT_RECORD_ELEMENT_CONSTRAINT);
        $$->piece_count = 2;
        $$->pieces[0] = $1;
        $$->pieces[1] = $2;
    }

/// Section 5.4
access_type_definition:
    KW_ACCESS subtype_indication {
        $$ = new VhdlParseTreeNode(PT_ACCESS_TYPE_DEFINITION);
        $$->piece_count = 1;
        $$->pieces[0] = $2;
    }

incomplete_type_declaration:
    KW_TYPE identifier ';' {
        $$ = new VhdlParseTreeNode(PT_INCOMPLETE_TYPE_DECLARATION);
        $$->piece_count = 1;
        $$->pieces[0] = $2;
    }

/// Section 5.5
file_type_definition:
    KW_FILE KW_OF _simple_or_selected_name {
        $$ = new VhdlParseTreeNode(PT_FILE_TYPE_DEFINITION);
        $$->piece_count = 1;
        $$->pieces[0] = $3;

    }

/////////////////////////// Declarations, section 6 ///////////////////////////

/// Section 6.2
type_declaration:
    full_type_declaration
    | incomplete_type_declaration

full_type_declaration:
    KW_TYPE identifier KW_IS type_definition ';' {
        $$ = new VhdlParseTreeNode(PT_FULL_TYPE_DECLARATION);
        $$->piece_count = 2;
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
    }

type_definition:
    scalar_type_definition
    | composite_type_definition
    | access_type_definition
    | file_type_definition
    // TODO

/// Section 6.3
subtype_indication:
    _simple_or_selected_name
    | resolution_indication _simple_or_selected_name {
        $$ = new VhdlParseTreeNode(PT_SUBTYPE_INDICATION);
        $$->piece_count = 3;
        $$->pieces[0] = $2;
        $$->pieces[1] = $1;
        $$->pieces[2] = nullptr;
    }
    | _simple_or_selected_name constraint {
        $$ = new VhdlParseTreeNode(PT_SUBTYPE_INDICATION);
        $$->piece_count = 3;
        $$->pieces[0] = $1;
        $$->pieces[1] = nullptr;
        $$->pieces[2] = $2;
    }
    | resolution_indication _simple_or_selected_name constraint {
        $$ = new VhdlParseTreeNode(PT_SUBTYPE_INDICATION);
        $$->piece_count = 3;
        $$->pieces[0] = $2;
        $$->pieces[1] = $1;
        $$->pieces[2] = $3;
    }

// Does not handle the case of only a type_mark because that can cause
// ambiguities. Does not allow a resolution indication because that isn't
// actually permitted (see 5.3.2.1).
_almost_discrete_subtype_indication:
    _simple_or_selected_name _discrete_constraint {
        $$ = new VhdlParseTreeNode(PT_SUBTYPE_INDICATION);
        $$->piece_count = 3;
        $$->pieces[0] = $1;
        $$->pieces[1] = nullptr;
        $$->pieces[2] = $2;
    }

// Reallow identifiers (a plain type_mark)
discrete_subtype_indication:
    _simple_or_selected_name
    | _almost_discrete_subtype_indication

_allocator_subtype_indication:
    // Resolution indications not allowed
    _simple_or_selected_name
    | _simple_or_selected_name _allocator_constraint {
        $$ = new VhdlParseTreeNode(PT_SUBTYPE_INDICATION);
        $$->piece_count = 3;
        $$->pieces[0] = $1;
        $$->pieces[1] = nullptr;
        $$->pieces[2] = $2;
    }

resolution_indication:
    // The following two are for function names
    function_name
    | '(' element_resolution ')' {
        // FIXME: Do I need to store more information here?
        $$ = $2;
    }

element_resolution:
    resolution_indication   // was array_element_resolution
    | record_resolution

record_resolution:
    record_element_resolution
    | record_resolution ',' record_element_resolution {
        $$ = new VhdlParseTreeNode(PT_RECORD_RESOLUTION);
        $$->piece_count = 2;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

record_element_resolution:
    identifier resolution_indication {
        $$ = new VhdlParseTreeNode(PT_RECORD_ELEMENT_RESOLUTION);
        $$->piece_count = 2;
        $$->pieces[0] = $1;
        $$->pieces[1] = $2;
    }

// FIXME: explain why there is a S/R conflict here
constraint:
    range_constraint
    | array_constraint
    | record_constraint

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
        $$->piece_count = 2;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }
    // HACK
    | _one_or_more_expressions ',' KW_OPEN {
        $$ = new VhdlParseTreeNode(PT_PARAMETER_ASSOCIATION_LIST);
        $$->piece_count = 2;
        $$->pieces[0] = $1;
        $$->pieces[1] = new VhdlParseTreeNode(PT_TOK_OPEN);
    }
    | _definitely_parameter_association_list ','
      _definitely_parameter_association_element {
        $$ = new VhdlParseTreeNode(PT_PARAMETER_ASSOCIATION_LIST);
        $$->piece_count = 2;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }
    // HACK
    | _definitely_parameter_association_list ',' _function_actual_part {
        $$ = new VhdlParseTreeNode(PT_PARAMETER_ASSOCIATION_LIST);
        $$->piece_count = 2;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

// Must have => in it
_definitely_parameter_association_element:
    formal_part DL_ARR _function_actual_part {
        $$ = new VhdlParseTreeNode(PT_PARAMETER_ASSOCIATION_ELEMENT);
        $$->piece_count = 2;
        $$->pieces[0] = $3;
        $$->pieces[1] = $1;
    }

formal_part:
    identifier
    | function_name '(' identifier ')' {
        $$ = new VhdlParseTreeNode(PT_FORMAL_PART_FN);
        $$->piece_count = 2;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

// By accepting expression we already accept all the possible types of names.
// We cannot accept a type (subtype_indication). We can additionally accept
// "open" however. "inertial" is not allowed for functions.
_function_actual_part:
    expression
    | KW_OPEN {
        $$ = new VhdlParseTreeNode(PT_TOK_OPEN);
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
    // This handles anything that involves parentheses, including some things
    // that are actually a "primary." It needs to be disambiguated later in
    // second-stage parsing. However, it notably includes indexed and slice
    // names.
    | name '(' _ambig_name_parens ')' {
        $$ = new VhdlParseTreeNode(PT_NAME_AMBIG_PARENS);
        $$->piece_count = 2;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }
    | slice_name
    | _almost_attribute_name
    | external_name

// A number of things require a list of names
_list_of_names:
    name
    | _list_of_names ',' name {
        $$ = new VhdlParseTreeNode(PT_NAME_LIST);
        $$->piece_count = 2;
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
    name '.' suffix {
        $$ = new VhdlParseTreeNode(PT_NAME_SELECTED);
        $$->piece_count = 2;
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
    name '(' _almost_discrete_range ')' {
        $$ = new VhdlParseTreeNode(PT_NAME_SLICE);
        $$->piece_count = 2;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

/// Section 8.6
// Note that we do not handle the possible occurrence of (expression) at the
// end because it is ambiguous with function calls. _ambig_name_parens should
// pick that up.
_almost_attribute_name:
    name '\'' __attribute_kw_identifier_hack {
        $$ = new VhdlParseTreeNode(PT_NAME_ATTRIBUTE);
        $$->piece_count = 2;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }
    | name signature '\'' __attribute_kw_identifier_hack {
        $$ = new VhdlParseTreeNode(PT_NAME_ATTRIBUTE);
        $$->piece_count = 3;
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
        $$->piece_count = 4;
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
        $$->piece_count = 2;
        $$->pieces[0] = $3;
        $$->pieces[1] = $5;
    }

external_signal_name:
    DL_LL KW_SIGNAL external_pathname ':' subtype_indication DL_RR {
        $$ = new VhdlParseTreeNode(PT_NAME_EXT_SIG);
        $$->piece_count = 2;
        $$->pieces[0] = $3;
        $$->pieces[1] = $5;
    }

external_variable_name:
    DL_LL KW_VARIABLE external_pathname ':' subtype_indication DL_RR {
        $$ = new VhdlParseTreeNode(PT_NAME_EXT_VAR);
        $$->piece_count = 2;
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
        $$->piece_count = 3;
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
        $$->pieces[2] = $6;
    }

_one_or_more_ids_dots:
    identifier
    | _one_or_more_ids_dots '.' identifier {
        $$ = new VhdlParseTreeNode(PT_ID_LIST);
        $$->piece_count = 2;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

absolute_pathname:
    '.' partial_pathname {
        $$ = new VhdlParseTreeNode(PT_ABSOLUTE_PATHNAME);
        $$->piece_count = 1;
        $$->pieces[0] = $2;
    }

relative_pathname:
    partial_pathname {
        $$ = new VhdlParseTreeNode(PT_RELATIVE_PATHNAME);
        $$->piece_count = 1;
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
        $$->piece_count = 1;
        $$->pieces[0] = $1;
    }
    | _one_or_more_pathname_elements '.' identifier {
        $$ = new VhdlParseTreeNode(PT_PARTIAL_PATHNAME);
        $$->piece_count = 2;
        $$->pieces[0] = $3;
        $$->pieces[1] = $1;
    }

_one_or_more_pathname_elements:
    pathname_element
    | _one_or_more_pathname_elements '.' pathname_element {
        $$ = new VhdlParseTreeNode(PT_PATHNAME_ELEMENT);
        $$->piece_count = 2;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

pathname_element:
    identifier
    | identifier '(' expression ')' {
        $$ = new VhdlParseTreeNode(PT_PATHNAME_ELEMENT_GENERATE_LABEL);
        $$->piece_count = 2;
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
        $$->piece_count = 2;
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
        $$->piece_count = 2;
        $$->pieces[0] = nullptr;
        $$->pieces[1] = $2;
    }

_two_or_more_element_association:
    element_association ',' element_association {
        $$ = new VhdlParseTreeNode(PT_AGGREGATE);
        $$->piece_count = 2;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }
    | _two_or_more_element_association ',' element_association {
        $$ = new VhdlParseTreeNode(PT_AGGREGATE);
        $$->piece_count = 2;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

element_association:
    expression {
        $$ = new VhdlParseTreeNode(PT_ELEMENT_ASSOCIATION);
        $$->piece_count = 1;
        $$->pieces[0] = $1;
    }
    | _must_have_choice_element_association

_must_have_choice_element_association:
    choices DL_ARR expression {
        $$ = new VhdlParseTreeNode(PT_ELEMENT_ASSOCIATION);
        $$->piece_count = 2;
        $$->pieces[0] = $3;
        $$->pieces[1] = $1;
    }

choices:
    choice
    | choices '|' choice {
        $$ = new VhdlParseTreeNode(PT_CHOICES);
        $$->piece_count = 2;
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
        $$->piece_count = 2;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

/// Section 9.3.5
qualified_expression:
    _simple_or_selected_name '\'' '(' expression ')' {
        $$ = new VhdlParseTreeNode(PT_QUALIFIED_EXPRESSION);
        $$->piece_count = 2;
        $$->pieces[0] = $1;
        $$->pieces[1] = $4;
    }
    | _simple_or_selected_name '\'' aggregate {
        $$ = new VhdlParseTreeNode(PT_QUALIFIED_EXPRESSION);
        $$->piece_count = 2;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

/// Section 9.3.7
allocator:
    KW_NEW _allocator_subtype_indication {
        $$ = new VhdlParseTreeNode(PT_ALLOCATOR);
        $$->piece_count = 1;
        $$->pieces[0] = $2;
    }
    | KW_NEW qualified_expression {
        $$ = new VhdlParseTreeNode(PT_ALLOCATOR);
        $$->piece_count = 1;
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
        $$->piece_count = 2;
        $$->pieces[0] = $1;
        $$->pieces[1] = $2;
    }

sequential_statement:
    _real_sequential_statement ';'
    | identifier ':' _real_sequential_statement ';' {
        $$ = new VhdlParseTreeNode(PT_STATEMENT_LABEL);
        $$->piece_count = 2;
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
        $$->piece_count = 3;
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
assertion_statement:
    KW_ASSERT expression {
        $$ = new VhdlParseTreeNode(PT_ASSERTION_STATEMENT);
        $$->piece_count = 3;
        $$->pieces[0] = $2;
        $$->pieces[1] = nullptr;
        $$->pieces[2] = nullptr;
    }
    | KW_ASSERT expression KW_REPORT expression {
        $$ = new VhdlParseTreeNode(PT_ASSERTION_STATEMENT);
        $$->piece_count = 3;
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
        $$->pieces[2] = nullptr;
    }
    | KW_ASSERT expression KW_SEVERITY expression {
        $$ = new VhdlParseTreeNode(PT_ASSERTION_STATEMENT);
        $$->piece_count = 3;
        $$->pieces[0] = $2;
        $$->pieces[1] = nullptr;
        $$->pieces[2] = $4;
    }
    | KW_ASSERT expression KW_REPORT expression KW_SEVERITY expression {
        $$ = new VhdlParseTreeNode(PT_ASSERTION_STATEMENT);
        $$->piece_count = 3;
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
        $$->pieces[2] = $6;
    }

/// Section 10.4
report_statement:
    KW_REPORT expression {
        $$ = new VhdlParseTreeNode(PT_REPORT_STATEMENT);
        $$->piece_count = 2;
        $$->pieces[0] = $2;
        $$->pieces[1] = nullptr;
    }
    | KW_REPORT expression KW_SEVERITY expression {
        $$ = new VhdlParseTreeNode(PT_REPORT_STATEMENT);
        $$->piece_count = 2;
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
        $$->piece_count = 3;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
        $$->pieces[2] = nullptr;
    }
    | target DL_LEQ delay_mechanism waveform {
        $$ = new VhdlParseTreeNode(PT_SIMPLE_WAVEFORM_ASSIGNMENT);
        $$->piece_count = 3;
        $$->pieces[0] = $1;
        $$->pieces[1] = $4;
        $$->pieces[2] = $3;
    }

simple_force_assignment:
    target DL_LEQ KW_FORCE expression {
        $$ = new VhdlParseTreeNode(PT_SIMPLE_FORCE_ASSIGNMENT);
        $$->force_mode = FORCE_UNSPEC;
        $$->piece_count = 2;
        $$->pieces[0] = $1;
        $$->pieces[1] = $4;
    }
    | target DL_LEQ KW_FORCE KW_IN expression {
        $$ = new VhdlParseTreeNode(PT_SIMPLE_FORCE_ASSIGNMENT);
        $$->force_mode = FORCE_IN;
        $$->piece_count = 2;
        $$->pieces[0] = $1;
        $$->pieces[1] = $5;
    }
    | target DL_LEQ KW_FORCE KW_OUT expression {
        $$ = new VhdlParseTreeNode(PT_SIMPLE_FORCE_ASSIGNMENT);
        $$->force_mode = FORCE_OUT;
        $$->piece_count = 2;
        $$->pieces[0] = $1;
        $$->pieces[1] = $5;
    }

simple_release_assignment:
    target DL_LEQ KW_RELEASE {
        $$ = new VhdlParseTreeNode(PT_SIMPLE_RELEASE_ASSIGNMENT);
        $$->force_mode = FORCE_UNSPEC;
        $$->piece_count = 1;
        $$->pieces[0] = $1;
    }
    | target DL_LEQ KW_RELEASE KW_IN {
        $$ = new VhdlParseTreeNode(PT_SIMPLE_RELEASE_ASSIGNMENT);
        $$->force_mode = FORCE_IN;
        $$->piece_count = 1;
        $$->pieces[0] = $1;
    }
    | target DL_LEQ KW_RELEASE KW_OUT {
        $$ = new VhdlParseTreeNode(PT_SIMPLE_RELEASE_ASSIGNMENT);
        $$->force_mode = FORCE_OUT;
        $$->piece_count = 1;
        $$->pieces[0] = $1;
    }

delay_mechanism:
    KW_TRANSPORT {
        $$ = new VhdlParseTreeNode(PT_DELAY_TRANSPORT);
    }
    | KW_INERTIAL {
        $$ = new VhdlParseTreeNode(PT_DELAY_INERTIAL);
        $$->piece_count = 1;
        $$->pieces[0] = nullptr;
    }
    | KW_REJECT expression KW_INERTIAL {
        $$ = new VhdlParseTreeNode(PT_DELAY_INERTIAL);
        $$->piece_count = 1;
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
        $$->piece_count = 2;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

waveform_element:
    expression {
        $$ = new VhdlParseTreeNode(PT_WAVEFORM_ELEMENT);
        $$->piece_count = 2;
        $$->pieces[0] = $1;
        $$->pieces[1] = nullptr;
    }
    | expression KW_AFTER expression {
        $$ = new VhdlParseTreeNode(PT_WAVEFORM_ELEMENT);
        $$->piece_count = 2;
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
        $$->piece_count = 3;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
        $$->pieces[2] = nullptr;
    }
    | target DL_LEQ delay_mechanism conditional_waveforms {
        $$ = new VhdlParseTreeNode(PT_CONDITIONAL_WAVEFORM_ASSIGNMENT);
        $$->piece_count = 3;
        $$->pieces[0] = $1;
        $$->pieces[1] = $4;
        $$->pieces[2] = $3;
    }

conditional_waveforms:
    waveform KW_WHEN expression {
        $$ = new VhdlParseTreeNode(PT_CONDITIONAL_WAVEFORMS);
        $$->piece_count = 4;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
        $$->pieces[2] = nullptr;
        $$->pieces[3] = nullptr;
    }
    | waveform KW_WHEN expression KW_ELSE waveform {
        $$ = new VhdlParseTreeNode(PT_CONDITIONAL_WAVEFORMS);
        $$->piece_count = 4;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
        $$->pieces[2] = nullptr;
        $$->pieces[3] = $5;
    }
    | waveform KW_WHEN expression _one_or_more_conditional_waveform_elses
      KW_ELSE waveform {
        $$ = new VhdlParseTreeNode(PT_CONDITIONAL_WAVEFORMS);
        $$->piece_count = 4;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
        $$->pieces[2] = $4;
        $$->pieces[3] = $6;
    }

_one_or_more_conditional_waveform_elses:
    _conditional_waveform_else
    | _one_or_more_conditional_waveform_elses _conditional_waveform_else {
        $$ = new VhdlParseTreeNode(PT_CONDITIONAL_WAVEFORM_ELSE_LIST);
        $$->piece_count = 2;
        $$->pieces[0] = $1;
        $$->pieces[1] = $2;
    }

_conditional_waveform_else:
    KW_ELSE waveform KW_WHEN expression {
        $$ = new VhdlParseTreeNode(PT_CONDITIONAL_WAVEFORM_ELSE);
        $$->piece_count = 2;
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
    }

conditional_force_assignment:
    target DL_LEQ KW_FORCE conditional_expressions {
        $$ = new VhdlParseTreeNode(PT_CONDITIONAL_FORCE_ASSIGNMENT);
        $$->force_mode = FORCE_UNSPEC;
        $$->piece_count = 2;
        $$->pieces[0] = $1;
        $$->pieces[1] = $4;
    }
    | target DL_LEQ KW_FORCE KW_IN conditional_expressions {
        $$ = new VhdlParseTreeNode(PT_CONDITIONAL_FORCE_ASSIGNMENT);
        $$->force_mode = FORCE_IN;
        $$->piece_count = 2;
        $$->pieces[0] = $1;
        $$->pieces[1] = $5;
    }
    | target DL_LEQ KW_FORCE KW_OUT conditional_expressions {
        $$ = new VhdlParseTreeNode(PT_CONDITIONAL_FORCE_ASSIGNMENT);
        $$->force_mode = FORCE_OUT;
        $$->piece_count = 2;
        $$->pieces[0] = $1;
        $$->pieces[1] = $5;
    }

conditional_expressions:
    expression KW_WHEN expression {
        $$ = new VhdlParseTreeNode(PT_CONDITIONAL_EXPRESSIONS);
        $$->piece_count = 4;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
        $$->pieces[2] = nullptr;
        $$->pieces[3] = nullptr;
    }
    | expression KW_WHEN expression KW_ELSE expression {
        $$ = new VhdlParseTreeNode(PT_CONDITIONAL_EXPRESSIONS);
        $$->piece_count = 4;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
        $$->pieces[2] = nullptr;
        $$->pieces[3] = $5;
    }
    | expression KW_WHEN expression _one_or_more_conditional_expression_elses
      KW_ELSE expression {
        $$ = new VhdlParseTreeNode(PT_CONDITIONAL_EXPRESSIONS);
        $$->piece_count = 4;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
        $$->pieces[2] = $4;
        $$->pieces[3] = $6;
    }

_one_or_more_conditional_expression_elses:
    _conditional_expression_else
    | _one_or_more_conditional_expression_elses _conditional_expression_else {
        $$ = new VhdlParseTreeNode(PT_CONDITIONAL_EXPRESSION_ELSE_LIST);
        $$->piece_count = 2;
        $$->pieces[0] = $1;
        $$->pieces[1] = $2;
    }

_conditional_expression_else:
    KW_ELSE expression KW_WHEN expression {
        $$ = new VhdlParseTreeNode(PT_CONDITIONAL_EXPRESSION_ELSE);
        $$->piece_count = 2;
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
        $$->piece_count = 4;
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
        $$->pieces[2] = $6;
        $$->pieces[3] = nullptr;
        $$->boolean = false;
    }
    | KW_WITH expression KW_SELECT '?' target DL_LEQ selected_waveforms {
        $$ = new VhdlParseTreeNode(PT_SELECTED_WAVEFORM_ASSIGNMENT);
        $$->piece_count = 4;
        $$->pieces[0] = $2;
        $$->pieces[1] = $5;
        $$->pieces[2] = $7;
        $$->pieces[3] = nullptr;
        $$->boolean = true;
    }
    | KW_WITH expression KW_SELECT
      target DL_LEQ delay_mechanism selected_waveforms {
        $$ = new VhdlParseTreeNode(PT_SELECTED_WAVEFORM_ASSIGNMENT);
        $$->piece_count = 4;
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
        $$->pieces[2] = $7;
        $$->pieces[3] = $6;
        $$->boolean = false;
    }
    | KW_WITH expression KW_SELECT '?'
      target DL_LEQ delay_mechanism selected_waveforms {
        $$ = new VhdlParseTreeNode(PT_SELECTED_WAVEFORM_ASSIGNMENT);
        $$->piece_count = 4;
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
        $$->piece_count = 2;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

_selected_waveform:
    waveform KW_WHEN choices {
        $$ = new VhdlParseTreeNode(PT_SELECTED_WAVEFORM);
        $$->piece_count = 2;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

selected_force_assignment:
    KW_WITH expression KW_SELECT target DL_LEQ KW_FORCE selected_expressions {
        $$ = new VhdlParseTreeNode(PT_SELECTED_FORCE_ASSIGNMENT);
        $$->piece_count = 3;
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
        $$->pieces[2] = $7;
        $$->force_mode = FORCE_UNSPEC;
        $$->boolean = false;
    }
    | KW_WITH expression KW_SELECT target
      DL_LEQ KW_FORCE KW_IN selected_expressions {
        $$ = new VhdlParseTreeNode(PT_SELECTED_FORCE_ASSIGNMENT);
        $$->piece_count = 3;
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
        $$->pieces[2] = $8;
        $$->force_mode = FORCE_IN;
        $$->boolean = false;
    }
    | KW_WITH expression KW_SELECT target
      DL_LEQ KW_FORCE KW_OUT selected_expressions {
        $$ = new VhdlParseTreeNode(PT_SELECTED_FORCE_ASSIGNMENT);
        $$->piece_count = 3;
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
        $$->pieces[2] = $8;
        $$->force_mode = FORCE_OUT;
        $$->boolean = false;
    }
    | KW_WITH expression KW_SELECT '?' target
      DL_LEQ KW_FORCE selected_expressions {
        $$ = new VhdlParseTreeNode(PT_SELECTED_FORCE_ASSIGNMENT);
        $$->piece_count = 3;
        $$->pieces[0] = $2;
        $$->pieces[1] = $5;
        $$->pieces[2] = $8;
        $$->force_mode = FORCE_UNSPEC;
        $$->boolean = true;
    }
    | KW_WITH expression KW_SELECT '?' target
      DL_LEQ KW_FORCE KW_IN selected_expressions {
        $$ = new VhdlParseTreeNode(PT_SELECTED_FORCE_ASSIGNMENT);
        $$->piece_count = 3;
        $$->pieces[0] = $2;
        $$->pieces[1] = $5;
        $$->pieces[2] = $9;
        $$->force_mode = FORCE_IN;
        $$->boolean = true;
    }
    | KW_WITH expression KW_SELECT '?' target
      DL_LEQ KW_FORCE KW_OUT selected_expressions {
        $$ = new VhdlParseTreeNode(PT_SELECTED_FORCE_ASSIGNMENT);
        $$->piece_count = 3;
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
        $$->piece_count = 2;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

_selected_expression:
    expression KW_WHEN choices {
        $$ = new VhdlParseTreeNode(PT_SELECTED_EXPRESSION);
        $$->piece_count = 2;
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
        $$->piece_count = 2;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

conditional_variable_assignment:
    target DL_ASS conditional_expressions {
        $$ = new VhdlParseTreeNode(PT_CONDITIONAL_VARIABLE_ASSIGNMENT);
        $$->piece_count = 2;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

selected_variable_assignment:
    KW_WITH expression KW_SELECT target DL_ASS selected_expressions {
        $$ = new VhdlParseTreeNode(PT_SELECTED_VARIABLE_ASSIGNMENT);
        $$->piece_count = 3;
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
        $$->pieces[2] = $6;
        $$->boolean = false;
    }
    | KW_WITH expression KW_SELECT '?' target DL_ASS selected_expressions {
        $$ = new VhdlParseTreeNode(PT_SELECTED_VARIABLE_ASSIGNMENT);
        $$->piece_count = 3;
        $$->pieces[0] = $2;
        $$->pieces[1] = $5;
        $$->pieces[2] = $7;
        $$->boolean = true;
    }

/// Section 10.7
procedure_call_statement:
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
        $$->piece_count = 5;
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
        $$->pieces[2] = nullptr;
        $$->pieces[3] = nullptr;
        $$->pieces[4] = nullptr;
    }
    | KW_IF expression KW_THEN sequence_of_statements _one_or_more_elsifs
      KW_END KW_IF {
        $$ = new VhdlParseTreeNode(PT_IF_STATEMENT);
        $$->piece_count = 5;
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
        $$->pieces[2] = $5;
        $$->pieces[3] = nullptr;
        $$->pieces[4] = nullptr;
    }
    | KW_IF expression KW_THEN sequence_of_statements
      KW_ELSE sequence_of_statements KW_END KW_IF {
        $$ = new VhdlParseTreeNode(PT_IF_STATEMENT);
        $$->piece_count = 5;
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
        $$->pieces[2] = nullptr;
        $$->pieces[3] = $6;
        $$->pieces[4] = nullptr;
    }
    | KW_IF expression KW_THEN sequence_of_statements 
      _one_or_more_elsifs KW_ELSE sequence_of_statements KW_END KW_IF {
        $$ = new VhdlParseTreeNode(PT_IF_STATEMENT);
        $$->piece_count = 5;
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
        $$->piece_count = 2;
        $$->pieces[0] = $1;
        $$->pieces[1] = $2;
    }

_elsif:
    KW_ELSIF expression KW_THEN sequence_of_statements {
        $$ = new VhdlParseTreeNode(PT_ELSIF);
        $$->piece_count = 2;
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
        $$->piece_count = 3;
        $$->boolean = false;
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
        $$->pieces[2] = nullptr;
    }
    | KW_CASE '?' expression KW_IS _one_or_more_case_statement_alternatives
      KW_END KW_CASE '?' {
        $$ = new VhdlParseTreeNode(PT_CASE_STATEMENT);
        $$->piece_count = 3;
        $$->boolean = true;
        $$->pieces[0] = $3;
        $$->pieces[1] = $5;
        $$->pieces[2] = nullptr;
    }

_one_or_more_case_statement_alternatives:
    case_statement_alternative
    | _one_or_more_case_statement_alternatives case_statement_alternative {
        $$ = new VhdlParseTreeNode(PT_CASE_STATEMENT_ALTERNATIVE_LIST);
        $$->piece_count = 2;
        $$->pieces[0] = $1;
        $$->pieces[1] = $2;
    }

case_statement_alternative:
    KW_WHEN choices DL_ARR sequence_of_statements {
        $$ = new VhdlParseTreeNode(PT_CASE_STATEMENT_ALTERNATIVE);
        $$->piece_count = 2;
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
        $$->piece_count = 3;
        $$->pieces[0] = $2;
        $$->pieces[1] = nullptr;
        $$->pieces[2] = nullptr;
    }
    | iteration_scheme KW_LOOP sequence_of_statements KW_END KW_LOOP {
        $$ = new VhdlParseTreeNode(PT_LOOP_STATEMENT);
        $$->piece_count = 3;
        $$->pieces[0] = $3;
        $$->pieces[1] = $1;
        $$->pieces[2] = nullptr;
    }

iteration_scheme:
    KW_WHILE expression {
        $$ = new VhdlParseTreeNode(PT_ITERATION_WHILE);
        $$->piece_count = 1;
        $$->pieces[0] = $2;
    }
    | KW_FOR parameter_specification {
        $$ = new VhdlParseTreeNode(PT_ITERATION_FOR);
        $$->piece_count = 1;
        $$->pieces[0] = $2;
    }

parameter_specification:
    identifier KW_IN discrete_range {
        $$ = new VhdlParseTreeNode(PT_PARAMETER_SPECIFICATION);
        $$->piece_count = 2;
        $$->pieces[0] = $1;
        $$->pieces[1] = $3;
    }

/// Section 10.11
next_statement:
    KW_NEXT {
        $$ = new VhdlParseTreeNode(PT_NEXT_STATEMENT);
        $$->piece_count = 2;
        $$->pieces[0] = nullptr;
        $$->pieces[1] = nullptr;
    }
    | KW_NEXT identifier {
        $$ = new VhdlParseTreeNode(PT_NEXT_STATEMENT);
        $$->piece_count = 2;
        $$->pieces[0] = $2;
        $$->pieces[1] = nullptr;
    }
    | KW_NEXT KW_WHEN expression {
        $$ = new VhdlParseTreeNode(PT_NEXT_STATEMENT);
        $$->piece_count = 2;
        $$->pieces[0] = nullptr;
        $$->pieces[1] = $3;
    }
    | KW_NEXT identifier KW_WHEN expression {
        $$ = new VhdlParseTreeNode(PT_NEXT_STATEMENT);
        $$->piece_count = 2;
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
    }

/// Section 10.12
exit_statement:
    KW_EXIT {
        $$ = new VhdlParseTreeNode(PT_EXIT_STATEMENT);
        $$->piece_count = 2;
        $$->pieces[0] = nullptr;
        $$->pieces[1] = nullptr;
    }
    | KW_EXIT identifier {
        $$ = new VhdlParseTreeNode(PT_EXIT_STATEMENT);
        $$->piece_count = 2;
        $$->pieces[0] = $2;
        $$->pieces[1] = nullptr;
    }
    | KW_EXIT KW_WHEN expression {
        $$ = new VhdlParseTreeNode(PT_EXIT_STATEMENT);
        $$->piece_count = 2;
        $$->pieces[0] = nullptr;
        $$->pieces[1] = $3;
    }
    | KW_EXIT identifier KW_WHEN expression {
        $$ = new VhdlParseTreeNode(PT_EXIT_STATEMENT);
        $$->piece_count = 2;
        $$->pieces[0] = $2;
        $$->pieces[1] = $4;
    }

/// Section 10.13
return_statement:
    KW_RETURN expression {
        $$ = new VhdlParseTreeNode(PT_RETURN_STATEMENT);
        $$->piece_count = 1;
        $$->pieces[0] = $2;
    }

/// Section 10.14
null_statement:
    KW_NULL {
        $$ = new VhdlParseTreeNode(PT_NULL_STATEMENT);
    }

////////////////////// Concurrent statements, section 11 //////////////////////

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
    // TODO
    KW_PROCESS __maybe_is process_declarative_part KW_BEGIN
    sequence_of_statements KW_END {
        $$ = new VhdlParseTreeNode(PT_PROCESS);
        $$->piece_count = 4;
        $$->boolean = false;
        $$->pieces[0] = nullptr;
        $$->pieces[1] = $3;
        $$->pieces[2] = $5;
        $$->pieces[3] = nullptr;
    }

__maybe_is:
    %empty
    | KW_IS

process_declarative_part:
    // TODO

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

int main(int argc, char **argv) {
    if (argc < 2) {
        cout << "Usage: " << argv[0] << " file.vhd\n";
        return -1;
    }

    FILE *f = fopen(argv[1], "r");
    if (!f) {
        cout << "Error opening " << argv[1] << "\n";
        return -1;
    }
    frontend_vhdl_yyin = f;

    int ret = 1;
    try {
        ret = yyparse();
    } catch(int) {}

    if (ret != 0) {
        cout << "Parse error!\n";
        return 1;
    }

    frontend_vhdl_yylex_destroy();

    parse_output->debug_print();
    cout << "\n";
    delete parse_output;

    fclose(f);
}

void frontend_vhdl_yyerror(const char *msg) {
    cout << "Error " << msg << " on line " << frontend_vhdl_yyget_lineno() << "\n";
}
