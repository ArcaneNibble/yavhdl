#include "vhdl_parse_tree.h"

#include <iostream>
using namespace std;

// Keep in sync with enum
const char *parse_tree_types[] = {
    "PT_LIT_NULL",
};

VhdlParseTreeNode::VhdlParseTreeNode(enum ParseTreeNodeType type) {
    this->type = type;
}

VhdlParseTreeNode::~VhdlParseTreeNode() {

}

void VhdlParseTreeNode::debug_print() {
    cout << "{\"type\": \"" << parse_tree_types[this->type] << "\",";

    cout << "}";
}
