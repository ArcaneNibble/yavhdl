/*
Copyright (c) 2016-2017, Robert Ou <rqou@robertou.com>
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
   this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#include "vhdl_analysis_identifier.h"

#include <codecvt>
#include <cstring>
#include <locale>
#include <string>
#include "util.h"
using namespace std;
using namespace YaVHDL::Analyser;
using namespace YaVHDL::Util;

Identifier::Identifier() {
}

Identifier *Identifier::_IdentifierInternalCreate(
    string name, bool is_extended_id) {

    // Validation
    size_t l = name.length();
    if (!is_extended_id) {
        for (size_t i = 0; i < l; i++) {
            if (!is_valid_for_basic_id(name[i])) return nullptr;
        }

        if (!is_valid_basic_id(name.c_str())) return nullptr;
    } else {
        for (size_t i = 0; i < l; i++) {
            if (!is_valid_for_ext_id(name[i])) return nullptr;
        }
    }

    Identifier *ret = new Identifier();

    ret->is_extended_id = is_extended_id;

    ret->orig_name = name;

    // Lower-case basic identifiers
    ret->canonical_name = name;
    if (!is_extended_id) {
        for (size_t i = 0; i < l; i++) {
            ret->canonical_name[i] =
                latin1_lcase_table[(unsigned char)ret->canonical_name[i]];
        }
    }

    // Pretty-printing UTF-8 lookup table
    ret->pretty_name = std::string();
    for (size_t i = 0; i < l; i++) {
        ret->pretty_name +=
            latin1_prettyprint_table[(unsigned char)ret->orig_name[i]];
    }

    return ret;
}

Identifier *Identifier::FromLatin1(const char *name, bool is_extended_id) {
    return _IdentifierInternalCreate(std::string(name), is_extended_id);
}

Identifier *Identifier::FromUTF8(const char *name, bool is_extended_id) {
    std::wstring_convert<std::codecvt_utf8<char32_t>, char32_t> converter;
    u32string conv_str;
    try {
        conv_str = converter.from_bytes(name);
    } catch (range_error &e) {
        return nullptr;
    }

    // Reject non-latin1
    for (size_t i = 0; i < conv_str.length(); i++) {
        if (conv_str[i] >= 0x100) return nullptr;
    }

    // Coerce to a byte string
    string byte_str(conv_str.length(), '\0');
    for (size_t i = 0; i < conv_str.length(); i++) {
        byte_str[i] = (char)conv_str[i];
    }

    return _IdentifierInternalCreate(byte_str, is_extended_id);
}

bool Identifier::operator==(const Identifier &other) const {
    if (this->is_extended_id != other.is_extended_id) return false;

    return this->canonical_name == other.canonical_name;
}

bool Identifier::operator!=(const Identifier &other) const {
    return !(*this == other);
}

size_t hash<YaVHDL::Analyser::Identifier>::operator()(YaVHDL::Analyser::Identifier value) const {
    size_t ret = hash<string>()(value.canonical_name);

    if (value.is_extended_id) {
        ret ^= 1;
    }

    return ret;
}
