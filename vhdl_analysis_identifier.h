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

#ifndef VHDL_ANALYSIS_IDENTIFIER_H
#define VHDL_ANALYSIS_IDENTIFIER_H

#include <string>

namespace YaVHDL::Analyser
{

class Identifier {
public:
    // Original Latin-1 name, no changes made
    std::string orig_name;
    // Lowercased name in the case of basic identifiers, otherwise the same
    // as orig_name
    std::string canonical_name;
    // Pretty name suitable for printing. UTF-8
    std::string pretty_name;
    bool is_extended_id;

    static Identifier *FromLatin1(const char *name, bool is_extended_id);
    static Identifier *FromUTF8(const char *name, bool is_extended_id);

    bool operator==(const Identifier &other) const;
    bool operator!=(const Identifier &other) const;

private:
    Identifier();
    static Identifier *_IdentifierInternalCreate(
        std::string name, bool is_extended_id);
};

}

#endif
