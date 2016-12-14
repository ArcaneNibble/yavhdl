#include "vhdl_parse_tree.h"

#include <iostream>
using namespace std;

// Keep in sync with enum
const char *parse_tree_types[] = {
    "PT_LIT_NULL",
    "PT_LIT_STRING",
};

VhdlParseTreeNode::VhdlParseTreeNode(enum ParseTreeNodeType type) {
    this->type = type;

    // Default contents
    this->str = nullptr;
}

VhdlParseTreeNode::~VhdlParseTreeNode() {
    // Destroy contents
    delete this->str;
}

void VhdlParseTreeNode::debug_print() {
    cout << "{\"type\": \"" << parse_tree_types[this->type] << "\"";

    switch (this->type) {
        case PT_LIT_STRING:
            cout << ", \"str\": \"" << *this->str << "\"";
            break;

        default:
            break;
    }

    cout << "}";
}
