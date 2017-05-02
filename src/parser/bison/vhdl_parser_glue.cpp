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

#define VHDL_PARSER_IN_GLUE
#include "vhdl_parser_glue.h"

#include <cstring>

void frontend_vhdl_yyerror(YYLTYPE *locp, yyscan_t scanner,
    VhdlParseTreeNode **, std::string &errors, const char *msg) {
    errors += "Error ";
    errors += msg;
    errors += " on line ";
    errors += std::to_string(frontend_vhdl_yyget_lineno(scanner));
    errors += "\n";
}

VhdlParseTreeNode *VhdlParserParseFile(
    const char *fn, char **errors) {
    yyscan_t myscanner;
    VhdlParseTreeNode *parse_output;

    std::string errors_cpp;

    FILE *f = fopen(fn, "rb");
    if (!f) {
        errors_cpp += "Error opening file \"";
        errors_cpp += fn;
        errors_cpp += "\"\n";
        *errors = strdup(errors_cpp.c_str());
        return nullptr;
    }

    int ret = frontend_vhdl_yylex_init(&myscanner);
    if (ret != 0) {
        errors_cpp += "yylex_init error!\n";
        *errors = strdup(errors_cpp.c_str());
        return nullptr;
    }

    frontend_vhdl_yyset_in(f, myscanner);
    ret = frontend_vhdl_yyparse(myscanner, &parse_output, errors_cpp);
    frontend_vhdl_yylex_destroy(myscanner);
    fclose(f);

    if (ret != 0) {
        errors_cpp += "Parse error!\n";
        *errors = strdup(errors_cpp.c_str());
        return nullptr;
    }

    *errors = strdup(errors_cpp.c_str());
    return parse_output;
}

void VhdlParserFreePT(YaVHDL::Parser::VhdlParseTreeNode *pt) {
    pt->delete_self();
}

void VhdlParserFreeString(char *errors) {
    free(errors);
}

char *VhdlParserCifyString(std::string *str) {
    return strdup(str->c_str());
}

void VhdlParseTreeNodeDebugPrint(YaVHDL::Parser::VhdlParseTreeNode *pt) {
    pt->debug_print();
}
