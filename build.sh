bison -d vhdl_parser.y
flex vhdl_lexer.l
g++ -ggdb3 -Wall vhdl_parser.tab.c lex.frontend_vhdl_yy.c -o vhdl_parser
