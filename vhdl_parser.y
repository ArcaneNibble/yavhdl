%{

#include <cstdio>
#include <iostream>
using namespace std;

int frontend_vhdl_yylex(void);
void frontend_vhdl_yyerror(const char *msg);
int frontend_vhdl_yyget_lineno(void);
extern FILE *frontend_vhdl_yyin;

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

%%

// Fake start token for testing
not_actualy_design_file:
    ;

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

    yyparse();

}

void frontend_vhdl_yyerror(const char *msg) {
    cout << "Error " << msg << " on line " << frontend_vhdl_yyget_lineno();
}
