#ifndef VHDL_PARSE_TREE_H
#define VHDL_PARSE_TREE_H

#include <string>

enum ParseTreeNodeType
{
    PT_LIT_NULL,
};

struct VhdlParseTreeNode {
    enum ParseTreeNodeType type;

    // Contents
    std::string str;

    VhdlParseTreeNode(enum ParseTreeNodeType type);
    ~VhdlParseTreeNode();

    void debug_print();
};

#endif
