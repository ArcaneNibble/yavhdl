%{

#include "vhdl_parser.tab.h"
   
%}

%option yylineno
%option noyywrap
%option nounput
%option prefix="frontend_vhdl_yy"

%x COMMENT

%%

"/*"            { BEGIN(COMMENT); }
<COMMENT>.      /* ignore comment body */
<COMMENT>\n     /* ignore comment body */
<COMMENT>"*/"   { BEGIN(0); }

[ \xA0\t\v\r\n\f]   /* ignore separators (including NBSP) */
"--"[^\r\n]*        /* ignore single-line comments */

%%
