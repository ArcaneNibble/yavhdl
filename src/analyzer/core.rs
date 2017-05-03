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

use analyzer::ast::*;
use analyzer::design::*;
use analyzer::identifier::*;
use analyzer::objpools::*;

use parser::*;

use std::ffi::OsStr;

pub struct AnalyzerCoreStateBlob {
    ///// This stuff is global

    // Object pools
    pub sp: StringPool,
    pub op_n: ObjPool<AstNode>,
    pub op_s: ObjPool<ScopeChainNode>,
    pub op_l: ObjPool<Library>,

    pub design_db: DesignDatabase,
    pub errors: String,
    pub warnings: String,

    ///// This stuff is local to some part of the parsing step
    work_lib: Option<ObjPoolIndex<Library>>,
    current_file_name: Option<StringPoolIndexOsStr>,
    innermost_scope: Option<ObjPoolIndex<ScopeChainNode>>,
}

impl AnalyzerCoreStateBlob {
    pub fn new() -> AnalyzerCoreStateBlob {
        AnalyzerCoreStateBlob {
            sp: StringPool::new(),
            op_n: ObjPool::new(),
            op_s: ObjPool::new(),
            op_l: ObjPool::new(),
            design_db: DesignDatabase::new(),
            errors: String::new(),
            warnings: String::new(),

            work_lib: None,
            current_file_name: None,
            innermost_scope: None,
        }
    }
}


fn dump_current_location(s: &mut AnalyzerCoreStateBlob, pt: &VhdlParseTreeNode,
    is_err: bool) {

    let o = if is_err { &mut s.errors } else { &mut s.warnings };

    *o += &format!("{}:",
        s.sp.retrieve_osstr(s.current_file_name.unwrap()).to_string_lossy());
    if pt.first_line != -1 {
        *o += &format!("{}:{}:", pt.first_line, pt.first_column);
    }
}

fn pt_loc(s: &AnalyzerCoreStateBlob, pt: &VhdlParseTreeNode) -> SourceLoc {
    SourceLoc {
        first_line: pt.first_line,
        first_column: pt.first_column,
        last_line: pt.last_line,
        last_column: pt.last_column,
        file_name: s.current_file_name,
    }
}

// XXX FIXME: We .unwrap() all identifiers because the parser already rejects
// invalid ones. This is a somewhat ugly duplication of effort.
fn analyze_identifier(s: &mut AnalyzerCoreStateBlob, pt: &VhdlParseTreeNode)
    -> Identifier {

    match pt.node_type {
        ParseTreeNodeType::PT_BASIC_ID => {
            let sp_idx = s.sp.add_latin1_str(&pt.str1);
            Identifier::new_latin1(&mut s.sp, sp_idx, false).unwrap()
        },
        ParseTreeNodeType::PT_EXT_ID => {
            let sp_idx = s.sp.add_latin1_str(&pt.str1);
            Identifier::new_latin1(&mut s.sp, sp_idx, true).unwrap()
        },
        _ => panic!("Don't know how to handle this parse tree node!")
    }
}

fn analyze_entity(s: &mut AnalyzerCoreStateBlob, pt: &VhdlParseTreeNode)
    -> bool {

    let e_ = s.op_n.alloc();

    // Location information
    let loc = pt_loc(s, pt);

    // Our name
    let id = analyze_identifier(s, &pt.pieces[0].as_ref().unwrap());

    // Check for duplicate entity
    let old_node_idx = s.op_l.get(s.work_lib.unwrap()).find_design_unit(id);
    if old_node_idx.is_some() {
        dump_current_location(s, pt, true);
        s.errors += &format!(
            "ERROR: Design unit {} already exists in library!\n",
            s.sp.retrieve_latin1_str(id.orig_name).pretty_name());

        let old_node = s.op_n.get(old_node_idx.unwrap());
        if let Some(old_loc) = old_node.loc() {
            s.errors += &format!("\tPrevious version was at {}\n",
                old_loc.format_for_error(&s.sp));
        }

        return false;
    }

    {
        let e = s.op_n.get_mut(e_);
        *e = AstNode::Entity {
            loc: loc,
            id: id,
            scope: Scope::new(),
            // Store the given root declarative region
            root_decl_region: s.innermost_scope.unwrap(),
        };
    }

    s.op_l.get_mut(s.work_lib.unwrap()).tentative_add_design_unit(id, e_);

    // Verify that the id at the end (if any) is the same as the one in the
    // beginning
    if let Some(tail_id_pt) = pt.pieces[4].as_ref() {
        let tail_id = analyze_identifier(s, tail_id_pt);
        if tail_id != id {
            dump_current_location(s, pt, true);
            s.errors +=
                "ERROR: Name at end of entity must match name at beginning\n";
            s.op_l.get_mut(s.work_lib.unwrap()).drop_tentative_design_unit();
            return false;
        }
    }

    // TODO

    // Declarations
    if let Some(decl_pt) = pt.pieces[2].as_ref() {
        let e = s.op_n.get_mut(e_);

        // TODO
    }

    // Add the thing we analyzed to the library for real
    s.op_l.get_mut(s.work_lib.unwrap()).commit_tentative_design_unit();

    true
}

// Analyzes PT_DESIGN_UNIT
fn analyze_design_unit(s: &mut AnalyzerCoreStateBlob, pt: &VhdlParseTreeNode)
    -> bool {

    let mut no_errors = true;
    
    // Root declarative region
    let root_decl_region = s.op_s.alloc();
    s.innermost_scope = Some(root_decl_region);

    // Not implemented
    assert!(pt.pieces[1].is_none());

    match pt.pieces[0].as_ref().unwrap().node_type {
        ParseTreeNodeType::PT_ENTITY => {
            no_errors &= analyze_entity(s, &pt.pieces[0].as_ref().unwrap());
        },
        _ => panic!("Don't know how to handle this parse tree node!")
    };

    no_errors
}


// Analyzes PT_DESIGN_FILE or PT_DESIGN_UNIT
fn analyze_design_file(s: &mut AnalyzerCoreStateBlob, pt: &VhdlParseTreeNode)
    -> bool {

    let mut no_errors = true;

    match pt.node_type {
        ParseTreeNodeType::PT_DESIGN_UNIT => {
            no_errors &= analyze_design_unit(s, pt);
        },
        ParseTreeNodeType::PT_DESIGN_FILE => {
            no_errors &= analyze_design_file(
                s, &pt.pieces[0].as_ref().unwrap());
            no_errors &= analyze_design_unit(
                s, &pt.pieces[1].as_ref().unwrap());
        },
        _ => panic!("Don't know how to handle this parse tree node!")
    };

    no_errors
}

// The core of the analysis code. This analyses the parse output of a single
// design file (stored in pt) into the design library work_lib. The design
// library work_lib must have already been added to the design database,
// design_db. design_db contains "everything" that possibly exists in the
// VHDL design, including all libraries. Errors are reported in the "errors"
// variable and warnings are reported in the "warnings" variable. This
// function returns true iff there were no errors.
pub fn vhdl_analyze_file(s: &mut AnalyzerCoreStateBlob, pt: &VhdlParseTreeNode,
    work_lib: ObjPoolIndex<Library>, file_name: &OsStr) -> bool {

    let fn_str_idx = s.sp.add_osstr(file_name);
    s.work_lib = Some(work_lib);
    s.current_file_name = Some(fn_str_idx);
    s.innermost_scope = None;

    analyze_design_file(s, pt)
}

#[cfg(test)]
mod tests {

}
