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
