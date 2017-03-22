#ifndef VHDL_PARSER_GLUE_H
#define VHDL_PARSER_GLUE_H

#include "vhdl_parse_tree.h"

// This is a hack because we cannot include the lexer header file in the lexer
// .l file but we don't want to have to expose the lexer internal types.
#ifdef VHDL_PARSER_IN_LEXER
void frontend_vhdl_yyerror(YYLTYPE *locp, yyscan_t scanner, const char *msg);
#endif

#endif
