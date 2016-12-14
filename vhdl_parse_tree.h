#ifndef VHDL_PARSE_TREE_H
#define VHDL_PARSE_TREE_H

#include <string>

enum ParseTreeNodeType
{
    PT_LIT_NULL,
    PT_LIT_STRING,
    PT_LIT_BITSTRING,
};

struct VhdlParseTreeNode {
    enum ParseTreeNodeType type;

    // Contents
    std::string *str;
    std::string *str2;

    VhdlParseTreeNode(enum ParseTreeNodeType type);
    ~VhdlParseTreeNode();

    void debug_print();
};

#endif
