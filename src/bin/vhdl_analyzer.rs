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

use std::env;
use std::os::unix::ffi::OsStrExt;
use std::process;

extern crate yavhdl;
use yavhdl::analyzer::*;
use yavhdl::parser;

fn main() {
    let args: Vec<_> = env::args_os().collect();
    if args.len() < 3 {
        println!("Usage: {} [-e] work_lib_name file1.vhd, file2.vhd, ...",
            args[0].to_string_lossy());
        process::exit(-1);
    }

    // Construct the state blob
    let mut s = AnalyzerCoreStateBlob::new();

    // Parse the given identifier
    let lib_was_ext_id = &args[1] == "-e";
    let lib_name = if lib_was_ext_id {
        &args[2]
    } else {
        &args[1]
    };

    // If the name parses as UTF-8, treat it as such. Otherwise treat it as
    // Latin-1
    let lib_id = match lib_name.to_str() {
        Some(name_unicode) =>
            Identifier::new_unicode(&mut s.sp, name_unicode, lib_was_ext_id),
        None => {
            let sp_idx = s.sp.add_latin1_str(lib_name.as_bytes());
            Identifier::new_latin1(&mut s.sp, sp_idx, lib_was_ext_id)
        }
    }.unwrap();

    // Create design database (ultimate container for everything)
    s.design_db.populate_builtins();

    // Create the library
    let work_lib_idx = s.op_l.alloc();
    {
        let work_lib = s.op_l.get_mut(work_lib_idx);
        *work_lib = Library::new(lib_id);
    }
    s.design_db.add_library(lib_id, work_lib_idx);

    // Parse each file
    for i in (if lib_was_ext_id {3} else {2})..args.len() {
        println!("Parsing file \"{}\"...", args[i].to_string_lossy());
        let (parse_output, parse_messages) = parser::parse_file(&args[i]);
        if let Some(pt) = parse_output {
            println!("Analyzing file \"{}\"...", args[i].to_string_lossy());
            s.errors.clear();
            s.warnings.clear();
            let ret = vhdl_analyze_file(&mut s, &pt, work_lib_idx, &args[i]);
            print!("{}", s.warnings);
            if !ret {
                // An error occurred
                println!("ERRORS occurred during analysis!");
                print!("{}", s.errors);
            }
        } else {
            print!("{}", parse_messages);
        }
    }

    println!("{}", s.design_db.debug_print(&s.sp, &s.op_l, &s.op_n, &s.op_s));
}
