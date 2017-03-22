bison -v -d vhdl_parser.y
flex vhdl_lexer.l
g++ -DVHDL_PARSER_DEMO_MODE -ggdb3 -Wall vhdl_parser.tab.c lex.frontend_vhdl_yy.c vhdl_parse_tree.cpp vhdl_parser_glue.cpp -o vhdl_parser
