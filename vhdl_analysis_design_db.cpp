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

#include "vhdl_analysis_design_db.h"

#include <iostream>
using namespace YaVHDL::Analyser;

void DesignDatabase::PopulateBuiltins() {
    // TODO
}

void DesignDatabase::debug_print() {
    std::cout << "I'm a design database!\n";
}

#ifdef VHDL_ANALYSIS_DEMO_MODE

#include "vhdl_parser_glue.h"
using namespace std;
using namespace YaVHDL::Parser;

int main(int argc, char **argv) {
    if (argc < 3) {
        cout << "Usage: " << argv[0] << " work_lib_name ";
        cout << "file1.vhd, file2.vhd, ...\n";
        return -1;
    }

    DesignDatabase *db = new DesignDatabase();
    db->PopulateBuiltins();
    std::string errors = std::string();

    // Parse each file
    for (int i = 2; i < argc; i++) {
        cout << "Parsing file \"" << argv[i] << "\"...\n";
        VhdlParseTreeNode *pt = VhdlParserParseFile(argv[i], errors);
        if (pt) {

        } else {
            cout << errors;
            break;
        }
    }

    db->debug_print();
    delete db;
}

#endif
