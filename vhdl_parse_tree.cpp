#include "vhdl_parse_tree.h"

#include <iostream>
#include <cstring>
using namespace std;

// Keep in sync with enum
const char *parse_tree_types[] = {
    "PT_LIT_NULL",
    "PT_LIT_STRING",
    "PT_LIT_BITSTRING",
    "PT_LIT_DECIMAL",
    "PT_LIT_BASED",
    "PT_LIT_CHAR",

    "PT_BASIC_ID",
    "PT_EXT_ID",

    "PT_NAME_SELECTED",

    "PT_TOK_ALL",
};

void print_chr_escaped(char c) {
    if (c >= 0x20 && c <= 0x7E && c != '"') {
        cout << c;
    } else {
        cout << "\\x" << hex << (+c & 0xFF);
    }
}

void print_string_escaped(std::string *s) {
    for (size_t i = 0; i < s->length(); i++) {
        char c = (*s)[i];
        print_chr_escaped(c);
    }
}

VhdlParseTreeNode::VhdlParseTreeNode(enum ParseTreeNodeType type) {
    this->type = type;

    // Default contents
    this->str = nullptr;
    this->str2 = nullptr;
    this->piece_count = 0;
    memset(this->pieces, 0, sizeof(this->pieces));
}

VhdlParseTreeNode::~VhdlParseTreeNode() {
    // Destroy contents
    delete this->str;
    delete this->str2;
    for (int i = 0; i < this->piece_count; i++) {
        delete this->pieces[i];
    }
}

void VhdlParseTreeNode::debug_print() {
    cout << "{\"type\": \"" << parse_tree_types[this->type] << "\"";

    switch (this->type) {
        case PT_LIT_STRING:
        case PT_LIT_DECIMAL:
        case PT_LIT_BASED:
        case PT_BASIC_ID:
        case PT_EXT_ID:
            cout << ", \"str\": \"";
            print_string_escaped(this->str);
            cout << "\"";
            break;

        case PT_LIT_CHAR:
            cout << ", \"char\": \"";
            print_chr_escaped(this->chr);
            cout << "\"";
            break;

        case PT_LIT_BITSTRING:
            cout << ", \"str\": \"";
            print_string_escaped(this->str);
            cout << "\"";
            cout << ", \"base_str\": \"";
            print_string_escaped(this->str2);
            cout << "\"";
            break;

        case PT_NAME_SELECTED:
            cout << ", \"name\": ";
            this->pieces[0]->debug_print();
            cout << ", \"suffix\": ";
            this->pieces[1]->debug_print();
            break;

        default:
            break;
    }

    cout << "}";
}
