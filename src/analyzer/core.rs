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
use analyzer::util::*;

use parser::*;

use std::collections::HashSet;
use std::ffi::OsStr;

pub struct AnalyzerCoreStateBlob {
    ///// This stuff is global

    // Object pools
    pub sp: StringPool,
    pub op_n: ObjPool<AstNode>,
    pub op_s: ObjPool<Scope>,
    pub op_sc: ObjPool<ScopeChainNode>,
    pub op_l: ObjPool<Library>,

    pub design_db: DesignDatabase,
    pub errors: String,
    pub warnings: String,

    ///// This stuff is local to some part of the parsing step
    internal_name_count: u64,
    work_lib: Option<ObjPoolIndex<Library>>,
    current_file_name: Option<StringPoolIndexOsStr>,
    innermost_scope: Option<ObjPoolIndex<ScopeChainNode>>,
    blacklisted_names: HashSet<ScopeItemName>,
}

impl AnalyzerCoreStateBlob {
    pub fn new() -> AnalyzerCoreStateBlob {
        AnalyzerCoreStateBlob {
            sp: StringPool::new(),
            op_n: ObjPool::new(),
            op_s: ObjPool::new(),
            op_sc: ObjPool::new(),
            op_l: ObjPool::new(),
            design_db: DesignDatabase::new(),
            errors: String::new(),
            warnings: String::new(),

            internal_name_count: 0,
            work_lib: None,
            current_file_name: None,
            innermost_scope: None,
            blacklisted_names: HashSet::new(),
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

#[derive(Eq)]
struct ParameterResultTypeProfile {
    result: Option<ObjPoolIndex<AstNode>>,
    params: Vec<ObjPoolIndex<AstNode>>,
}

impl PartialEq for ParameterResultTypeProfile {
    fn eq(&self, other: &ParameterResultTypeProfile) -> bool {
        // Compare arg count
        if self.params.len() != other.params.len() {
            return false;
        }

        // Compare args
        for i in 0..self.params.len() {
            if self.params[i] != other.params[i] {
                return false;
            }
        }

        // Compare return type
        if self.result != other.result {
            return false;
        }

        true
    }
}

fn get_parameter_result_type_profile(s: &AnalyzerCoreStateBlob,
    node_idx: ObjPoolIndex<AstNode>) -> ParameterResultTypeProfile {

    let node = s.op_n.get(node_idx);
    match node {
        &AstNode::EnumerationLitDecl {corresponding_type_decl, ..} => {
            // Treat this as a function that takes no arguments and returns the
            // type of the corresponding enum.

            // TODO: subtypes

            ParameterResultTypeProfile {
                result: Some(corresponding_type_decl),
                params: vec![],
            }
        }
        _ =>
            panic!("Don't know how to get parameter/result type profile here!")
    }
}

fn try_add_declaration(s: &mut AnalyzerCoreStateBlob, name: ScopeItemName,
    node: ObjPoolIndex<AstNode>, scope: ObjPoolIndex<Scope>) -> bool {

    // This seems to be needed because the borrow checker doesn't seem to
    // understand that the None case shouldn't need the borrow still.
    let has_existing = s.op_s.get(scope).get(name).is_some();
    if !has_existing {
        // We are adding a new thing; this should always work
        s.op_s.get_mut(scope).add(name, node);
        true
    } else {
        let found_conflict = {
            let existing = s.op_s.get(scope).get(name).unwrap();
            // Are the existing things overloadable? (Must always be the same)
            let existing_overloadable =
                s.op_n.get(existing[0]).is_an_overloadable_decl();

            let this_overloadable =
                s.op_n.get(node).is_an_overloadable_decl();

            // TODO: Implicit declarations?

            if !(existing_overloadable && this_overloadable) {
                // Definitely fail
                true
            } else {
                // Both are overloadable

                // Check the type profiles
                let typeprof_of_new =
                    get_parameter_result_type_profile(s, node);
                let mut found_conflict = false;
                for existing_i in existing {
                    let typeprof_of_existing =
                        get_parameter_result_type_profile(s, *existing_i);

                    if typeprof_of_new == typeprof_of_existing {
                        found_conflict = true;
                        break;
                    }
                }

                found_conflict
            }
        };

        if !found_conflict {
            s.op_s.get_mut(scope).add(name, node);
            true
        } else {
            false
        }
    }
}

fn analyze_enum_lit(s: &mut AnalyzerCoreStateBlob,
    lit_pt: &VhdlParseTreeNode, scope: ObjPoolIndex<Scope>, idx: &mut i64,
    e_: ObjPoolIndex<AstNode>, pt_for_loc: &VhdlParseTreeNode) -> bool {

    let lit = match lit_pt.node_type {
        ParseTreeNodeType::PT_LIT_CHAR =>
            EnumerationLiteral::CharLiteral(lit_pt.chr),
        _ => EnumerationLiteral::Identifier(analyze_identifier(
            s, lit_pt))
    };

    let x_ = s.op_n.alloc();
    {
        let x = s.op_n.get_mut(x_);
        *x = AstNode::EnumerationLitDecl {
            lit: lit,
            idx: *idx,
            corresponding_type_decl: e_,
        };
    }

    // Done setting up, try to add it
    if !try_add_declaration(s, lit.to_scope_item_name(), x_, scope) {
        dump_current_location(s, pt_for_loc, true);
        s.errors += &format!(
            "ERROR: Duplicate declaration of enum literal {}!\n",
            match lit {
                EnumerationLiteral::Identifier(id) =>
                    s.sp.retrieve_latin1_str(id.orig_name).pretty_name(),
                EnumerationLiteral::CharLiteral(c) =>
                    get_chr_escaped(c),
            });
        return false;
    }

    // Add it to the type decl as well
    {
        let e = s.op_n.get_mut(e_);
        match e {
            &mut AstNode::EnumerationTypeDecl{ref mut literals, ..} => {
                literals.push(x_);
            },
            _ => panic!("AST invariant violated!")
        }
    }

    true
}

fn analyze_enum_lits(s: &mut AnalyzerCoreStateBlob,
    lit_pt: &VhdlParseTreeNode, scope: ObjPoolIndex<Scope>, idx: &mut i64,
    e_: ObjPoolIndex<AstNode>, pt_for_loc: &VhdlParseTreeNode) -> bool {

    match lit_pt.node_type {
        ParseTreeNodeType::PT_ENUM_LITERAL_LIST => {
            if !analyze_enum_lits(s, &lit_pt.pieces[0].as_ref().unwrap(),
                                  scope, idx, e_, pt_for_loc) {
                return false;
            }
            (*idx) += 1;
            analyze_enum_lit(s, &lit_pt.pieces[1].as_ref().unwrap(),
                             scope, idx, e_, pt_for_loc)
        },
        _ => {
            analyze_enum_lit(s, lit_pt, scope, idx, e_, pt_for_loc)
        },
    }
}

fn analyze_type_decl(s: &mut AnalyzerCoreStateBlob,
    pt: &VhdlParseTreeNode, scope: ObjPoolIndex<Scope>) -> bool {

    let id = analyze_identifier(s, &pt.pieces[0].as_ref().unwrap());

    let typedef_pt = pt.pieces[1].as_ref().unwrap();
    match typedef_pt.node_type {
        ParseTreeNodeType::PT_ENUMERATION_TYPE_DEFINITION => {
            // The main declaration
            let loc = pt_loc(s, pt);
            let d_ = s.op_n.alloc();
            {
                let d = s.op_n.get_mut(d_);
                *d = AstNode::EnumerationTypeDecl {
                    loc: loc,
                    id: id,
                    literals: Vec::new(),
                };
            }

            if !try_add_declaration(s, ScopeItemName::Identifier(id),
                d_, scope) {

                dump_current_location(s, pt, true);
                s.errors += &format!(
                    "ERROR: Duplicate declaration of type {}!\n",
                    s.sp.retrieve_latin1_str(id.orig_name).pretty_name());
                return false;
            }

            // The literals
            let mut idx: i64 = 0;
            let lits_ok = analyze_enum_lits(s,
                &typedef_pt.pieces[0].as_ref().unwrap(), scope, &mut idx,
                d_, pt);
            if !lits_ok {
                return false;
            }
        },
        _ => panic!("Don't know how to handle this parse tree node!")
    }

    true
}

fn walk_scope_chain(s: &mut AnalyzerCoreStateBlob, item: ScopeItemName)
    -> Option<Vec<ObjPoolIndex<AstNode>>> {

    let mut ret = vec![];
    let mut cur_scope_node = s.innermost_scope;
    let mut looking_for_overloadable = false;
    let mut first_time = true;
    let mut used_param_result_type_profiles = vec![];
    while cur_scope_node.is_some() {
        let cur_scope_node_ = s.op_sc.get(cur_scope_node.unwrap());
        if let &ScopeChainNode::X{this_scope, parent} = cur_scope_node_ {
            // Try to find the thing
            if let Some(maybe_found_thing) = s.op_s.get(this_scope).get(item) {
                // We potentially found some things

                // TODO: we need to handle aliases

                // This should always be true
                assert!(maybe_found_thing.len() > 0);

                if first_time {
                    // Everything found must either all be overloadable
                    // or none can be overloadable (it cannot be mixed)
                    looking_for_overloadable = s.op_n.get(maybe_found_thing[0])
                        .is_an_overloadable_decl();

                    first_time = false;
                }

                if !looking_for_overloadable {
                    // We are looking for a non-overloadable thing, and we
                    // have Definitely found at least one. This means that
                    // we have found what we are looking for, and we are done!
                    assert!(maybe_found_thing.len() == 1);
                    ret.push(maybe_found_thing[0]);
                    break;
                } else {
                    // We are looking for overloadable things. Anything that
                    // isn't already shadowed is good

                    for &maybe_found_i in maybe_found_thing {
                        let this_param_result_profile =
                            get_parameter_result_type_profile(s,
                                maybe_found_i);

                        let mut matched = false;
                        for other_param_result_profile in
                            &used_param_result_type_profiles {

                            if this_param_result_profile ==
                                *other_param_result_profile {

                                matched = true;
                                break;
                            }
                        }

                        if !matched {
                            // We can add it
                            ret.push(maybe_found_i);
                            used_param_result_type_profiles.push(
                                this_param_result_profile);
                        }
                    }
                }
            }

            cur_scope_node = parent;
        } else {
            panic!("AST invariant violated!")
        }
    }

    if ret.len() > 0 {
        Some(ret)
    } else {
        None
    }
}

fn analyze_designator(s: &mut AnalyzerCoreStateBlob, pt: &VhdlParseTreeNode)
    -> ScopeItemName {

    match pt.node_type {
        ParseTreeNodeType::PT_BASIC_ID | ParseTreeNodeType::PT_EXT_ID => {
            ScopeItemName::Identifier(analyze_identifier(s, pt))
        },
        ParseTreeNodeType::PT_LIT_STRING => {
            let string_idx = {
                s.sp.add_latin1_str(&pt.str1)
            };
            ScopeItemName::StringLiteral(string_idx)
        },
        ParseTreeNodeType::PT_LIT_CHAR => {
            ScopeItemName::CharLiteral(pt.chr)
        },
        _ => panic!("Don't know how to handle this parse tree node!")
    }
}

// The point of these functions is to do _only_ scope and visibility logic
// (not overloading). There are three cases: overloadable (can get multiple),
// non-overloadable and a single thing ("normal"), and non-overloadable and
// multiple things (e.g. use clauses)
// TODO: Braindump better
fn analyze_name(s: &mut AnalyzerCoreStateBlob, pt: &VhdlParseTreeNode)
    -> Option<Vec<ObjPoolIndex<AstNode>>> {

    match pt.node_type {
        // simple_name, operator_symbol, or character_literal
        ParseTreeNodeType::PT_BASIC_ID | ParseTreeNodeType::PT_EXT_ID |
        ParseTreeNodeType::PT_LIT_STRING | ParseTreeNodeType::PT_LIT_CHAR => {
            let designator = analyze_designator(s, pt);

            // FIXME: I'm not sure this exactly follows the rules of the spec.
            // However, I don't know if it is noticeable or not. I think
            // that any time this rule can apply, the result can never be
            // something overloadable.
            if s.blacklisted_names.contains(&designator) {
                return None;
            }

            walk_scope_chain(s, designator)
        },

        // selected_name
        ParseTreeNodeType::PT_NAME_SELECTED => {
            // First figure out what the prefix is
            let prefix = analyze_name(s, &pt.pieces[0].as_ref().unwrap());
            if prefix.is_none() {
                return None;
            }
            let prefix = prefix.unwrap();
            let suffix_pt = &pt.pieces[1].as_ref().unwrap();

            if prefix.len() == 1 {
                // There is a single thing here
                let prefix = prefix[0];
                let designator = analyze_designator(s, suffix_pt);

                match s.op_n.get(prefix).kind() {
                    AstNodeKind::DeclarativeRegion => {
                        // TODO: The "only if we're currently inside" logic

                        let scope = s.op_n.get(prefix).scope().unwrap();

                        // Try to find the thing
                        if let Some(maybe_found_thing) =
                            s.op_s.get(scope).get(designator) {

                            // TODO: handle aliases??

                            // This should always be true
                            assert!(maybe_found_thing.len() > 0);

                            Some(maybe_found_thing.to_owned())
                        } else {
                            None
                        }
                    },
                    // TODO: Other things

                    // This is not a thing we can select into
                    _ => None,
                }
            } else {
                // This is a function call or something
                panic!("NOT IMPLEMENTED YET!");
            }
        },
        _ => panic!("Don't know how to handle this parse tree node!")
    }
}

fn analyze_type_mark(s: &mut AnalyzerCoreStateBlob,
    pt: &VhdlParseTreeNode, pt_for_loc: &VhdlParseTreeNode)
    -> Option<ObjPoolIndex<AstNode>> {

    let type_mark_ = analyze_name(s, pt);

    if type_mark_.is_none() {
        dump_current_location(s, pt_for_loc, true);
        s.errors +=  "ERROR: Bad name for type_mark\n";
        return None;
    }
    let type_mark = type_mark_.unwrap();

    if type_mark.len() != 1 {
        dump_current_location(s, pt_for_loc, true);
        s.errors +=  "ERROR: Bad name for type_mark\n";
        return None;
    }

    if s.op_n.get(type_mark[0]).kind() != AstNodeKind::Type {
        // FIXME: Do I need to do special stuff here anymore?
        dump_current_location(s, pt_for_loc, true);
        s.errors += "ERROR: name is not a type\n";
        return None;
    }

    Some(type_mark[0])
}

fn analyze_subtype_indication(s: &mut AnalyzerCoreStateBlob,
    pt: &VhdlParseTreeNode, pt_for_loc: &VhdlParseTreeNode)
    -> Option<ObjPoolIndex<AstNode>> {

    match pt.node_type {
        ParseTreeNodeType::PT_SUBTYPE_INDICATION => {
            // We have an absolutely normal subtype_indication

            // TODO: Not implemented
            assert!(pt.pieces[1].is_none());
            assert!(pt.pieces[2].is_none());

            let type_mark =
                analyze_type_mark(s, &pt.pieces[0].as_ref().unwrap(),
                                  pt_for_loc);

            if type_mark.is_none() {
                return None;
            }

            let x_ = s.op_n.alloc();
            {
                let x = s.op_n.get_mut(x_);
                *x = AstNode::SubtypeIndication {
                    type_mark: type_mark.unwrap(),
                };
            }

            Some(x_)
        },
        _ => panic!("Don't know how to handle this parse tree node!")
    }
}

fn analyze_subtype_decl(s: &mut AnalyzerCoreStateBlob,
    pt: &VhdlParseTreeNode, scope: ObjPoolIndex<Scope>) -> bool {

    let id = analyze_identifier(s, &pt.pieces[0].as_ref().unwrap());
    s.blacklisted_names.insert(ScopeItemName::Identifier(id));

    let loc = pt_loc(s, pt);
    let subtype_indication_ = analyze_subtype_indication(s,
        &pt.pieces[1].as_ref().unwrap(), pt);

    if subtype_indication_.is_none() {
        return false;
    }

    let x_ = s.op_n.alloc();
    {
        let x = s.op_n.get_mut(x_);
        *x = AstNode::SubtypeDecl {
            loc: loc,
            id: id,
            subtype_indication: subtype_indication_.unwrap(),
        };
    }

    if !try_add_declaration(s, ScopeItemName::Identifier(id), x_, scope) {
        dump_current_location(s, pt, true);
        s.errors += &format!(
            "ERROR: Duplicate declaration of subtype {}!\n",
            s.sp.retrieve_latin1_str(id.orig_name).pretty_name());
        return false;
    }

    s.blacklisted_names.clear();

    true
}

fn analyze_identifier_list(s: &mut AnalyzerCoreStateBlob,
    pt: &VhdlParseTreeNode) -> Vec<Identifier> {

    let mut ret = vec![];
    let mut cur_pt = pt;

    // Just parse in backwards order and reverse at the end
    while cur_pt.node_type == ParseTreeNodeType::PT_ID_LIST_REAL {
        let this_id =
            analyze_identifier(s, &cur_pt.pieces[1].as_ref().unwrap());
        ret.push(this_id);
        cur_pt = &cur_pt.pieces[0].as_ref().unwrap();
    }
    let final_id = analyze_identifier(s, cur_pt);
    ret.push(final_id);

    ret.reverse();

    ret
}

fn analyze_constant_decl(s: &mut AnalyzerCoreStateBlob,
    pt: &VhdlParseTreeNode, scope: ObjPoolIndex<Scope>) -> bool {

    let id_list = analyze_identifier_list(s, &pt.pieces[0].as_ref().unwrap());
    for &id in &id_list {
        s.blacklisted_names.insert(ScopeItemName::Identifier(id));
    }

    let loc = pt_loc(s, pt);
    let subtype_indication_ = analyze_subtype_indication(s,
        &pt.pieces[1].as_ref().unwrap(), pt);

    if subtype_indication_.is_none() {
        return false;
    }

    // TODO: Not implemented
    assert!(pt.pieces[2].is_none());

    for id in id_list {
        let x_ = s.op_n.alloc();
        {
            let x = s.op_n.get_mut(x_);
            *x = AstNode::ConstantDecl {
                loc: loc,
                id: id,
                subtype_indication: subtype_indication_.unwrap(),
                value: None,
            };
        }

        if !try_add_declaration(s, ScopeItemName::Identifier(id), x_, scope) {
            dump_current_location(s, pt, true);
            s.errors += &format!(
                "ERROR: Duplicate declaration of constant {}!\n",
                s.sp.retrieve_latin1_str(id.orig_name).pretty_name());
            return false;
        }
    }

    s.blacklisted_names.clear();

    true
}

fn analyze_subprogram_spec(s: &mut AnalyzerCoreStateBlob,
    pt: &VhdlParseTreeNode, pt_for_loc: &VhdlParseTreeNode,
    scope: ObjPoolIndex<Scope>) -> bool {

    match pt.node_type {
        ParseTreeNodeType::PT_FUNCTION_SPECIFICATION => {
            let is_pure = match pt.purity {
                ParseTreeFunctionPurity::PURITY_IMPURE => false,
                _ => true,
            };
            let loc = pt_loc(s, pt_for_loc);
            let designator =
                analyze_designator(s, &pt.pieces[0].as_ref().unwrap());
            s.blacklisted_names.insert(designator);

            let return_type =
                analyze_type_mark(s, &pt.pieces[1].as_ref().unwrap(),
                                  pt_for_loc);
            if return_type.is_none() {
                return false;
            }

            // Not implemented
            assert!(pt.pieces[2].is_none());
            assert!(pt.pieces[3].is_none());

            // We need a new internal name
            let internal_name =
                format!("__internal_anon_{}", s.internal_name_count);
            s.internal_name_count += 1;
            let mut internal_designator_id =
                Identifier::new_unicode(&mut s.sp, internal_name.as_str(),
                    true).unwrap();
            internal_designator_id.is_internal = true;
            let internal_designator =
                ScopeItemName::Identifier(internal_designator_id);

            // This is the generic piece
            let x_ = s.op_n.alloc();
            {
                let x = s.op_n.get_mut(x_);
                *x = AstNode::GenericFunctionDecl {
                    loc: loc,
                    designator: internal_designator,
                    return_type: return_type.unwrap(),
                    is_pure: is_pure,
                };
            }
            if !try_add_declaration(s, internal_designator, x_, scope) {
                panic!("Internal compiler error!");
            }

            // This is the instantiation
            let y_ = s.op_n.alloc();
            {
                let y = s.op_n.get_mut(y_);
                *y = AstNode::FuncInstantiation {
                    loc: loc,
                    designator: designator,
                    generic_func: x_,
                };
            }
            if !try_add_declaration(s, designator, y_, scope) {
                dump_current_location(s, pt, true);
                s.errors += &format!(
                    "ERROR: Duplicate declaration of function {}!\n",
                    designator.pretty_name(&mut s.sp));
                return false;
            }

            // FIXME: What is the correct spot to do this?
            s.blacklisted_names.clear();

            true
        },
        _ => panic!("Don't know how to handle this parse tree node!")
    }
}

fn analyze_subprogram_decl(s: &mut AnalyzerCoreStateBlob,
    pt: &VhdlParseTreeNode, scope: ObjPoolIndex<Scope>) -> bool {

    // FIXME: How exactly should this work?
    analyze_subprogram_spec(s, &pt.pieces[0].as_ref().unwrap(), pt, scope)
}


fn analyze_declarative_item(s: &mut AnalyzerCoreStateBlob,
    pt: &VhdlParseTreeNode, decl_scope: ObjPoolIndex<Scope>,
    use_scope: ObjPoolIndex<Scope>) -> bool {

    match pt.node_type {
        ParseTreeNodeType::PT_FULL_TYPE_DECLARATION =>
            analyze_type_decl(s, pt, decl_scope),
        ParseTreeNodeType::PT_SUBTYPE_DECLARATION =>
            analyze_subtype_decl(s, pt, decl_scope),
        ParseTreeNodeType::PT_CONSTANT_DECLARATION =>
            analyze_constant_decl(s, pt, decl_scope),
        ParseTreeNodeType::PT_SUBPROGRAM_DECLARATION =>
            analyze_subprogram_decl(s, pt, decl_scope),
        _ => panic!("Don't know how to handle this parse tree node!")
    }
}

fn analyze_declaration_list(s: &mut AnalyzerCoreStateBlob,
    pt: &VhdlParseTreeNode, decl_scope: ObjPoolIndex<Scope>,
    use_scope: ObjPoolIndex<Scope>) -> bool {

    match pt.node_type {
        ParseTreeNodeType::PT_DECLARATION_LIST => {
            if !analyze_declaration_list(s, &pt.pieces[0].as_ref().unwrap(),
                                         decl_scope, use_scope) {
                return false;
            }
            analyze_declarative_item(s, &pt.pieces[1].as_ref().unwrap(),
                                     decl_scope, use_scope)
        },
        _ => analyze_declarative_item(s, pt, decl_scope, use_scope)
    }
}

fn analyze_entity(s: &mut AnalyzerCoreStateBlob, pt: &VhdlParseTreeNode,
    tgt_scope: ObjPoolIndex<Scope>) -> bool {

    // Location information
    let loc = pt_loc(s, pt);

    // Our name
    let id = analyze_identifier(s, &pt.pieces[0].as_ref().unwrap());

    // Verify that the id at the end (if any) is the same as the one in the
    // beginning
    if let Some(tail_id_pt) = pt.pieces[4].as_ref() {
        let tail_id = analyze_identifier(s, tail_id_pt);
        if tail_id != id {
            dump_current_location(s, pt, true);
            s.errors +=
                "ERROR: Name at end of entity must match name at beginning\n";
            return false;
        }
    }

    // Check for duplicate entity
    // FIXME: Probably have to replace existing one at some point???
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

    // Create scopes and chain them up properly.
    // FIXME: Do note that we cheat a bunch here and don't pop off scope chain
    // nodes when things fail. This is fine because the next design unit
    // will start with an empty scope chain. However, we do need to remember
    // to remove these on success except on toplevel design units.
    let use_scope = s.op_s.alloc();
    let decl_scope = s.op_s.alloc();
    let use_sc = s.op_sc.alloc();
    let decl_sc = s.op_sc.alloc();
    {
        let use_sc_ = s.op_sc.get_mut(use_sc);
        *use_sc_ = ScopeChainNode::X {
            this_scope: use_scope,
            parent: s.innermost_scope
        };
    }
    {
        let decl_sc_ = s.op_sc.get_mut(decl_sc);
        *decl_sc_ = ScopeChainNode::X {
            this_scope: decl_scope,
            parent: Some(use_sc),
        }
    }
    s.innermost_scope = Some(decl_sc);

    // Set up the actual entity object
    let e_ = s.op_n.alloc();
    {
        let e = s.op_n.get_mut(e_);
        *e = AstNode::Entity {
            loc: loc,
            id: id,
            scope: decl_scope,
            scope_chain: decl_sc,
        };
    }
    s.op_s.get_mut(tgt_scope).add(ScopeItemName::Identifier(id), e_);

    // TODO

    // Declarations
    if let Some(decl_pt) = pt.pieces[2].as_ref() {
        if !analyze_declaration_list(s, decl_pt, decl_scope, use_scope) {
            return false;
        }
    }

    // Add the thing we analyzed to the library
    s.op_l.get_mut(s.work_lib.unwrap()).add_design_unit(id, e_);

    true
}

// Analyzes PT_DESIGN_UNIT
fn analyze_design_unit(s: &mut AnalyzerCoreStateBlob, pt: &VhdlParseTreeNode)
    -> bool {

    let mut no_errors = true;
    
    // Root declarative region
    let root_decl_region = s.op_sc.alloc();
    let root_decl_region_scope = s.op_s.alloc();
    {
        let root_decl_region_ = s.op_sc.get_mut(root_decl_region);
        *root_decl_region_ = ScopeChainNode::X {
            this_scope: root_decl_region_scope,
            parent: None,
        };
    }
    s.innermost_scope = Some(root_decl_region);

    // Not implemented
    assert!(pt.pieces[1].is_none());

    match pt.pieces[0].as_ref().unwrap().node_type {
        ParseTreeNodeType::PT_ENTITY => {
            no_errors &= analyze_entity(
                s, &pt.pieces[0].as_ref().unwrap(), root_decl_region_scope);
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
