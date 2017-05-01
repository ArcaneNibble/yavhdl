mod ffi {
#![allow(dead_code)]
#![allow(non_camel_case_types)]

include!(concat!(env!("OUT_DIR"), "/bindings.rs"));
}

use std::ptr;
use std::ffi::CStr;
use std::ffi::OsStr;
use std::os::unix::ffi::OsStrExt;
use std::os::raw::*;

pub use self::ffi::ParseTreeNodeType as ParseTreeNodeType;
pub use self::ffi::ParseTreeOperatorType as ParseTreeOperatorType;
pub use self::ffi::ParseTreeRangeDirection as ParseTreeRangeDirection;
pub use self::ffi::ParseTreeForceMode as ParseTreeForceMode;
pub use self::ffi::ParseTreeFunctionPurity as ParseTreeFunctionPurity;
pub use self::ffi::ParseTreeInterfaceObjectMode as ParseTreeInterfaceObjectMode;
pub use self::ffi::ParseTreeSubprogramKind as ParseTreeSubprogramKind;
pub use self::ffi::ParseTreeEntityClass as ParseTreeEntityClass;
pub use self::ffi::ParseTreeSignalKind as ParseTreeSignalKind;

// FIXME: Copypasta problems?
pub struct VhdlParseTreeNode {
    pub node_type: ParseTreeNodeType,
    pub str1: String,
    pub str2: String,
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

    raw_node: *mut ffi::VhdlParseTreeNode
}

unsafe fn rustify_str(input: *mut c_char) -> String {
    // Get the string into something Rust can handle
    let string_rs = CStr::from_ptr(input);
    let string_rs = String::from(string_rs.to_str().unwrap());
    // Free the C string
    ffi::VhdlParserFreeString(input);

    string_rs
}

unsafe fn rustify_stdstring(input: *mut c_void) -> String {
    let null_terminated_string = ffi::VhdlParserCifyString(input);
    rustify_str(null_terminated_string)
}

unsafe fn rustify_node(
    input: *mut ffi::VhdlParseTreeNode) -> VhdlParseTreeNode {

    let str1 = rustify_stdstring((*input).str);
    let str2 = rustify_stdstring((*input).str2);

    let mut inner_nodes = Vec::with_capacity(ffi::NUM_FIXED_PIECES as usize);
    // Recursively convert inner nodes first
    for i in 0..ffi::NUM_FIXED_PIECES {
        let this_child = (*input).pieces[i as usize];
        if this_child.is_null() {
            break;
        }
        inner_nodes.push(rustify_node(this_child));
    }

    let ret = VhdlParseTreeNode {
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
    };

    ret
}

pub fn parse_file(filename: &OsStr) -> (Option<VhdlParseTreeNode>, String) {
    unsafe {
        let mut errors: *mut c_char = ptr::null_mut::<c_char>();
        let ret = ffi::VhdlParserParseFile(
            filename.as_bytes().as_ptr() as *const i8,
            &mut errors);

        let errors_rs = rustify_str(errors);

        if ret.is_null() {
            (None, errors_rs)
        } else {
            // Need to Rust-ify the struct
            (Some(rustify_node(ret)), errors_rs)
        }
    }
}

impl Drop for VhdlParseTreeNode {
    fn drop(&mut self) {
        unsafe {
            ffi::VhdlParserFreePT(self.raw_node);
        }
    }
}

impl VhdlParseTreeNode {
    pub fn debug_print(&self) {
        unsafe {
            // FIXME: This isn't a C function, does it matter?
            ffi::VhdlParseTreeNode_debug_print(self.raw_node);
        }
    }
}
