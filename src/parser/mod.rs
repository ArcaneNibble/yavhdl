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

mod ffi {
#![allow(dead_code)]
#![allow(non_camel_case_types)]

include!(concat!(env!("OUT_DIR"), "/bindings.rs"));
}

use std::ptr;
use std::ffi::{CStr, CString};
use std::ffi::OsStr;
use std::os::unix::ffi::OsStrExt;
use std::os::raw::*;

pub use self::ffi::ParseTreeNodeType;
pub use self::ffi::ParseTreeOperatorType;
pub use self::ffi::ParseTreeRangeDirection;
pub use self::ffi::ParseTreeForceMode;
pub use self::ffi::ParseTreeFunctionPurity;
pub use self::ffi::ParseTreeInterfaceObjectMode;
pub use self::ffi::ParseTreeSubprogramKind;
pub use self::ffi::ParseTreeEntityClass;
pub use self::ffi::ParseTreeSignalKind;

// FIXME: Copypasta problems?
pub struct VhdlParseTreeNode {
    pub node_type: ParseTreeNodeType,
    pub str1: Vec<u8>,
    pub str2: Vec<u8>,
    pub chr: u8,
    pub integer: i32,
    pub boolean: bool,
    pub boolean2: bool,
    pub boolean3: bool,
    pub pieces: Vec<VhdlParseTreeNode>,
    pub op_type: ParseTreeOperatorType,
    pub range_dir: ParseTreeRangeDirection,
    pub force_mode: ParseTreeForceMode,
    pub purity: ParseTreeFunctionPurity,
    pub interface_mode: ParseTreeInterfaceObjectMode,
    pub subprogram_kind: ParseTreeSubprogramKind,
    pub entity_class: ParseTreeEntityClass,
    pub signal_kind: ParseTreeSignalKind,
    pub first_line: i32,
    pub first_column: i32,
    pub last_line: i32,
    pub last_column: i32,

    raw_node: *mut ffi::VhdlParseTreeNode,
    // We only want to call free on the root
    is_root: bool,
}

unsafe fn rustify_str(input: *mut c_char) -> String {
    // Get the string into something Rust can handle
    let string_rs = CStr::from_ptr(input);
    let string_rs = String::from(string_rs.to_str().unwrap());
    // Free the C string
    ffi::VhdlParserFreeString(input);

    string_rs
}

unsafe fn rustify_stdstring(input: *mut c_void) -> Vec<u8> {
    if input.is_null() {
        return vec![];
    }

    let null_terminated_string = ffi::VhdlParserCifyString(input);
    let string_rs = CStr::from_ptr(null_terminated_string);
    let string_rs = string_rs.to_bytes().to_vec();
    // Free the C string
    ffi::VhdlParserFreeString(null_terminated_string);

    string_rs
}

unsafe fn rustify_node(
    input: *mut ffi::VhdlParseTreeNode, is_root: bool) -> VhdlParseTreeNode {

    let str1 = rustify_stdstring((*input).str);
    let str2 = rustify_stdstring((*input).str2);

    let mut inner_nodes = Vec::with_capacity(ffi::NUM_FIXED_PIECES as usize);
    // Recursively convert inner nodes first
    for i in 0..ffi::NUM_FIXED_PIECES {
        let this_child = (*input).pieces[i as usize];
        if this_child.is_null() {
            break;
        }
        inner_nodes.push(rustify_node(this_child, false));
    }

    VhdlParseTreeNode {
        node_type: (*input).type_,
        chr: (*input).chr as u8,
        integer: (*input).integer,
        boolean: (*input).boolean,
        boolean2: (*input).boolean2,
        boolean3: (*input).boolean3,
        op_type: (*input).op_type,
        range_dir: (*input).range_dir,
        force_mode: (*input).force_mode,
        purity: (*input).purity,
        interface_mode: (*input).interface_mode,
        subprogram_kind: (*input).subprogram_kind,
        entity_class: (*input).entity_class,
        signal_kind: (*input).signal_kind,
        first_line: (*input).first_line,
        first_column: (*input).first_column,
        last_line: (*input).last_line,
        last_column: (*input).last_column,

        str1: str1,
        str2: str2,

        pieces: inner_nodes,

        raw_node: input,
        is_root: is_root,
    }
}

pub fn parse_file(filename: &OsStr) -> (Option<VhdlParseTreeNode>, String) {
    unsafe {
        let mut errors = ptr::null_mut::<c_char>();
        let ret = ffi::VhdlParserParseFile(
            CString::new(filename.as_bytes()).unwrap().as_ptr() as *const i8,
            &mut errors);

        let errors_rs = rustify_str(errors);

        if ret.is_null() {
            (None, errors_rs)
        } else {
            // Need to Rust-ify the struct
            (Some(rustify_node(ret, true)), errors_rs)
        }
    }
}

impl Drop for VhdlParseTreeNode {
    fn drop(&mut self) {
        unsafe {
            if self.is_root {
                ffi::VhdlParserFreePT(self.raw_node);
            }
        }
    }
}

impl VhdlParseTreeNode {
    pub fn debug_print(&self) {
        unsafe {
            ffi::VhdlParseTreeNodeDebugPrint(self.raw_node);
        }
    }
}
