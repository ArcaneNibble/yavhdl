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

%define parse.error verbose
%define parse.lac full
%debug

// Reserved keywords
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

// Multi-character delimiters
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
    name;

// This is a super hacked up version of the name grammar production
// It accepts far more than it should. This will be disambiguated in a second
// pass that is not part of the (generated) parser.
name:
    identifier              // was simple_name
    | string_literal        // was operator_symbol
    | character_literal
    | name '.' suffix   {   // was selected_name
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

literal:
    numeric_literal
    | enumeration_literal
    | string_literal
    | bit_string_literal
    | KW_NULL   { $$ = new VhdlParseTreeNode(PT_LIT_NULL); }

numeric_literal:
    abstract_literal
    // TODO

abstract_literal:
    decimal_literal
    | based_literal

enumeration_literal:
    identifier
    | character_literal

based_literal: TOK_BASED
bit_string_literal: TOK_BITSTRING
character_literal: TOK_CHAR
decimal_literal: TOK_DECIMAL
string_literal: TOK_STRING

identifier:
    basic_identifier
    | extended_identifier

basic_identifier: TOK_BASIC_ID
extended_identifier: TOK_EXT_ID

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
