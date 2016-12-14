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

    PT_NAME_SELECTED,

    PT_TOK_ALL,

    PT_UNARY_OPERATOR,
    PT_BINARY_OPERATOR,
};

enum ParseTreeOperatorType
{
    OP_COND,
    OP_AND,
    OP_OR,
    OP_NAND,
    OP_NOR,
    OP_XOR,
    OP_XNOR,
    OP_EQ,
    OP_NEQ,
    OP_LT,
    OP_LTE,
    OP_GT,
    OP_GTE,
    OP_MEQ,
    OP_MNE,
    OP_MLT,
    OP_MLE,
    OP_MGT,
    OP_MGE,
    OP_SLL,
    OP_SRL,
    OP_SLA,
    OP_SRA,
    OP_ROL,
    OP_ROR,
    OP_ADD,
    OP_SUB,
    OP_CONCAT,
    OP_MUL,
    OP_DIV,
    OP_MOD,
    OP_REM,
    OP_EXP,
    OP_ABS,
    OP_NOT,
};

#define NUM_FIXED_PIECES 8

struct VhdlParseTreeNode {
    enum ParseTreeNodeType type;

    // Contents
    std::string *str;
    std::string *str2;
    char chr;
    struct VhdlParseTreeNode *pieces[NUM_FIXED_PIECES];
    int piece_count;

    ParseTreeOperatorType op_type;

    VhdlParseTreeNode(enum ParseTreeNodeType type);
    ~VhdlParseTreeNode();

    void debug_print();
};

#endif
