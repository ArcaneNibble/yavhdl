#ifndef VHDL_PARSER_GLUE_H
#define VHDL_PARSER_GLUE_H

#include "vhdl_parse_tree.h"

#if defined(VHDL_PARSER_IN_LEXER)
#include "vhdl_parser.tab.h"
#endif

#if defined(VHDL_PARSER_IN_BISON) || \
    defined(VHDL_PARSER_IN_GLUE)
#include "vhdl_parser.tab.h"
#include "lex.frontend_vhdl_yy.h"
#endif

#if defined(VHDL_PARSER_IN_LEXER) || \
    defined(VHDL_PARSER_IN_BISON) || \
    defined(VHDL_PARSER_IN_GLUE)
void frontend_vhdl_yyerror(YYLTYPE *locp, yyscan_t scanner,
    VhdlParseTreeNode **, const char *msg);
#endif

#endif
