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
