#include "vhdl_parse_tree.h"

#include <iostream>
using namespace std;

// Keep in sync with enum
const char *parse_tree_types[] = {
    "PT_LIT_NULL",
    "PT_LIT_STRING",
};

void print_string_escaped(std::string *s) {
    for (size_t i = 0; i < s->length(); i++) {
        char c = (*s)[i];
        if (c >= 0x20 && c <= 0x7E && c != '"') {
            cout << c;
        } else {
            cout << "\\x" << hex << (+c & 0xFF);
        }
    }
}

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
            cout << ", \"str\": \"";
            print_string_escaped(this->str);
            cout << "\"";
            break;

        default:
            break;
    }

    cout << "}";
}
