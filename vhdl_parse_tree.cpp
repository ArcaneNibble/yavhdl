#include "vhdl_parse_tree.h"

#include <iostream>
#include <cstring>
using namespace std;

// Names, used for pretty-printing
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
    "PT_NAME_AMBIG_PARENS",
    "PT_NAME_SLICE",
    "PT_NAME_ATTRIBUTE",

    "PT_SIGNATURE",

    "PT_SUBTYPE_INDICATION",

    "PT_EXPRESSION_LIST",
    "PT_ID_LIST",

    "PT_TOK_ALL",

    "PT_UNARY_OPERATOR",
    "PT_BINARY_OPERATOR",
};

const char *parse_operators[] = {
    "??",
    "and",
    "or",
    "nand",
    "nor",
    "xor",
    "xnor",
    "=",
    "/=",
    "<",
    "<=",
    ">",
    ">=",
    "?=",
    "?/=",
    "?<",
    "?<=",
    "?>",
    "?>=",
    "sll",
    "srl",
    "sla",
    "sra",
    "rol",
    "ror",
    "+",
    "-",
    "&",
    "*",
    "/",
    "mod",
    "rem",
    "**",
    "abs",
    "not",
};

// Escape values for JSON output
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

// Create a new parse tree node with type but no data
VhdlParseTreeNode::VhdlParseTreeNode(enum ParseTreeNodeType type) {
    this->type = type;

    // Default contents
    this->str = nullptr;
    this->str2 = nullptr;
    this->chr = 0;
    this->piece_count = 0;
    memset(this->pieces, 0, sizeof(this->pieces));
}

// Destroy a parse tree node and free associated data
VhdlParseTreeNode::~VhdlParseTreeNode() {
    // Destroy contents
    delete this->str;
    delete this->str2;
    // Destroy all pieces for nodes
    // Just in case nodes don't track their count, free the maximum rather than
    // the stored count. This is safe because freeing null is safe.
    for (int i = 0; i < NUM_FIXED_PIECES; i++) {
        delete this->pieces[i];
    }
}

// Pretty-print the node into a JSON-like format
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

        case PT_NAME_AMBIG_PARENS:
        case PT_NAME_SLICE:
            cout << ", \"name\": ";
            this->pieces[0]->debug_print();
            cout << ", \"parens\": ";
            this->pieces[1]->debug_print();
            break;

        case PT_NAME_ATTRIBUTE:
            cout << ", \"name\": ";
            this->pieces[0]->debug_print();
            cout << ", \"attribute\": ";
            this->pieces[1]->debug_print();
            if (this->pieces[2]) {
                cout << ", \"signature\": ";
                this->pieces[2]->debug_print();
            }
            break;

        case PT_SIGNATURE:
            if (this->pieces[0]) {
                cout << ", \"args\": ";
                this->pieces[0]->debug_print();
            }
            if (this->pieces[1]) {
                cout << ", \"ret\": ";
                this->pieces[1]->debug_print();
            }
            break;

        case PT_SUBTYPE_INDICATION:
            cout << ", \"type_mark\": ";
            this->pieces[0]->debug_print();
            if (this->pieces[1]) {
                cout << ", \"resolution_indication\": ";
                this->pieces[1]->debug_print();
            }
            if (this->pieces[2]) {
                cout << ", \"constraint\": ";
                this->pieces[2]->debug_print();
            }
            break;

        case PT_EXPRESSION_LIST:
        case PT_ID_LIST:
            cout << ", \"rest\": ";
            this->pieces[0]->debug_print();
            cout << ", \"this_piece\": ";
            this->pieces[1]->debug_print();
            break;

        case PT_UNARY_OPERATOR:
            cout << ", \"op\": " << parse_operators[this->op_type];
            cout << ", \"x\": ";
            this->pieces[0]->debug_print();
            break;

        case PT_BINARY_OPERATOR:
            cout << ", \"op\": " << parse_operators[this->op_type];
            cout << ", \"x\": ";
            this->pieces[0]->debug_print();
            cout << ", \"y\": ";
            this->pieces[1]->debug_print();
            break;

        default:
            break;
    }

    cout << "}";
}
