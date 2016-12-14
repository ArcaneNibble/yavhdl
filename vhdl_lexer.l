%{

#include <iostream>
#include <string>
using namespace std;

#include "vhdl_parser.tab.h"
#include "vhdl_parse_tree.h"

void frontend_vhdl_yyerror(const char *msg);
   
%}

%option yylineno
%option noyywrap
%option nounput
%option prefix="frontend_vhdl_yy"

%x COMMENT
%x STRING
%x BITSTRING

%%

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

[0-9][0-9_]*(\.[0-9][0-9_]*)?([Ee][+-]?[0-9][0-9_]*)?     {
    // Decimal literal
    frontend_vhdl_yylval = new VhdlParseTreeNode(PT_LIT_DECIMAL);
    frontend_vhdl_yylval->str = new std::string(yytext);
    return TOK_DECIMAL;
}

[0-9][0-9_]*#[0-9A-Fa-f][0-9A-Fa-f_]*(\.[0-9A-Fa-f][0-9A-Fa-f_]*)?#([Ee][+-]?[0-9][0-9_]*)?  {
    // Based literal
    frontend_vhdl_yylval = new VhdlParseTreeNode(PT_LIT_BASED);
    frontend_vhdl_yylval->str = new std::string(yytext);
    return TOK_BASED;
}

\"              { BEGIN(STRING); }
<STRING>\"\"    { yymore(); }
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

    frontend_vhdl_yylval = new VhdlParseTreeNode(PT_LIT_STRING);
    frontend_vhdl_yylval->str = new std::string(the_str);
    free(the_str);
    return TOK_STRING;
}
<STRING>[\x20-\x7E\xA0-\xFF]    { yymore(); }
<STRING>\n  {
    frontend_vhdl_yyerror("Illegal newline in string");
    throw 1;
}
<STRING>.   {
    frontend_vhdl_yyerror("Illegal string contents");
    throw 1;
}

[0-9][0-9_]*([US]?[BOX]|D)\"    { BEGIN(BITSTRING); yymore(); }
<BITSTRING>\"\"                 { yymore(); }
<BITSTRING>\"                   {
    BEGIN(0);
    char *the_str = strdup(yytext);

    frontend_vhdl_yylval = new VhdlParseTreeNode(PT_LIT_BITSTRING);

    // Strip last quote
    the_str[strlen(the_str) - 1] = 0;

    // Everything up to the first quote is the base specifier
    size_t main_str_offset = -1;
    for (size_t i = 0; i < strlen(the_str); i++) {
        if (the_str[i] == '"') {
            the_str[i] = 0;
            main_str_offset = i + 1;
            frontend_vhdl_yylval->str2 = new std::string(the_str);
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

    frontend_vhdl_yylval->str = new std::string(the_str + main_str_offset);
    free(the_str);
    return TOK_BITSTRING;
}
<BITSTRING>[\x20-\x7E\xA0-\xFF]    { yymore(); }
<BITSTRING>\n  {
    frontend_vhdl_yyerror("Illegal newline in string");
    throw 1;
}
<BITSTRING>.   {
    frontend_vhdl_yyerror("Illegal string contents");
    throw 1;
}

"/*"            { BEGIN(COMMENT); }
<COMMENT>.      /* ignore comment body */
<COMMENT>\n     /* ignore comment body */
<COMMENT>"*/"   { BEGIN(0); }

[ \xA0\t\v\r\n\f]   /* ignore separators (including NBSP) */
"--"[^\r\n]*        /* ignore single-line comments */

%%
