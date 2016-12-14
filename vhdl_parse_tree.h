#ifndef VHDL_PARSE_TREE_H
#define VHDL_PARSE_TREE_H

#include <string>

enum ParseTreeNodeType
{
    PT_LIT_NULL,
    PT_LIT_STRING,
    PT_LIT_BITSTRING,
    PT_LIT_DECIMAL,
    PT_LIT_BASED,
    PT_LIT_CHAR,

    PT_BASIC_ID,
    PT_EXT_ID,
};

struct VhdlParseTreeNode {
    enum ParseTreeNodeType type;

    // Contents
    std::string *str;
    std::string *str2;
    char chr;

    VhdlParseTreeNode(enum ParseTreeNodeType type);
    ~VhdlParseTreeNode();

    void debug_print();
};

#endif
