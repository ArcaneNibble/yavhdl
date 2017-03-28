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

#include <cstring>
#include <iostream>

#include "vhdl_analysis_core.h"
#include "vhdl_analysis_design_db.h"
#include "vhdl_parser_glue.h"

using namespace std;
using namespace YaVHDL::Analyser;
using namespace YaVHDL::Parser;

int main(int argc, char **argv) {
    if (argc < 3) {
        cout << "Usage: " << argv[0] << " [-e] work_lib_name ";
        cout << "file1.vhd, file2.vhd, ...\n";
        return -1;
    }

    // Parse the given identifier
    Identifier *lib_id;
    bool lib_was_ext_id = false;
    if (strcmp(argv[1], "-e") == 0) {
        lib_was_ext_id = true;
        lib_id = Identifier::FromUTF8(argv[2], true);
    } else {
        lib_id = Identifier::FromUTF8(argv[1], false);
    }

    if (!lib_id) {
        cout << "Bad library identifier!\n";
        return 1;
    }

    // Create design database (ultimate container for everything)
    DesignDatabase *db = new DesignDatabase();
    db->PopulateBuiltins();

    // Create the library
    Library *work_lib = new Library();
    work_lib->id = lib_id;
    db->AddLibrary(work_lib);

    // Parse each file
    std::string errors = std::string();
    std::string warnings = std::string();
    for (int i = lib_was_ext_id ? 3 : 2; i < argc; i++) {
        cout << "Parsing file \"" << argv[i] << "\"...\n";
        VhdlParseTreeNode *pt = VhdlParserParseFile(argv[i], errors);
        if (pt) {
            cout << "Analysing file \"" << argv[i] << "\"...\n";
            errors.clear();
            warnings.clear();
            bool ret = do_vhdl_analysis(
                db, work_lib, pt, errors, warnings, argv[i]);
            cout << warnings;
            if (!ret) {
                // An error occurred
                cout << "ERRORS occurred during analysis!\n";
                cout << errors;
            }
            delete pt;
        } else {
            cout << errors;
            break;
        }
    }

    db->debug_print();
    cout << "\n";
    delete db;

    return 0;
}
