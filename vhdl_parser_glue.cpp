#include <cstdio>
#include <iostream>
#include <string>
using namespace std;

#define VHDL_PARSER_IN_GLUE
#include "vhdl_parser_glue.h"

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
    // frontend_vhdl_yyin = f;

    yyscan_t myscanner;
    frontend_vhdl_yylex_init(&myscanner);
    frontend_vhdl_yyset_in(f, myscanner);
    VhdlParseTreeNode *parse_output;

    int ret = 1;
    try {
        ret = frontend_vhdl_yyparse(myscanner, &parse_output);
    } catch(int) {}

    if (ret != 0) {
        cout << "Parse error!\n";
        return 1;
    }

    frontend_vhdl_yylex_destroy(myscanner);

    parse_output->debug_print();
    cout << "\n";
    delete parse_output;

    fclose(f);
}

void frontend_vhdl_yyerror(YYLTYPE *locp, yyscan_t scanner, VhdlParseTreeNode **, const char *msg) {
    cout << "Error " << msg << " on line " << frontend_vhdl_yyget_lineno(scanner) << "\n";

    // Hack for fuzzing?
    if (strcmp(msg, "syntax is ambiguous") == 0) {
        abort();
    }
}
