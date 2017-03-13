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
    "PT_LIT_PHYS",

    "PT_BASIC_ID",
    "PT_EXT_ID",

    "PT_NAME_SELECTED",
    "PT_NAME_AMBIG_PARENS",
    "PT_NAME_SLICE",
    "PT_NAME_ATTRIBUTE",
    "PT_NAME_EXT_CONST",
    "PT_NAME_EXT_SIG",
    "PT_NAME_EXT_VAR",

    "PT_PACKAGE_PATHNAME",
    "PT_ABSOLUTE_PATHNAME",
    "PT_RELATIVE_PATHNAME",
    "PT_PARTIAL_PATHNAME",
    "PT_PATHNAME_ELEMENT",
    "PT_PATHNAME_ELEMENT_GENERATE_LABEL",

    "PT_SIGNATURE",

    "PT_SUBTYPE_INDICATION",
    "PT_RECORD_ELEMENT_RESOLUTION",

    "PT_RANGE",

    "PT_ARRAY_CONSTRAINT",
    "PT_INDEX_CONSTRAINT",
    "PT_RECORD_CONSTRAINT",
    "PT_RECORD_ELEMENT_CONSTRAINT",

    "PT_EXPRESSION_LIST",
    "PT_ID_LIST",
    "PT_RECORD_RESOLUTION",

    "PT_TOK_ALL",
    "PT_TOK_OPEN",

    "PT_UNARY_OPERATOR",
    "PT_BINARY_OPERATOR",

    "PT_AGGREGATE",
    "PT_ELEMENT_ASSOCIATION",
    "PT_CHOICES",
    "PT_CHOICES_OTHER",
    "PT_QUALIFIED_EXPRESSION",
    "PT_ALLOCATOR",

    "PT_FUNCTION_CALL",
    "PT_PARAMETER_ASSOCIATION_LIST",
    "PT_PARAMETER_ASSOCIATION_ELEMENT",
    "PT_FORMAL_PART_FN",

    "PT_STATEMENT_LABEL",
    "PT_RETURN_STATEMENT",
    "PT_NULL_STATEMENT",
    "PT_ASSERTION_STATEMENT",
    "PT_REPORT_STATEMENT",
    "PT_NEXT_STATEMENT",
    "PT_EXIT_STATEMENT",
    "PT_SEQUENCE_OF_STATEMENTS",
    "PT_IF_STATEMENT",
    "PT_ELSIF",
    "PT_ELSIF_LIST",
    "PT_CASE_STATEMENT",
    "PT_CASE_STATEMENT_ALTERNATIVE",
    "PT_CASE_STATEMENT_ALTERNATIVE_LIST",
    "PT_LOOP_STATEMENT",
    "PT_ITERATION_WHILE",
    "PT_ITERATION_FOR",
    "PT_PARAMETER_SPECIFICATION",
    "PT_WAIT_STATEMENT",

    "PT_NAME_LIST",

    "PT_SIMPLE_WAVEFORM_ASSIGNMENT",
    "PT_WAVEFORM",
    "PT_WAVEFORM_UNAFFECTED",
    "PT_WAVEFORM_ELEMENT",
    "PT_DELAY_TRANSPORT",
    "PT_DELAY_INERTIAL",
    "PT_SIMPLE_FORCE_ASSIGNMENT",
    "PT_SIMPLE_RELEASE_ASSIGNMENT",
    "PT_CONDITIONAL_WAVEFORM_ASSIGNMENT",
    "PT_CONDITIONAL_WAVEFORMS",
    "PT_CONDITIONAL_WAVEFORM_ELSE",
    "PT_CONDITIONAL_WAVEFORM_ELSE_LIST",
    "PT_CONDITIONAL_FORCE_ASSIGNMENT",
    "PT_CONDITIONAL_EXPRESSIONS",
    "PT_CONDITIONAL_EXPRESSION_ELSE",
    "PT_CONDITIONAL_EXPRESSION_ELSE_LIST",
    "PT_SELECTED_WAVEFORM_ASSIGNMENT",
    "PT_SELECTED_WAVEFORMS",
    "PT_SELECTED_WAVEFORM",
    "PT_SELECTED_FORCE_ASSIGNMENT",
    "PT_SELECTED_EXPRESSIONS",
    "PT_SELECTED_EXPRESSION",
    "PT_SIMPLE_VARIABLE_ASSIGNMENT",
    "PT_CONDITIONAL_VARIABLE_ASSIGNMENT",
    "PT_SELECTED_VARIABLE_ASSIGNMENT",

    "PT_FULL_TYPE_DECLARATION",
    "PT_ENUMERATION_TYPE_DEFINITION",
    "PT_ENUM_LITERAL_LIST",
    "PT_INTEGER_FLOAT_TYPE_DEFINITION",
    "PT_PHYSICAL_TYPE_DEFINITION",
    "PT_SECONDARY_UNIT_DECLARATION",
    "PT_SECONDARY_UNIT_DECLARATION_LIST",
    "PT_CONSTRAINED_ARRAY_DEFINITION",
    "PT_INDEX_SUBTYPE_DEFINITION_LIST",
    "PT_UNBOUNDED_ARRAY_DEFINITION",
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

const char *range_direction[] = {
    "downto",
    "to",
};

const char *force_modes[] = {
    nullptr,
    "in",
    "out",
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
    this->integer = 0;
    this->boolean = false;
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

        case PT_LIT_PHYS:
            cout << ", \"unit\": ";
            this->pieces[0]->debug_print();
            if (this->pieces[1]) {
                cout << ", \"val\": ";
                this->pieces[1]->debug_print();
            }
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
            if (this->pieces[3]) {
                cout << ", \"expression\": ";
                this->pieces[3]->debug_print();
            }
            break;

        case PT_NAME_EXT_CONST:
        case PT_NAME_EXT_SIG:
        case PT_NAME_EXT_VAR:
            cout << ", \"pathname\": ";
            this->pieces[0]->debug_print();
            cout << ", \"subtype_indication\": ";
            this->pieces[1]->debug_print();
            break;

        case PT_PACKAGE_PATHNAME:
            cout << ", \"library\": ";
            this->pieces[0]->debug_print();
            cout << ", \"package\": ";
            this->pieces[1]->debug_print();
            cout << ", \"object\": ";
            this->pieces[2]->debug_print();
            break;

        case PT_ABSOLUTE_PATHNAME:
            cout << ", \"pathname\": ";
            this->pieces[0]->debug_print();
            break;

        case PT_RELATIVE_PATHNAME:
            cout << ", \"pathname\": ";
            this->pieces[0]->debug_print();
            cout << ", \"up_count\": ";
            cout << this->integer;
            break;

        case PT_PARTIAL_PATHNAME:
            cout << ", \"object\": ";
            this->pieces[0]->debug_print();
            if (this->pieces[1]) {
                cout << ", \"pathname_element\": ";
                this->pieces[1]->debug_print();
            }
            break;

        case PT_PATHNAME_ELEMENT_GENERATE_LABEL:
            cout << ", \"label\": ";
            this->pieces[0]->debug_print();
            cout << ", \"expression\": ";
            this->pieces[1]->debug_print();
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

        case PT_RECORD_ELEMENT_RESOLUTION:
            cout << ", \"element_name\": ";
            this->pieces[0]->debug_print();
            cout << ", \"resolution_indication\": ";
            this->pieces[1]->debug_print();
            break;

        case PT_RANGE:
            cout << ", \"dir\": \"" << range_direction[this->range_dir];
            cout << "\", \"x\": ";
            this->pieces[0]->debug_print();
            cout << ", \"y\": ";
            this->pieces[1]->debug_print();
            break;

        case PT_ARRAY_CONSTRAINT:
            cout << ", \"index_constraint\": ";
            if (this->pieces[0]) {
                this->pieces[0]->debug_print();
            } else {
                cout << "\"open\"";
            }
            if (this->pieces[1]) {
                cout << ", \"element_constraint\": ";
                this->pieces[1]->debug_print();
            }
            break;

        case PT_RECORD_ELEMENT_CONSTRAINT:
            cout << ", \"element_name\": ";
            this->pieces[0]->debug_print();
            cout << ", \"element_constraint\": ";
            this->pieces[1]->debug_print();
            break;

        case PT_ELEMENT_ASSOCIATION:
            cout << ", \"expression\": ";
            this->pieces[0]->debug_print();
            if (this->pieces[1]) {
                cout << ", \"choices\": ";
                this->pieces[1]->debug_print();
            }
            break;

        case PT_QUALIFIED_EXPRESSION:
            cout << ", \"type\": ";
            this->pieces[0]->debug_print();
            cout << ", \"expression\": ";
            this->pieces[1]->debug_print();
            break;

        case PT_ALLOCATOR:
            cout << ", \"alloc\": ";
            this->pieces[0]->debug_print();
            break;

        case PT_FUNCTION_CALL:
            cout << ", \"name\": ";
            this->pieces[0]->debug_print();
            cout << ", \"params\": ";
            this->pieces[1]->debug_print();
            break;

        case PT_PARAMETER_ASSOCIATION_ELEMENT:
            cout << ", \"actual_part\": ";
            this->pieces[0]->debug_print();
            if (this->pieces[1]) {
                cout << ", \"formal_part\": ";
                this->pieces[1]->debug_print();
            }
            break;

        case PT_FORMAL_PART_FN:
            cout << ", \"function\": ";
            this->pieces[0]->debug_print();
            cout << ", \"formal_designator\": ";
            this->pieces[1]->debug_print();
            break;

        case PT_STATEMENT_LABEL:
            cout << ", \"label\": ";
            this->pieces[0]->debug_print();
            cout << ", \"statement\": ";
            this->pieces[1]->debug_print();
            break;

        case PT_RETURN_STATEMENT:
            cout << ", \"expression\": ";
            this->pieces[0]->debug_print();
            break;

        case PT_ASSERTION_STATEMENT:
            cout << ", \"condition\": ";
            this->pieces[0]->debug_print();
            if (this->pieces[1]) {
                cout << ", \"report\": ";
                this->pieces[1]->debug_print();
            }
            if (this->pieces[2]) {
                cout << ", \"severity\": ";
                this->pieces[2]->debug_print();
            }
            break;

        case PT_REPORT_STATEMENT:
            cout << ", \"report\": ";
            this->pieces[0]->debug_print();
            if (this->pieces[1]) {
                cout << ", \"severity\": ";
                this->pieces[1]->debug_print();
            }
            break;

        case PT_NEXT_STATEMENT:
        case PT_EXIT_STATEMENT:
            if (this->pieces[0]) {
                cout << ", \"label\": ";
                this->pieces[0]->debug_print();
            }
            if (this->pieces[1]) {
                cout << ", \"condition\": ";
                this->pieces[1]->debug_print();
            }
            break;

        case PT_IF_STATEMENT:
            cout << ", \"condition\": ";
            this->pieces[0]->debug_print();
            if (this->pieces[1]) {
                cout << ", \"if_arm\": ";
                this->pieces[1]->debug_print();
            }
            if (this->pieces[2]) {
                cout << ", \"elsif_arms\": ";
                this->pieces[2]->debug_print();
            }
            if (this->pieces[3]) {
                cout << ", \"else_arms\": ";
                this->pieces[3]->debug_print();
            }
            if (this->pieces[4]) {
                cout << ", \"end_label\": ";
                this->pieces[4]->debug_print();
            }
            break;

        case PT_ELSIF:
            cout << ", \"condition\": ";
            this->pieces[0]->debug_print();
            if (this->pieces[1]) {
                cout << ", \"statements\": ";
                this->pieces[1]->debug_print();
            }
            break;

        case PT_CASE_STATEMENT:
            cout << ", \"expression\": ";
            this->pieces[0]->debug_print();
            cout << ", \"alternatives\": ";
            this->pieces[1]->debug_print();
            cout << ", \"matching\": ";
            cout << (this->boolean ? "true" : "false");
            if (this->pieces[2]) {
                cout << ", \"end_label\": ";
                this->pieces[2]->debug_print();
            }
            break;

        case PT_CASE_STATEMENT_ALTERNATIVE:
            cout << ", \"choices\": ";
            this->pieces[0]->debug_print();
            if (this->pieces[1]) {
                cout << ", \"statements\": ";
                this->pieces[1]->debug_print();
            }
            break;

        case PT_LOOP_STATEMENT:
            cout << ", \"statements\": ";
            this->pieces[0]->debug_print();
            if (this->pieces[1]) {
                cout << ", \"scheme\": ";
                this->pieces[1]->debug_print();
            }
            if (this->pieces[2]) {
                cout << ", \"end_label\": ";
                this->pieces[2]->debug_print();
            }
            break;

        case PT_ITERATION_WHILE:
            cout << ", \"condition\": ";
            this->pieces[0]->debug_print();
            break;

        case PT_ITERATION_FOR:
            cout << ", \"parameter_specification\": ";
            this->pieces[0]->debug_print();
            break;

        case PT_PARAMETER_SPECIFICATION:
            cout << ", \"identifier\": ";
            this->pieces[0]->debug_print();
            cout << ", \"range\": ";
            this->pieces[1]->debug_print();
            break;

        case PT_WAIT_STATEMENT:
            if (this->pieces[0]) {
                cout << ", \"sensitivity\": ";
                this->pieces[0]->debug_print();
            }
            if (this->pieces[1]) {
                cout << ", \"condition\": ";
                this->pieces[1]->debug_print();
            }
            if (this->pieces[2]) {
                cout << ", \"timeout\": ";
                this->pieces[2]->debug_print();
            }
            break;

        case PT_SIMPLE_WAVEFORM_ASSIGNMENT:
        case PT_CONDITIONAL_WAVEFORM_ASSIGNMENT:
            cout << ", \"target\": ";
            this->pieces[0]->debug_print();
            cout << ", \"waveform\": ";
            this->pieces[1]->debug_print();
            if (this->pieces[2]) {
                cout << ", \"delay_mechanism\": ";
                this->pieces[2]->debug_print();
            }
            break;

        case PT_WAVEFORM_ELEMENT:
            cout << ", \"value\": ";
            this->pieces[0]->debug_print();
            if (this->pieces[1]) {
                cout << ", \"time\": ";
                this->pieces[1]->debug_print();
            }
            break;

        case PT_DELAY_INERTIAL:
            if (this->pieces[0]) {
                cout << ", \"reject\": ";
                this->pieces[0]->debug_print();
            }
            break;

        case PT_SIMPLE_FORCE_ASSIGNMENT:
        case PT_CONDITIONAL_FORCE_ASSIGNMENT:
            cout << ", \"target\": ";
            this->pieces[0]->debug_print();
            cout << ", \"expression\": ";
            this->pieces[1]->debug_print();
            if (this->force_mode != FORCE_UNSPEC) {
                cout << ", \"force_mode\": \"";
                cout << force_modes[this->force_mode];
                cout << "\"";
            }
            break;

        case PT_SIMPLE_RELEASE_ASSIGNMENT:
            cout << ", \"target\": ";
            this->pieces[0]->debug_print();
            if (this->force_mode != FORCE_UNSPEC) {
                cout << ", \"force_mode\": \"";
                cout << force_modes[this->force_mode];
                cout << "\"";
            }
            break;

        case PT_CONDITIONAL_WAVEFORMS:
        case PT_CONDITIONAL_EXPRESSIONS:
            cout << ", \"main_value\": ";
            this->pieces[0]->debug_print();
            cout << ", \"main_condition\": ";
            this->pieces[1]->debug_print();
            if (this->pieces[2]) {
                cout << ", \"elses\": ";
                this->pieces[2]->debug_print();
            }
            if (this->pieces[3]) {
                cout << ", \"else_value\": ";
                this->pieces[3]->debug_print();
            }
            break;

        case PT_CONDITIONAL_WAVEFORM_ELSE:
        case PT_CONDITIONAL_EXPRESSION_ELSE:
            cout << ", \"value\": ";
            this->pieces[0]->debug_print();
            cout << ", \"condition\": ";
            this->pieces[1]->debug_print();
            break;

        case PT_SELECTED_WAVEFORM_ASSIGNMENT:
            cout << ", \"expression\": ";
            this->pieces[0]->debug_print();
            cout << ", \"target\": ";
            this->pieces[1]->debug_print();
            cout << ", \"waveform\": ";
            this->pieces[2]->debug_print();
            if (this->pieces[3]) {
                cout << ", \"delay_mechanism\": ";
                this->pieces[3]->debug_print();
            }
            cout << ", \"matching\": ";
            cout << (this->boolean ? "true" : "false");
            break;

        case PT_SELECTED_FORCE_ASSIGNMENT:
            cout << ", \"expression\": ";
            this->pieces[0]->debug_print();
            cout << ", \"target\": ";
            this->pieces[1]->debug_print();
            cout << ", \"selected_expression\": ";
            this->pieces[2]->debug_print();
            if (this->force_mode != FORCE_UNSPEC) {
                cout << ", \"force_mode\": \"";
                cout << force_modes[this->force_mode];
                cout << "\"";
            }
            cout << ", \"matching\": ";
            cout << (this->boolean ? "true" : "false");
            break;

        case PT_SELECTED_WAVEFORM:
        case PT_SELECTED_EXPRESSION:
            cout << ", \"waveform\": ";
            this->pieces[0]->debug_print();
            cout << ", \"choices\": ";
            this->pieces[1]->debug_print();
            break;

        case PT_SIMPLE_VARIABLE_ASSIGNMENT:
        case PT_CONDITIONAL_VARIABLE_ASSIGNMENT:
            cout << ", \"target\": ";
            this->pieces[0]->debug_print();
            cout << ", \"expression\": ";
            this->pieces[1]->debug_print();
            break;

        case PT_SELECTED_VARIABLE_ASSIGNMENT:
            cout << ", \"expression\": ";
            this->pieces[0]->debug_print();
            cout << ", \"target\": ";
            this->pieces[1]->debug_print();
            cout << ", \"selected_expression\": ";
            this->pieces[2]->debug_print();
            cout << ", \"matching\": ";
            cout << (this->boolean ? "true" : "false");
            break;

        case PT_FULL_TYPE_DECLARATION:
            cout << ", \"identifier\": ";
            this->pieces[0]->debug_print();
            cout << ", \"definition\": ";
            this->pieces[1]->debug_print();
            break;

        case PT_ENUMERATION_TYPE_DEFINITION:
            cout << ", \"literals\": ";
            this->pieces[0]->debug_print();
            break;

        case PT_INTEGER_FLOAT_TYPE_DEFINITION:
            cout << ", \"range\": ";
            this->pieces[0]->debug_print();
            break;

        case PT_PHYSICAL_TYPE_DEFINITION:
            cout << ", \"range\": ";
            this->pieces[0]->debug_print();
            cout << ", \"primary\": ";
            this->pieces[1]->debug_print();
            if (this->pieces[2]) {
                cout << ", \"secondaries\": ";
                this->pieces[2]->debug_print();
            }
            if (this->pieces[3]) {
                cout << ", \"end_label\": ";
                this->pieces[3]->debug_print();
            }
            break;

        case PT_SECONDARY_UNIT_DECLARATION:
            cout << ", \"identifier\": ";
            this->pieces[0]->debug_print();
            cout << ", \"literal\": ";
            this->pieces[1]->debug_print();
            break;

        case PT_CONSTRAINED_ARRAY_DEFINITION:
        case PT_UNBOUNDED_ARRAY_DEFINITION:
            cout << ", \"index_constraint\": ";
            this->pieces[0]->debug_print();
            cout << ", \"element\": ";
            this->pieces[1]->debug_print();
            break;

        case PT_EXPRESSION_LIST:
        case PT_ID_LIST:
        case PT_RECORD_RESOLUTION:
        case PT_INDEX_CONSTRAINT:
        case PT_RECORD_CONSTRAINT:
        case PT_PATHNAME_ELEMENT:
        case PT_AGGREGATE:
        case PT_CHOICES:
        case PT_PARAMETER_ASSOCIATION_LIST:
        case PT_SEQUENCE_OF_STATEMENTS:
        case PT_ELSIF_LIST:
        case PT_CASE_STATEMENT_ALTERNATIVE_LIST:
        case PT_NAME_LIST:
        case PT_WAVEFORM:
        case PT_CONDITIONAL_WAVEFORM_ELSE_LIST:
        case PT_CONDITIONAL_EXPRESSION_ELSE_LIST:
        case PT_SELECTED_WAVEFORMS:
        case PT_SELECTED_EXPRESSIONS:
        case PT_ENUM_LITERAL_LIST:
        case PT_SECONDARY_UNIT_DECLARATION_LIST:
        case PT_INDEX_SUBTYPE_DEFINITION_LIST:
            if (this->pieces[0]) {
                cout << ", \"rest\": ";
                this->pieces[0]->debug_print();
            }
            cout << ", \"this_piece\": ";
            this->pieces[1]->debug_print();
            break;

        case PT_UNARY_OPERATOR:
            cout << ", \"op\": \"" << parse_operators[this->op_type];
            cout << "\", \"x\": ";
            this->pieces[0]->debug_print();
            break;

        case PT_BINARY_OPERATOR:
            cout << ", \"op\": \"" << parse_operators[this->op_type];
            cout << "\", \"x\": ";
            this->pieces[0]->debug_print();
            cout << ", \"y\": ";
            this->pieces[1]->debug_print();
            break;

        default:
            break;
    }

    cout << "}";
}
