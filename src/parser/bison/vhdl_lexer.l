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

%{

#include <string>

#define VHDL_PARSER_IN_LEXER
#include "vhdl_parser_glue.h"

%}

%{
// Bison location tracking default (obvious) implementation.
#define YY_USER_ACTION do {                         \
    yylloc->first_line = yylineno;                  \
    yylloc->last_line = yylineno;                   \
    yylloc->first_column = yycolumn;                \
    yylloc->last_column = yycolumn + yyleng - 1;    \
    yycolumn += yyleng;                             \
} while(0);

// This is a hack so that alternate lexer states track columns correctly.
#define UNUPDATE_COL() do {         \
    yycolumn -= yyleng;             \
} while(0)
%}

%option yylineno
%option noyywrap
%option nounput
%option prefix="frontend_vhdl_yy"

%option reentrant bison-bridge bison-locations
%option header-file="lex.frontend_vhdl_yy.h"

%x COMMENT
%x STRING
%x BITSTRING
%x EXT_ID

%%

%{
// Reserved words, section 15.10
%}
(?i:abs)                { return KW_ABS; }
(?i:access)             { return KW_ACCESS; }
(?i:after)              { return KW_AFTER; }
(?i:alias)              { return KW_ALIAS; }
(?i:all)                { return KW_ALL; }
(?i:and)                { return KW_AND; }
(?i:architecture)       { return KW_ARCHITECTURE; }
(?i:array)              { return KW_ARRAY; }
(?i:assert)             { return KW_ASSERT; }
(?i:assume)             { return KW_ASSUME; }
(?i:assume_guarantee)   { return KW_ASSUME_GUARANTEE; }
(?i:attribute)          { return KW_ATTRIBUTE; }
(?i:begin)              { return KW_BEGIN; }
(?i:block)              { return KW_BLOCK; }
(?i:body)               { return KW_BODY; }
(?i:buffer)             { return KW_BUFFER; }
(?i:bus)                { return KW_BUS; }
(?i:case)               { return KW_CASE; }
(?i:component)          { return KW_COMPONENT; }
(?i:configuration)      { return KW_CONFIGURATION; }
(?i:constant)           { return KW_CONSTANT; }
(?i:context)            { return KW_CONTEXT; }
(?i:cover)              { return KW_COVER; }
(?i:default)            { return KW_DEFAULT; }
(?i:disconnect)         { return KW_DISCONNECT; }
(?i:downto)             { return KW_DOWNTO; }
(?i:else)               { return KW_ELSE; }
(?i:elsif)              { return KW_ELSIF; }
(?i:end)                { return KW_END; }
(?i:entity)             { return KW_ENTITY; }
(?i:exit)               { return KW_EXIT; }
(?i:fairness)           { return KW_FAIRNESS; }
(?i:file)               { return KW_FILE; }
(?i:for)                { return KW_FOR; }
(?i:force)              { return KW_FORCE; }
(?i:function)           { return KW_FUNCTION; }
(?i:generate)           { return KW_GENERATE; }
(?i:generic)            { return KW_GENERIC; }
(?i:group)              { return KW_GROUP; }
(?i:guarded)            { return KW_GUARDED; }
(?i:if)                 { return KW_IF; }
(?i:impure)             { return KW_IMPURE; }
(?i:in)                 { return KW_IN; }
(?i:inertial)           { return KW_INERTIAL; }
(?i:inout)              { return KW_INOUT; }
(?i:is)                 { return KW_IS; }
(?i:label)              { return KW_LABEL; }
(?i:library)            { return KW_LIBRARY; }
(?i:linkage)            { return KW_LINKAGE; }
(?i:literal)            { return KW_LITERAL; }
(?i:loop)               { return KW_LOOP; }
(?i:map)                { return KW_MAP; }
(?i:mod)                { return KW_MOD; }
(?i:nand)               { return KW_NAND; }
(?i:new)                { return KW_NEW; }
(?i:next)               { return KW_NEXT; }
(?i:nor)                { return KW_NOR; }
(?i:not)                { return KW_NOT; }
(?i:null)               { return KW_NULL; }
(?i:of)                 { return KW_OF; }
(?i:on)                 { return KW_ON; }
(?i:open)               { return KW_OPEN; }
(?i:or)                 { return KW_OR; }
(?i:others)             { return KW_OTHERS; }
(?i:out)                { return KW_OUT; }
(?i:package)            { return KW_PACKAGE; }
(?i:parameter)          { return KW_PARAMETER; }
(?i:port)               { return KW_PORT; }
(?i:postponed)          { return KW_POSTPONED; }
(?i:procedure)          { return KW_PROCEDURE; }
(?i:process)            { return KW_PROCESS; }
(?i:property)           { return KW_PROPERTY; }
(?i:protected)          { return KW_PROTECTED; }
(?i:pure)               { return KW_PURE; }
(?i:range)              { return KW_RANGE; }
(?i:record)             { return KW_RECORD; }
(?i:register)           { return KW_REGISTER; }
(?i:reject)             { return KW_REJECT; }
(?i:release)            { return KW_RELEASE; }
(?i:rem)                { return KW_REM; }
(?i:report)             { return KW_REPORT; }
(?i:restrict)           { return KW_RESTRICT; }
(?i:restrict_guarantee) { return KW_RESTRICT_GUARANTEE; }
(?i:return)             { return KW_RETURN; }
(?i:rol)                { return KW_ROL; }
(?i:ror)                { return KW_ROR; }
(?i:select)             { return KW_SELECT; }
(?i:sequence)           { return KW_SEQUENCE; }
(?i:severity)           { return KW_SEVERITY; }
(?i:shared)             { return KW_SHARED; }
(?i:signal)             { return KW_SIGNAL; }
(?i:sla)                { return KW_SLA; }
(?i:sll)                { return KW_SLL; }
(?i:sra)                { return KW_SRA; }
(?i:srl)                { return KW_SRL; }
(?i:strong)             { return KW_STRONG; }
(?i:subtype)            { return KW_SUBTYPE; }
(?i:then)               { return KW_THEN; }
(?i:to)                 { return KW_TO; }
(?i:transport)          { return KW_TRANSPORT; }
(?i:type)               { return KW_TYPE; }
(?i:unaffected)         { return KW_UNAFFECTED; }
(?i:units)              { return KW_UNITS; }
(?i:until)              { return KW_UNTIL; }
(?i:use)                { return KW_USE; }
(?i:variable)           { return KW_VARIABLE; }
(?i:vmode)              { return KW_VMODE; }
(?i:vprop)              { return KW_VPROP; }
(?i:vunit)              { return KW_VUNIT; }
(?i:wait)               { return KW_WAIT; }
(?i:when)               { return KW_WHEN; }
(?i:while)              { return KW_WHILE; }
(?i:with)               { return KW_WITH; }
(?i:xnor)               { return KW_XNOR; }
(?i:xor)                { return KW_XOR; }

%{
// Multi-character delimiters, section 15.3
%}
"=>"    { return DL_ARR; }
"**"    { return DL_EXP; }
":="    { return DL_ASS; }
"/="    { return DL_NEQ; }
">="    { return DL_GEQ; }
"<="    { return DL_LEQ; }
"<>"    { return DL_BOX; }
"??"    { return DL_QQ; }
"?="    { return DL_MEQ; }
"?/="   { return DL_MNE; }
"?<"    { return DL_MLT; }
"?<="   { return DL_MLE; }
"?>"    { return DL_MGT; }
"?>="   { return DL_MGE; }
"<<"    { return DL_LL; }
">>"    { return DL_RR; }

%{
// Decimal literals, section 15.5.2
%}
[0-9](_?[0-9])*(\.[0-9](_?[0-9])*)?([Ee][+-]?[0-9](_?[0-9])*)?     {
    // Decimal literal
    *yylval = new VhdlParseTreeNode(PT_LIT_DECIMAL);
    (*yylval)->str = new std::string(yytext);
    return TOK_DECIMAL;
}

%{
// Based literals, section 15.5.3
%}
[0-9](_?[0-9])*#[0-9A-Fa-f](_?[0-9A-Fa-f])*(\.[0-9A-Fa-f](_?[0-9A-Fa-f])*)?#([Ee][+-]?[0-9](_?[0-9])*)?  {
    // Based literal
    *yylval = new VhdlParseTreeNode(PT_LIT_BASED);
    (*yylval)->str = new std::string(yytext);
    return TOK_BASED;
}

%{
// Basic identifiers, section 15.4.2
%}
[A-Za-z\xC0-\xD6\xD8-\xF6\xF8-\xFF](_?[A-Za-z\xC0-\xD6\xD8-\xF6\xF8-\xFF0-9])* {
    // FIXME: Are trailing underscores allowed here? On numbers?
    // Basic identifier
    *yylval = new VhdlParseTreeNode(PT_BASIC_ID);
    (*yylval)->str = new std::string(yytext);
    return TOK_BASIC_ID;
}

%{
// Character literals, section 15.6
%}
"'"[\x20-\x7E\xA0-\xFF]"'" {
    // Character literal
    *yylval = new VhdlParseTreeNode(PT_LIT_CHAR);
    (*yylval)->chr = yytext[1];
    return TOK_CHAR;
}

%{
// Extended identifiers, section 15.4.3
// This uses start conditions because all sorts of characters are allowed in
// extended identifiers, including things that will normally lex as something
// else.
%}
\\              { BEGIN(EXT_ID); }
<EXT_ID>\\\\    { UNUPDATE_COL(); yymore(); }
<EXT_ID>\\      {
    BEGIN(0);
    char *the_str = strdup(yytext);

    // Strip last backslash
    the_str[strlen(the_str) - 1] = 0;

    // Undo the backslash escaping
    size_t j = 0;
    for (size_t i = 0; i < strlen(the_str); i++, j++) {
        the_str[j] = the_str[i];
        if (the_str[i] == '\\') i++;
    }
    the_str[j] = 0;

    *yylval = new VhdlParseTreeNode(PT_EXT_ID);
    (*yylval)->str = new std::string(the_str);
    free(the_str);
    return TOK_EXT_ID;
}
<EXT_ID>[\x20-\x7E\xA0-\xFF]    { UNUPDATE_COL(); yymore(); }
<EXT_ID>\n  {
    frontend_vhdl_yyerror(yylloc, yyscanner, nullptr, errors,
        "Illegal newline in extended identifier");
    return LEXER_ERROR;
}
<EXT_ID>.   {
    frontend_vhdl_yyerror(yylloc, yyscanner, nullptr, errors,
        "Illegal extended identifier contents");
    return LEXER_ERROR;
}

%{
// String literals, section 15.7
// This uses almost the same logic as extended identifiers, except that quotes
// need to be doubled rather than backslashes.
%}
\"              { BEGIN(STRING); }
<STRING>\"\"    { UNUPDATE_COL(); yymore(); }
<STRING>\"      {
    BEGIN(0);
    char *the_str = strdup(yytext);

    // Strip last quote
    the_str[strlen(the_str) - 1] = 0;

    // Undo the quote escaping
    size_t j = 0;
    for (size_t i = 0; i < strlen(the_str); i++, j++) {
        the_str[j] = the_str[i];
        if (the_str[i] == '"') i++;
    }
    the_str[j] = 0;

    *yylval = new VhdlParseTreeNode(PT_LIT_STRING);
    (*yylval)->str = new std::string(the_str);
    free(the_str);
    return TOK_STRING;
}
<STRING>[\x20-\x7E\xA0-\xFF]    { UNUPDATE_COL(); yymore(); }
<STRING>\n  {
    frontend_vhdl_yyerror(yylloc, yyscanner, nullptr, errors,
        "Illegal newline in string");
    return LEXER_ERROR;
}
<STRING>.   {
    frontend_vhdl_yyerror(yylloc, yyscanner, nullptr, errors,
        "Illegal string contents");
    return LEXER_ERROR;
}

%{
// Bit string literals, section 15.8
// Again similar logic as strings.
%}
([0-9](_?[0-9])*)?([USus]?[BOXbox]|[Dd])\"    {
    BEGIN(BITSTRING);
    UNUPDATE_COL();
    yymore();
}
<BITSTRING>\"\"                 { UNUPDATE_COL(); yymore(); }
<BITSTRING>\"                   {
    BEGIN(0);
    char *the_str = strdup(yytext);

    *yylval = new VhdlParseTreeNode(PT_LIT_BITSTRING);

    // Strip last quote
    the_str[strlen(the_str) - 1] = 0;

    // Everything up to the first quote is the base specifier
    size_t main_str_offset = -1;
    for (size_t i = 0; i < strlen(the_str); i++) {
        if (the_str[i] == '"') {
            the_str[i] = 0;
            main_str_offset = i + 1;
            (*yylval)->str2 = new std::string(the_str);
            break;
        }
    }

    // Undo the quote escaping
    size_t j = main_str_offset;
    for (size_t i = main_str_offset;
         i - main_str_offset < strlen(the_str + main_str_offset);
         i++, j++) {
        the_str[j] = the_str[i];
        if (the_str[i] == '"') i++;
    }
    the_str[j] = 0;

    (*yylval)->str = new std::string(the_str + main_str_offset);
    free(the_str);
    return TOK_BITSTRING;
}
<BITSTRING>[\x20-\x7E\xA0-\xFF]    { UNUPDATE_COL(); yymore(); }
<BITSTRING>\n  {
    frontend_vhdl_yyerror(yylloc, yyscanner, nullptr, errors,
        "Illegal newline in string");
    return LEXER_ERROR;
}
<BITSTRING>.   {
    frontend_vhdl_yyerror(yylloc, yyscanner, nullptr, errors,
        "Illegal string contents");
    return LEXER_ERROR;
}

%{
// Multi-line comments, section 15.9
%}
"/*"            { BEGIN(COMMENT); }
<COMMENT>.      /* ignore comment body */
<COMMENT>\n     /* ignore comment body */
<COMMENT>"*/"   { BEGIN(0); }

%{
// Single-line comments, section 15.9
%}
"--"[^\r\n]*        /* ignore single-line comments */

%{
// Separators, section 15.3
%}
[ \xA0\t\v\r\f]     /* ignore separators (including NBSP) */
\n                  { yycolumn--; }

%{
// Pass unknown characters to the parser
%}
. { return *yytext; }

%%
