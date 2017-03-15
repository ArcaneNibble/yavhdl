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
    "PT_RECORD_TYPE_DEFINITION",
    "PT_ELEMENT_DECLARATION",
    "PT_ELEMENT_DECLARATION_LIST",
    "PT_ID_LIST_REAL",
    "PT_ACCESS_TYPE_DEFINITION",
    "PT_INCOMPLETE_TYPE_DECLARATION",
    "PT_FILE_TYPE_DEFINITION",

    "PT_PROCESS",
    "PT_DECLARATION_LIST",

    "PT_SUBTYPE_DECLARATION",
    "PT_CONSTANT_DECLARATION",
    "PT_VARIABLE_DECLARATION",
    "PT_FILE_DECLARATION",
    "PT_ALIAS_DECLARATION",
    "PT_FILE_OPEN_INFORMATION",
    "PT_ATTRIBUTE_DECLARATION",
    "PT_SUBPROGRAM_DECLARATION",
    "PT_PROCEDURE_SPECIFICATION",
    "PT_FUNCTION_SPECIFICATION",
    "PT_SUBPROGRAM_HEADER",
    "PT_INTERFACE_LIST",
    "PT_INTERFACE_FILE_DECLARATION",
    "PT_INTERFACE_AMBIG_OBJ_DECLARATION",
    "PT_INTERFACE_CONSTANT_DECLARATION",
    "PT_INTERFACE_SIGNAL_DECLARATION",
    "PT_INTERFACE_VARIABLE_DECLARATION",
    "PT_INTERFACE_MODE",
    "PT_INTERFACE_TYPE_DECLARATION",
    "PT_INTERFACE_SUBPROGRAM_DECLARATION",
    "PT_INTERFACE_PROCEDURE_SPECIFICATION",
    "PT_INTERFACE_FUNCTION_SPECIFICATION",
    "PT_INTERFACE_SUBPROGRAM_DEFAULT_BOX",

    "PT_GENERIC_MAP_ASPECT",
    "PT_PORT_MAP_ASPECT",
    "PT_ASSOCIATION_LIST",
    "PT_ASSOCIATION_ELEMENT",
    "PT_INERTIAL_EXPRESSION",

    "PT_SUBPROGRAM_INSTANTIATION_DECLARATION",

    "PT_SUBPROGRAM_BODY",
    "PT_SUBTYPE_INDICATION_AMBIG_WTF",

    "PT_ELEMENT_RESOLUTION_NEST",

    "PT_USE_CLAUSE",
    "PT_SELECTED_NAME_LIST",

    "PT_ATTRIBUTE_SPECIFICATION",
    "PT_ENTITY_SPECIFICATION",
    "PT_ENTITY_CLASS",
    "PT_ENTITY_NAME_LIST",
    "PT_ENTITY_NAME_LIST_OTHERS",
    "PT_ENTITY_NAME_LIST_ALL",
    "PT_ENTITY_DESIGNATOR",

    "PT_GROUP_TEMPLATE_DECLARATION",
    "PT_ENTITY_CLASS_ENTRY_LIST",
    "PT_ENTITY_CLASS_ENTRY",

    "PT_GROUP_DECLARATION",

    "PT_PACKAGE_DECLARATION",
    "PT_PACKAGE_HEADER",

    "PT_SIGNAL_DECLARATION",
    "PT_SIGNAL_KIND",

    "PT_PACKAGE_BODY",

    "PT_PACKAGE_INSTANTIATION_DECLARATION",

    "PT_INTERFACE_PACKAGE_DECLARATION",
    "PT_INTERFACE_PACKAGE_GENERIC_MAP_BOX",
    "PT_INTERFACE_PACKAGE_GENERIC_MAP_DEFAULT",

    "PT_PROTECTED_TYPE_DECLARATION",
    "PT_PROTECTED_TYPE_BODY",

    "PT_COMPONENT_DECLARATION",

    "PT_DISCONNECTION_SPECIFICATION",
    "PT_GUARDED_SIGNAL_SPECIFICATION",
    "PT_SIGNAL_LIST_OTHERS",
    "PT_SIGNAL_LIST_ALL",

    "PT_CONCURRENT_PROCEDURE_CALL",
    "PT_CONCURRENT_ASSERTION_STATEMENT",

    "PT_COMPONENT_INSTANTIATION",
    "PT_INSTANTIATED_UNIT_COMPONENT",
    "PT_INSTANTIATED_UNIT_ENTITY",
    "PT_INSTANTIATED_UNIT_CONFIGURATION",

    "PT_CONCURRENT_SIMPLE_SIGNAL_ASSIGNMENT",
    "PT_CONCURRENT_CONDITIONAL_SIGNAL_ASSIGNMENT",
    "PT_CONCURRENT_SELECTED_SIGNAL_ASSIGNMENT",

    "PT_SEQUENCE_OF_CONCURRENT_STATEMENTS",

    "PT_BLOCK",
    "PT_BLOCK_HEADER",

    "PT_FOR_GENERATE",
    "PT_IF_GENERATE",
    "PT_CASE_GENERATE",
    "PT_GENERATE_BODY",
    "PT_IF_GENERATE_ELSIF",
    "PT_IF_GENERATE_ELSIF_LIST",
    "PT_CASE_GENERATE_ALTERNATIVE",
    "PT_CASE_GENERATE_ALTERNATIVE_LIST",

    "PT_SIMPLE_CONFIGURATION_SPECIFICATION",
    "PT_INSTANTIATION_LIST_OTHERS",
    "PT_INSTANTIATION_LIST_ALL",
    "PT_COMPONENT_SPECIFICATION",
    "PT_BINDING_INDICATION",
    "PT_ENTITY_ASPECT_ENTITY",
    "PT_ENTITY_ASPECT_CONFIGURATION",
    "PT_ENTITY_ASPECT_OPEN",
    "PT_VERIFICATION_UNIT_BINDING_INDICATION",
    "PT_VERIFICATION_UNIT_BINDING_INDICATION_LIST",
    "PT_COMPOUND_CONFIGURATION_SPECIFICATION",

    "PT_ENTITY",
    "PT_ENTITY_HEADER",

    "PT_CONTEXT_DECLARATION",
    "PT_LIBRARY_CLAUSE",
    "PT_CONTEXT_REFERENCE",
    "PT_CONTEXT_CLAUSE",
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

const char *func_purity[] = {
    nullptr,
    "pure",
    "impure",
};

const char *interface_modes[] = {
    nullptr,
    "in",
    "out",
    "inout",
    "buffer",
    "linkage",
};

const char *subprogram_kinds[] = {
    nullptr,
    "procedure",
    "function",
};

const char *entity_classes[] = {
    "entity",
    "architecture",
    "configuration",
    "procedure",
    "function",
    "package",
    "type",
    "subtype",
    "constant",
    "signal",
    "variable",
    "component",
    "label",
    "literal",
    "units",
    "group",
    "file",
    "property",
    "sequence",
};

const char *signal_kinds[] = {
    nullptr,
    "register",
    "bus",
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
        case PT_ASSOCIATION_ELEMENT:
            cout << ", \"actual_part\": ";
            this->pieces[0]->debug_print();
            if (this->pieces[1]) {
                cout << ", \"formal_part\": ";
                this->pieces[1]->debug_print();
            }
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

        case PT_RECORD_TYPE_DEFINITION:
            cout << ", \"elements\": ";
            this->pieces[0]->debug_print();
            if (this->pieces[1]) {
                cout << ", \"end_label\": ";
                this->pieces[1]->debug_print();
            }
            break;

        case PT_ELEMENT_DECLARATION:
            cout << ", \"identifiers\": ";
            this->pieces[0]->debug_print();
            cout << ", \"subtype\": ";
            this->pieces[1]->debug_print();
            break;

        case PT_ACCESS_TYPE_DEFINITION:
            cout << ", \"subtype\": ";
            this->pieces[0]->debug_print();
            break;

        case PT_INCOMPLETE_TYPE_DECLARATION:
        case PT_INTERFACE_TYPE_DECLARATION:
            cout << ", \"identifier\": ";
            this->pieces[0]->debug_print();
            break;

        case PT_FILE_TYPE_DEFINITION:
            cout << ", \"type_mark\": ";
            this->pieces[0]->debug_print();
            break;

        case PT_PROCESS:
            if (this->pieces[0]) {
                cout << ", \"label\": ";
                this->pieces[0]->debug_print();
            }
            if (this->pieces[1]) {
                cout << ", \"declarations\": ";
                this->pieces[1]->debug_print();
            }
            if (this->pieces[2]) {
                cout << ", \"statements\": ";
                this->pieces[2]->debug_print();
            }
            if (this->pieces[3]) {
                cout << ", \"end_label\": ";
                this->pieces[3]->debug_print();
            }
            if (this->pieces[4]) {
                cout << ", \"sensitivity_list\": ";
                this->pieces[4]->debug_print();
            }
            cout << ", \"postponed\": ";
            cout << (this->boolean ? "true" : "false");
            break;

        case PT_SUBTYPE_DECLARATION:
            cout << ", \"identifier\": ";
            this->pieces[0]->debug_print();
            cout << ", \"subtype\": ";
            this->pieces[1]->debug_print();
            break;

        case PT_CONSTANT_DECLARATION:
            cout << ", \"identifiers\": ";
            this->pieces[0]->debug_print();
            cout << ", \"subtype\": ";
            this->pieces[1]->debug_print();
            if (this->pieces[2]) {
                cout << ", \"expression\": ";
                this->pieces[2]->debug_print();
            }
            break;

        case PT_VARIABLE_DECLARATION:
            cout << ", \"identifiers\": ";
            this->pieces[0]->debug_print();
            cout << ", \"subtype\": ";
            this->pieces[1]->debug_print();
            if (this->pieces[2]) {
                cout << ", \"expression\": ";
                this->pieces[2]->debug_print();
            }
            cout << ", \"shared\": ";
            cout << (this->boolean ? "true" : "false");
            break;

        case PT_FILE_DECLARATION:
        case PT_INTERFACE_FILE_DECLARATION:
            cout << ", \"identifiers\": ";
            this->pieces[0]->debug_print();
            cout << ", \"subtype\": ";
            this->pieces[1]->debug_print();
            if (this->pieces[2]) {
                cout << ", \"open_information\": ";
                this->pieces[2]->debug_print();
            }
            break;

        case PT_FILE_OPEN_INFORMATION:
            cout << ", \"logical_name\": ";
            this->pieces[0]->debug_print();
            if (this->pieces[1]) {
                cout << ", \"open_kind\": ";
                this->pieces[1]->debug_print();
            }
            break;

        case PT_ALIAS_DECLARATION:
            cout << ", \"designator\": ";
            this->pieces[0]->debug_print();
            cout << ", \"name\": ";
            this->pieces[1]->debug_print();
            if (this->pieces[2]) {
                cout << ", \"subtype\": ";
                this->pieces[2]->debug_print();
            }
            if (this->pieces[3]) {
                cout << ", \"signature\": ";
                this->pieces[3]->debug_print();
            }
            break;

        case PT_ATTRIBUTE_DECLARATION:
            cout << ", \"identifier\": ";
            this->pieces[0]->debug_print();
            cout << ", \"type_mark\": ";
            this->pieces[1]->debug_print();
            break;

        case PT_SUBPROGRAM_DECLARATION:
            cout << ", \"specification\": ";
            this->pieces[0]->debug_print();
            break;

        case PT_PROCEDURE_SPECIFICATION:
            cout << ", \"designator\": ";
            this->pieces[0]->debug_print();
            if (this->pieces[1]) {
                cout << ", \"header\": ";
                this->pieces[1]->debug_print();
            }
            if (this->pieces[2]) {
                cout << ", \"parameters\": ";
                this->pieces[2]->debug_print();
            }
            break;

        case PT_FUNCTION_SPECIFICATION:
            cout << ", \"designator\": ";
            this->pieces[0]->debug_print();
            cout << ", \"return\": ";
            this->pieces[1]->debug_print();
            if (this->pieces[2]) {
                cout << ", \"header\": ";
                this->pieces[2]->debug_print();
            }
            if (this->pieces[3]) {
                cout << ", \"parameters\": ";
                this->pieces[3]->debug_print();
            }
            if (this->purity != PURITY_UNSPEC) {
                cout << ", \"purity\": \"";
                cout << func_purity[this->purity];
                cout << "\"";
            }
            break;

        case PT_SUBPROGRAM_HEADER:
        case PT_PACKAGE_HEADER:
            if (this->pieces[0]) {
                cout << ", \"generic\": ";
                this->pieces[0]->debug_print();
            }
            if (this->pieces[1]) {
                cout << ", \"generic_map\": ";
                this->pieces[1]->debug_print();
            }
            break;

        case PT_INTERFACE_SIGNAL_DECLARATION:
            cout << ", \"is_bus\": ";
            cout << (this->boolean ? "true" : "false");
        case PT_INTERFACE_AMBIG_OBJ_DECLARATION:
        case PT_INTERFACE_CONSTANT_DECLARATION:
        case PT_INTERFACE_VARIABLE_DECLARATION:
            cout << ", \"identifiers\": ";
            this->pieces[0]->debug_print();
            cout << ", \"subtype\": ";
            this->pieces[1]->debug_print();
            if (this->pieces[2]) {
                cout << ", \"expression\": ";
                this->pieces[2]->debug_print();
            }
            if (this->pieces[3]) {
                cout << ", \"mode\": ";
                this->pieces[3]->debug_print();
            }
            break;

        case PT_INTERFACE_MODE:
            if (this->interface_mode != MODE_UNSPEC) {
                cout << ", \"mode\": \"";
                cout << interface_modes[this->interface_mode];
                cout << "\"";
            }
            break;

        case PT_INTERFACE_SUBPROGRAM_DECLARATION:
            cout << ", \"specification\": ";
            this->pieces[0]->debug_print();
            if (this->pieces[1]) {
                cout << ", \"default\": ";
                this->pieces[1]->debug_print();
            }
            break;

        case PT_INTERFACE_PROCEDURE_SPECIFICATION:
            cout << ", \"designator\": ";
            this->pieces[0]->debug_print();
            if (this->pieces[1]) {
                cout << ", \"parameters\": ";
                this->pieces[1]->debug_print();
            }
            break;

        case PT_INTERFACE_FUNCTION_SPECIFICATION:
            cout << ", \"designator\": ";
            this->pieces[0]->debug_print();
            cout << ", \"return\": ";
            this->pieces[1]->debug_print();
            if (this->pieces[2]) {
                cout << ", \"parameters\": ";
                this->pieces[2]->debug_print();
            }
            if (this->purity != PURITY_UNSPEC) {
                cout << ", \"purity\": \"";
                cout << func_purity[this->purity];
                cout << "\"";
            }
            break;

        case PT_GENERIC_MAP_ASPECT:
        case PT_PORT_MAP_ASPECT:
            cout << ", \"association_list\": ";
            this->pieces[0]->debug_print();
            break;

        case PT_INERTIAL_EXPRESSION:
            cout << ", \"expression\": ";
            this->pieces[0]->debug_print();
            break;

        case PT_SUBPROGRAM_INSTANTIATION_DECLARATION:
            cout << ", \"kind\": \"";
            cout << subprogram_kinds[this->subprogram_kind];
            cout << "\"";
            cout << ", \"designator\": ";
            this->pieces[0]->debug_print();
            cout << ", \"uninstantiated_name\": ";
            this->pieces[1]->debug_print();
            if (this->pieces[2]) {
                cout << ", \"signature\": ";
                this->pieces[2]->debug_print();
            }
            if (this->pieces[3]) {
                cout << ", \"generic_map\": ";
                this->pieces[3]->debug_print();
            }
            break;

        case PT_SUBPROGRAM_BODY:
            cout << ", \"specification\": ";
            this->pieces[0]->debug_print();
            if (this->pieces[1]) {
                cout << ", \"declarations\": ";
                this->pieces[1]->debug_print();
            }
            if (this->pieces[2]) {
                cout << ", \"statements\": ";
                this->pieces[2]->debug_print();
            }
            if (this->pieces[3]) {
                cout << ", \"end_label\": ";
                this->pieces[3]->debug_print();
            }
            if (this->subprogram_kind != SUBPROGRAM_UNSPEC) {
                cout << ", \"end_kind\": \"";
                cout << subprogram_kinds[this->subprogram_kind];
                cout << "\"";
            }
            break;

        case PT_SUBTYPE_INDICATION_AMBIG_WTF:
            cout << ", \"fixup_needed\": ";
            this->pieces[0]->debug_print();
            break;

        case PT_ELEMENT_RESOLUTION_NEST:
            cout << ", \"inner\": ";
            this->pieces[0]->debug_print();
            break;

        case PT_USE_CLAUSE:
            cout << ", \"used_names\": ";
            this->pieces[0]->debug_print();
            break;

        case PT_ATTRIBUTE_SPECIFICATION:
            cout << ", \"designator\": ";
            this->pieces[0]->debug_print();
            cout << ", \"specification\": ";
            this->pieces[1]->debug_print();
            cout << ", \"expression\": ";
            this->pieces[2]->debug_print();
            break;

        case PT_ENTITY_SPECIFICATION:
            cout << ", \"name_list\": ";
            this->pieces[0]->debug_print();
            cout << ", \"entity_class\": ";
            this->pieces[1]->debug_print();
            break;

        case PT_ENTITY_CLASS:
            cout << ", \"entity_class\": \"";
            cout << entity_classes[this->entity_class];
            cout << "\"";
            break;

        case PT_ENTITY_DESIGNATOR:
            cout << ", \"tag\": ";
            this->pieces[0]->debug_print();
            if (this->pieces[1]) {
                cout << ", \"signature\": ";
                this->pieces[1]->debug_print();
            }
            break;

        case PT_GROUP_TEMPLATE_DECLARATION:
            cout << ", \"identifier\": ";
            this->pieces[0]->debug_print();
            cout << ", \"entity_class_entry_list\": ";
            this->pieces[1]->debug_print();
            break;

        case PT_ENTITY_CLASS_ENTRY:
            cout << ", \"designator\": ";
            this->pieces[0]->debug_print();
            cout << ", \"has_box\": ";
            cout << (this->boolean ? "true" : "false");
            break;

        case PT_GROUP_DECLARATION:
            cout << ", \"identifier\": ";
            this->pieces[0]->debug_print();
            cout << ", \"template\": ";
            this->pieces[1]->debug_print();
            cout << ", \"constituent\": ";
            this->pieces[2]->debug_print();
            break;

        case PT_PACKAGE_DECLARATION:
            cout << ", \"identifier\": ";
            this->pieces[0]->debug_print();
            if (this->pieces[1]) {
                cout << ", \"header\": ";
                this->pieces[1]->debug_print();
            }
            if (this->pieces[2]) {
                cout << ", \"declarations\": ";
                this->pieces[2]->debug_print();
            }
            if (this->pieces[3]) {
                cout << ", \"end_label\": ";
                this->pieces[3]->debug_print();
            }
            break;

        case PT_SIGNAL_DECLARATION:
            cout << ", \"identifiers\": ";
            this->pieces[0]->debug_print();
            cout << ", \"subtype\": ";
            this->pieces[1]->debug_print();
            if (this->pieces[2]) {
                cout << ", \"kind\": ";
                this->pieces[2]->debug_print();
            }
            if (this->pieces[3]) {
                cout << ", \"expression\": ";
                this->pieces[3]->debug_print();
            }
            break;

        case PT_SIGNAL_KIND:
            if (this->signal_kind != SIGKIND_UNSPEC) {
                cout << ", \"kind\": \"";
                cout << signal_kinds[this->signal_kind];
                cout << "\"";
            }
            break;

        case PT_PACKAGE_BODY:
            cout << ", \"identifier\": ";
            this->pieces[0]->debug_print();
            if (this->pieces[1]) {
                cout << ", \"declarations\": ";
                this->pieces[1]->debug_print();
            }
            if (this->pieces[2]) {
                cout << ", \"end_label\": ";
                this->pieces[2]->debug_print();
            }
            break;

        case PT_PACKAGE_INSTANTIATION_DECLARATION:
            cout << ", \"identifier\": ";
            this->pieces[0]->debug_print();
            cout << ", \"uninstantiated_name\": ";
            this->pieces[1]->debug_print();
            if (this->pieces[2]) {
                cout << ", \"generic_map\": ";
                this->pieces[2]->debug_print();
            }
            break;

        case PT_INTERFACE_PACKAGE_DECLARATION:
            cout << ", \"identifier\": ";
            this->pieces[0]->debug_print();
            cout << ", \"uninstantiated_name\": ";
            this->pieces[1]->debug_print();
            cout << ", \"generic_map\": ";
            this->pieces[2]->debug_print();
            break;

        case PT_PROTECTED_TYPE_DECLARATION:
        case PT_PROTECTED_TYPE_BODY:
            if (this->pieces[0]) {
                cout << ", \"declarations\": ";
                this->pieces[0]->debug_print();
            }
            if (this->pieces[1]) {
                cout << ", \"end_label\": ";
                this->pieces[1]->debug_print();
            }
            break;

        case PT_COMPONENT_DECLARATION:
            cout << ", \"identifier\": ";
            this->pieces[0]->debug_print();
            if (this->pieces[1]) {
                cout << ", \"generic\": ";
                this->pieces[1]->debug_print();
            }
            if (this->pieces[2]) {
                cout << ", \"port\": ";
                this->pieces[2]->debug_print();
            }
            if (this->pieces[3]) {
                cout << ", \"end_label\": ";
                this->pieces[3]->debug_print();
            }
            break;

        case PT_DISCONNECTION_SPECIFICATION:
            cout << ", \"signal_specification\": ";
            this->pieces[0]->debug_print();
            cout << ", \"time\": ";
            this->pieces[1]->debug_print();
            break;

        case PT_GUARDED_SIGNAL_SPECIFICATION:
            cout << ", \"signal_list\": ";
            this->pieces[0]->debug_print();
            cout << ", \"type_mark\": ";
            this->pieces[1]->debug_print();
            break;

        case PT_CONCURRENT_PROCEDURE_CALL:
        case PT_CONCURRENT_ASSERTION_STATEMENT:
            cout << ", \"inner\": ";
            this->pieces[0]->debug_print();
            if (this->pieces[1]) {
                cout << ", \"label\": ";
                this->pieces[1]->debug_print();
            }
            cout << ", \"postponed\": ";
            cout << (this->boolean ? "true" : "false");
            break;

        case PT_COMPONENT_INSTANTIATION:
            cout << ", \"label\": ";
            this->pieces[0]->debug_print();
            cout << ", \"instantiated_unit\": ";
            this->pieces[1]->debug_print();
            if (this->pieces[2]) {
                cout << ", \"generic_map\": ";
                this->pieces[2]->debug_print();
            }
            if (this->pieces[3]) {
                cout << ", \"port_map\": ";
                this->pieces[3]->debug_print();
            }
            break;

        case PT_INSTANTIATED_UNIT_ENTITY:
            if (this->pieces[1]) {
                cout << ", \"architecture\": ";
                this->pieces[1]->debug_print();
            }
        case PT_INSTANTIATED_UNIT_COMPONENT:
        case PT_INSTANTIATED_UNIT_CONFIGURATION:
            cout << ", \"name\": ";
            this->pieces[0]->debug_print();
            break;

        case PT_CONCURRENT_SELECTED_SIGNAL_ASSIGNMENT:
            cout << ", \"select_expression\": ";
            this->pieces[4]->debug_print();
            cout << ", \"matching\": ";
            cout << (this->boolean3 ? "true" : "false");
        case PT_CONCURRENT_SIMPLE_SIGNAL_ASSIGNMENT:
        case PT_CONCURRENT_CONDITIONAL_SIGNAL_ASSIGNMENT:
            cout << ", \"target\": ";
            this->pieces[0]->debug_print();
            cout << ", \"waveform\": ";
            this->pieces[1]->debug_print();
            if (this->pieces[2]) {
                cout << ", \"delay\": ";
                this->pieces[2]->debug_print();
            }
            if (this->pieces[3]) {
                cout << ", \"label\": ";
                this->pieces[3]->debug_print();
            }
            cout << ", \"postponed\": ";
            cout << (this->boolean ? "true" : "false");
            cout << ", \"guarded\": ";
            cout << (this->boolean2 ? "true" : "false");
            break;

        case PT_BLOCK:
            cout << ", \"label\": ";
            this->pieces[0]->debug_print();
            if (this->pieces[1]) {
                cout << ", \"header\": ";
                this->pieces[1]->debug_print();
            }
            if (this->pieces[2]) {
                cout << ", \"guard\": ";
                this->pieces[2]->debug_print();
            }
            if (this->pieces[3]) {
                cout << ", \"declarations\": ";
                this->pieces[3]->debug_print();
            }
            if (this->pieces[4]) {
                cout << ", \"statements\": ";
                this->pieces[4]->debug_print();
            }
            if (this->pieces[5]) {
                cout << ", \"end_label\": ";
                this->pieces[5]->debug_print();
            }
            break;

        case PT_BLOCK_HEADER:
            if (this->pieces[0]) {
                cout << ", \"generic\": ";
                this->pieces[0]->debug_print();
            }
            if (this->pieces[1]) {
                cout << ", \"generic_map\": ";
                this->pieces[1]->debug_print();
            }
            if (this->pieces[2]) {
                cout << ", \"port\": ";
                this->pieces[2]->debug_print();
            }
            if (this->pieces[3]) {
                cout << ", \"port_map\": ";
                this->pieces[3]->debug_print();
            }
            break;

        case PT_FOR_GENERATE:
            cout << ", \"label\": ";
            this->pieces[0]->debug_print();
            cout << ", \"parameter_specification\": ";
            this->pieces[1]->debug_print();
            cout << ", \"body\": ";
            this->pieces[2]->debug_print();
            if (this->pieces[3]) {
                cout << ", \"end_label\": ";
                this->pieces[3]->debug_print();
            }
            break;

        case PT_IF_GENERATE:
            cout << ", \"generate_label\": ";
            this->pieces[0]->debug_print();
            cout << ", \"condition\": ";
            this->pieces[1]->debug_print();
            cout << ", \"if_body\": ";
            this->pieces[2]->debug_print();
            if (this->pieces[3]) {
                cout << ", \"if_label\": ";
                this->pieces[3]->debug_print();
            }
            if (this->pieces[4]) {
                cout << ", \"elsif_arms\": ";
                this->pieces[4]->debug_print();
            }
            if (this->pieces[5]) {
                cout << ", \"else_body\": ";
                this->pieces[5]->debug_print();
            }
            if (this->pieces[6]) {
                cout << ", \"else_label\": ";
                this->pieces[6]->debug_print();
            }
            if (this->pieces[7]) {
                cout << ", \"end_label\": ";
                this->pieces[7]->debug_print();
            }
            break;

        case PT_CASE_GENERATE:
            cout << ", \"generate_label\": ";
            this->pieces[0]->debug_print();
            cout << ", \"expression\": ";
            this->pieces[1]->debug_print();
            cout << ", \"alternatives\": ";
            this->pieces[2]->debug_print();
            if (this->pieces[3]) {
                cout << ", \"end_label\": ";
                this->pieces[3]->debug_print();
            }
            break;

        case PT_GENERATE_BODY:
            if (this->pieces[0]) {
                cout << ", \"declarations\": ";
                this->pieces[0]->debug_print();
            }
            if (this->pieces[1]) {
                cout << ", \"statements\": ";
                this->pieces[1]->debug_print();
            }
            if (this->pieces[2]) {
                cout << ", \"end_label\": ";
                this->pieces[2]->debug_print();
            }
            break;

        case PT_IF_GENERATE_ELSIF:
            cout << ", \"condition\": ";
            this->pieces[0]->debug_print();
            cout << ", \"body\": ";
            this->pieces[1]->debug_print();
            if (this->pieces[2]) {
                cout << ", \"label\": ";
                this->pieces[2]->debug_print();
            }
            break;

        case PT_CASE_GENERATE_ALTERNATIVE:
            cout << ", \"choices\": ";
            this->pieces[0]->debug_print();
            cout << ", \"body\": ";
            this->pieces[1]->debug_print();
            if (this->pieces[2]) {
                cout << ", \"label\": ";
                this->pieces[2]->debug_print();
            }
            break;

        case PT_SIMPLE_CONFIGURATION_SPECIFICATION:
            cout << ", \"component\": ";
            this->pieces[0]->debug_print();
            cout << ", \"binding\": ";
            this->pieces[1]->debug_print();
            break;

        case PT_COMPONENT_SPECIFICATION:
            cout << ", \"instantiation_list\": ";
            this->pieces[0]->debug_print();
            cout << ", \"name\": ";
            this->pieces[1]->debug_print();
            break;

        case PT_BINDING_INDICATION:
            if (this->pieces[0]) {
                cout << ", \"entity_aspect\": ";
                this->pieces[0]->debug_print();
            }
            if (this->pieces[1]) {
                cout << ", \"generic_map\": ";
                this->pieces[1]->debug_print();
            }
            if (this->pieces[2]) {
                cout << ", \"port_map\": ";
                this->pieces[2]->debug_print();
            }
            break;

        case PT_ENTITY_ASPECT_ENTITY:
            cout << ", \"name\": ";
            this->pieces[0]->debug_print();
            if (this->pieces[1]) {
                cout << ", \"architecture\": ";
                this->pieces[1]->debug_print();
            }
            break;

        case PT_ENTITY_ASPECT_CONFIGURATION:
            cout << ", \"configuration\": ";
            this->pieces[0]->debug_print();
            break;

        case PT_VERIFICATION_UNIT_BINDING_INDICATION:
            cout << ", \"vunits\": ";
            this->pieces[0]->debug_print();
            break;

        case PT_COMPOUND_CONFIGURATION_SPECIFICATION:
            cout << ", \"component\": ";
            this->pieces[0]->debug_print();
            cout << ", \"binding\": ";
            this->pieces[1]->debug_print();
            cout << ", \"vunits\": ";
            this->pieces[2]->debug_print();
            break;

        case PT_ENTITY:
            cout << ", \"identifier\": ";
            this->pieces[0]->debug_print();
            if (this->pieces[1]) {
                cout << ", \"header\": ";
                this->pieces[1]->debug_print();
            }
            if (this->pieces[2]) {
                cout << ", \"declarations\": ";
                this->pieces[2]->debug_print();
            }
            if (this->pieces[3]) {
                cout << ", \"statements\": ";
                this->pieces[3]->debug_print();
            }
            if (this->pieces[4]) {
                cout << ", \"end_label\": ";
                this->pieces[4]->debug_print();
            }
            break;

        case PT_ENTITY_HEADER:
            if (this->pieces[0]) {
                cout << ", \"generic\": ";
                this->pieces[0]->debug_print();
            }
            if (this->pieces[1]) {
                cout << ", \"port\": ";
                this->pieces[1]->debug_print();
            }
            break;

        case PT_CONTEXT_DECLARATION:
            cout << ", \"identifier\": ";
            this->pieces[0]->debug_print();
            if (this->pieces[1]) {
                cout << ", \"context\": ";
                this->pieces[1]->debug_print();
            }
            if (this->pieces[2]) {
                cout << ", \"end_label\": ";
                this->pieces[2]->debug_print();
            }
            break;

        case PT_LIBRARY_CLAUSE:
            cout << ", \"names\": ";
            this->pieces[0]->debug_print();
            break;
            
        case PT_CONTEXT_REFERENCE:
            cout << ", \"names\": ";
            this->pieces[0]->debug_print();
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
        case PT_ELEMENT_DECLARATION_LIST:
        case PT_ID_LIST_REAL:
        case PT_DECLARATION_LIST:
        case PT_INTERFACE_LIST:
        case PT_ASSOCIATION_LIST:
        case PT_SELECTED_NAME_LIST:
        case PT_ENTITY_NAME_LIST:
        case PT_ENTITY_CLASS_ENTRY_LIST:
        case PT_SEQUENCE_OF_CONCURRENT_STATEMENTS:
        case PT_IF_GENERATE_ELSIF_LIST:
        case PT_CASE_GENERATE_ALTERNATIVE_LIST:
        case PT_VERIFICATION_UNIT_BINDING_INDICATION_LIST:
        case PT_CONTEXT_CLAUSE:
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
