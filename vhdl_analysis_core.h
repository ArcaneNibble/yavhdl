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

#ifndef VHDL_ANALYSIS_CORE
#define VHDL_ANALYSIS_CORE

#include <string>
#include "vhdl_analysis_design_db.h"
#include "vhdl_analysis_library.h"
#include "vhdl_parser_glue.h"

// The core of the analysis code. This analyses the parse output of a single
// design file (stored in pt) into the design library work_lib. The design
// library work_lib must have already been added to the design database,
// design_db. design_db contains "everything" that possibly exists in the
// VHDL design, including all libraries. Errors are reported in the "errors"
// variable and warnings are reported in the "warnings" variable. This
// function returns true iff there were no errors.
bool do_vhdl_analysis(
    YaVHDL::Analyser::DesignDatabase *design_db,
    YaVHDL::Analyser::Library *work_lib,
    YaVHDL::Parser::VhdlParseTreeNode *pt,
    std::string &errors,
    std::string &warnings);

#endif
