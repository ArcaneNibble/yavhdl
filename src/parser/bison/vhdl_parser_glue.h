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

// This file contains both the low-level interface to the lexer/parser as
// well as the internal "stuff" needed to make the lexer/parser work together.

#ifndef VHDL_PARSER_GLUE_H
#define VHDL_PARSER_GLUE_H

#include <string>

#include "vhdl_parse_tree.h"

namespace YaVHDL::Parser
{

// Main wrapper for low-level parser function.
VhdlParseTreeNode *VhdlParserParseFile(const char *fn, std::string &errors);

}

// All the code below here is miscellaneous junk needed for the lexer/parser
// to talk to each other correctly.
#if defined(VHDL_PARSER_IN_LEXER) || \
    defined(VHDL_PARSER_IN_BISON) || \
    defined(VHDL_PARSER_IN_GLUE)
using namespace YaVHDL::Parser;
#endif

#if defined(VHDL_PARSER_IN_LEXER)
#define YY_DECL int frontend_vhdl_yylex \
    (YYSTYPE * yylval_param, YYLTYPE * yylloc_param , yyscan_t yyscanner, \
     std::string &errors)

#include "vhdl_parser_yy.hpp"
#endif

#if defined(VHDL_PARSER_IN_BISON) || \
    defined(VHDL_PARSER_IN_GLUE)
#include "vhdl_parser_yy.hpp"
#include "lex.frontend_vhdl_yy.h"
#endif

#if defined(VHDL_PARSER_IN_BISON)
int frontend_vhdl_yylex
    (YYSTYPE * yylval_param, YYLTYPE * yylloc_param , yyscan_t yyscanner,
     std::string &errors);
#endif

#if defined(VHDL_PARSER_IN_LEXER) || \
    defined(VHDL_PARSER_IN_BISON) || \
    defined(VHDL_PARSER_IN_GLUE)
void frontend_vhdl_yyerror(YYLTYPE *locp, yyscan_t scanner,
    VhdlParseTreeNode **, std::string &errors, const char *msg);
#endif

#endif
