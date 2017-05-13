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

use std::collections::HashMap;

use analyzer::identifier::*;
use analyzer::objpools::*;
use analyzer::util::*;

#[derive(Copy, Clone, Eq, PartialEq, Hash, Debug)]
pub struct SourceLoc {
    pub first_line: i32,
    pub first_column: i32,
    pub last_line: i32,
    pub last_column: i32,
    pub file_name: Option<StringPoolIndexOsStr>,
}

impl Default for SourceLoc {
    fn default() -> SourceLoc {
        SourceLoc {
            first_line: -1,
            first_column: -1,
            last_line: -1,
            last_column: -1,
            file_name: None
        }
    }
}

impl SourceLoc {
    pub fn debug_print(&self, sp: &StringPool) -> String {
        let mut s = format!(", \"first_line\": {}, \"first_column\": {}\
                             , \"last_line\": {}, \"last_column\": {}",
                            self.first_line, self.first_column,
                            self.last_line, self.last_column);

        if let Some(file_name) = self.file_name {
            s += &format!(", \"file_name\": \"{}\"",
                sp.retrieve_osstr(file_name).to_string_lossy());
        }

        s
    }

    pub fn format_for_error(&self, sp: &StringPool) -> String {
        match self.file_name {
            Some(file_name) => {
                format!("{}:{}:{}",
                    &sp.retrieve_osstr(file_name).to_string_lossy(),
                    self.first_line, self.first_column)
            }
            None => {
                format!("<unknown>:{}:{}", self.first_line, self.first_column)
            }
        }
    }
}


#[derive(Copy, Clone, Eq, PartialEq, Hash, Debug)]
pub enum ScopeItemName {
    Identifier(Identifier),
    CharLiteral(u8),
    StringLiteral(StringPoolIndexLatin1),
}

impl ScopeItemName {
    pub fn debug_print(&self, sp: &StringPool) -> String {
        match self {
            &ScopeItemName::Identifier(id) => id.debug_print(sp),
            &ScopeItemName::StringLiteral(strlit) => {
                format!("\"{}\"", sp.retrieve_latin1_str(strlit)
                    .debug_escaped_name())
            },
            &ScopeItemName::CharLiteral(c) =>
                format!("'{}'", get_chr_escaped(c)),
        }
    }

    pub fn pretty_name(&self, sp: &StringPool) -> String {
        match self {
            &ScopeItemName::Identifier(id) =>
                sp.retrieve_latin1_str(id.orig_name).pretty_name(),
            &ScopeItemName::StringLiteral(strlit) => {
                format!("\"{}\"", sp.retrieve_latin1_str(strlit).pretty_name())
            },
            &ScopeItemName::CharLiteral(c) =>
                format!("'{}'", LATIN1_PRETTYPRINT_TABLE[c as usize]),
        }
    }
}

#[derive(Debug)]
pub struct Scope {
    items: HashMap<ScopeItemName, Vec<ObjPoolIndex<AstNode>>>,
}

impl Default for Scope {
    fn default() -> Scope {
        Scope::new()
    }
}

impl Scope {
    pub fn new() -> Scope {
        Scope {items: HashMap::new()}
    }

    pub fn add(&mut self, name: ScopeItemName, item: ObjPoolIndex<AstNode>) {
        if let Some(existing_vec) = self.items.get_mut(&name) {
            existing_vec.push(item);
            return;
        }

        let new_vec = vec![item];
        self.items.insert(name, new_vec);
    }

    pub fn get(&self, name: ScopeItemName)
        -> Option<&[ObjPoolIndex<AstNode>]> {

        if let Some(existing_vec) = self.items.get(&name) {
            Some(existing_vec)
        } else {
            None
        }
    }
}

#[derive(Debug)]
pub enum ScopeChainNode {
    Invalid,
    X {
        this_scope: ObjPoolIndex<Scope>,
        parent: Option<ObjPoolIndex<ScopeChainNode>>,
    }
}

impl Default for ScopeChainNode {
    fn default() -> ScopeChainNode {
        ScopeChainNode::Invalid
    }
}

#[derive(Copy, Clone, Eq, PartialEq, Hash, Debug)]
pub enum EnumerationLiteral {
    Identifier(Identifier),
    CharLiteral(u8),
}

impl EnumerationLiteral {
    pub fn to_scope_item_name(&self) -> ScopeItemName {
        match self {
            &EnumerationLiteral::Identifier(id) =>
                ScopeItemName::Identifier(id),
            &EnumerationLiteral::CharLiteral(c) =>
                ScopeItemName::CharLiteral(c),
        }
    }
}


#[derive(Copy, Clone, Eq, PartialEq, Hash, Debug)]
pub enum AstNodeKind {
    Invalid,
    Other,
    Type,
    Object,
    DeclarativeRegion,
    GenericSubprogram,
    InstantiatedSubprogram,
}


#[derive(Debug)]
pub enum AstNode {
    Invalid,
    EnumerationLitDecl {
        lit: EnumerationLiteral,
        idx: i64,
        corresponding_type_decl: ObjPoolIndex<AstNode>,
    },
    EnumerationTypeDecl {
        loc: SourceLoc,
        id: Identifier,
        literals: Vec<ObjPoolIndex<AstNode>>,
    },
    Entity {
        loc: SourceLoc,
        id: Identifier,
        scope: ObjPoolIndex<Scope>,

        // This is needed for matching architectures
        // TODO: explain what is happening here
        scope_chain: ObjPoolIndex<ScopeChainNode>
    },
    SubtypeDecl {
        loc: SourceLoc,
        id: Identifier,
        subtype_indication: ObjPoolIndex<AstNode>,
    },
    SubtypeIndication {
        type_mark: ObjPoolIndex<AstNode>,
        // TODO
    },
    ConstantDecl {
        loc: SourceLoc,
        id: Identifier,
        subtype_indication: ObjPoolIndex<AstNode>,
        value: Option<ObjPoolIndex<AstNode>>,
    },
    GenericFunctionDecl {
        loc: SourceLoc,
        designator: ScopeItemName,

        // TODO: generics
        // TODO: args
        // TODO: return

        is_pure: bool,
    },
    FuncInstantiation {
        loc: SourceLoc,
        designator: ScopeItemName,

        // TODO: generic map

        generic_func: ObjPoolIndex<AstNode>,
    },
}

impl Default for AstNode {
    fn default() -> AstNode { AstNode::Invalid }
}

impl AstNode {
    pub fn kind(&self) -> AstNodeKind {
        match self {
            _ => self.real_kind(),
        }
    }

    pub fn real_kind(&self) -> AstNodeKind {
        match self {
            &AstNode::Invalid => AstNodeKind::Invalid,
            &AstNode::EnumerationTypeDecl{..} |
            &AstNode::SubtypeDecl{..}
                => AstNodeKind::Type,
            &AstNode::Entity{..} => AstNodeKind::DeclarativeRegion,
            &AstNode::ConstantDecl{..} => AstNodeKind::Object,
            _ => AstNodeKind::Other,
        }
    }

    pub fn is_an_overloadable_decl(&self) -> bool {
        match self {
            &AstNode::EnumerationLitDecl{..} => true,
            _ => false,
        }
    }

    pub fn loc(&self) -> Option<SourceLoc> {
        match self {
            &AstNode::EnumerationTypeDecl {loc, ..} => Some(loc),
            &AstNode::Entity {loc, ..} => Some(loc),
            &AstNode::SubtypeDecl {loc, ..} => Some(loc),
            &AstNode::ConstantDecl {loc, ..} => Some(loc),
            &AstNode::GenericFunctionDecl {loc, ..} => Some(loc),
            &AstNode::FuncInstantiation {loc, ..} => Some(loc),
            _ => None
        }
    }

    pub fn id(&self) -> Option<Identifier> {
        match self {
            &AstNode::EnumerationTypeDecl {id, ..} => Some(id),
            &AstNode::Entity {id, ..} => Some(id),
            &AstNode::SubtypeDecl {id, ..} => Some(id),
            &AstNode::ConstantDecl {id, ..} => Some(id),
            _ => None
        }
    }

    pub fn designator(&self) -> Option<ScopeItemName> {
        match self {
            &AstNode::GenericFunctionDecl {designator, ..} => Some(designator),
            &AstNode::FuncInstantiation {designator, ..} => Some(designator),
            _ => {
                if let Some(id) = self.id() {
                    Some(ScopeItemName::Identifier(id))
                } else {
                    None
                }
            }
        }
    }

    pub fn scope(&self) -> Option<ObjPoolIndex<Scope>> {
        match self {
            &AstNode::Entity {scope, ..} => Some(scope),
            _ => None
        }
    }

    pub fn debug_print(&self, sp: &StringPool, op_n: &ObjPool<AstNode>,
        op_s: &ObjPool<Scope>) -> String {

        match self {
            &AstNode::EnumerationLitDecl {
                idx, lit, corresponding_type_decl
            } => {
                let corresponding_type_decl =
                    op_n.get(corresponding_type_decl);

                format!("{{\"type\": \"EnumerationLitDecl\"{}, \"idx\": {}\
                         , \"enum_name\": {}}}",
                    match lit {
                        EnumerationLiteral::Identifier(id) =>
                            format!(", \"id\": {}", id.debug_print(sp)),
                        EnumerationLiteral::CharLiteral(c) =>
                            format!(", \"chr\": \"{}\"", get_chr_escaped(c)),
                    },
                    idx,
                    corresponding_type_decl.id().unwrap().debug_print(sp))
            },

            &AstNode::EnumerationTypeDecl {loc, id, ..} => {
                format!("{{\"type\": \"EnumerationTypeDecl\", \"id\": {}{}}}",
                    id.debug_print(sp), loc.debug_print(sp))
            },

            &AstNode::Entity {loc, id, scope, ..} => {
                let mut s = String::new();

                s += &format!("{{\"type\": \"Entity\", \"id\": {}{}",
                    id.debug_print(sp), loc.debug_print(sp));

                s += ", \"decls\": [\"__is_a_set\"";

                for (_, decl_values) in &op_s.get(scope).items {
                    for decl_value in decl_values {
                        s += ",";
                        s += &op_n.get(*decl_value).debug_print(
                            sp, op_n, op_s);
                    }
                }

                s += "]}";

                s
            },

            &AstNode::SubtypeDecl {loc, id, subtype_indication, ..} => {
                format!("{{\"type\": \"SubtypeDecl\", \"id\": {}{}\
                         , \"subtype_indication\": {}}}",
                    id.debug_print(sp), loc.debug_print(sp),
                    op_n.get(subtype_indication).debug_print(sp, op_n, op_s))
            },

            &AstNode::SubtypeIndication {type_mark} => {
                let type_mark = op_n.get(type_mark);

                format!("{{\"type\": \"SubtypeIndication\"\
                         , \"type_mark\": {}}}",
                    type_mark.id().unwrap().debug_print(sp))
            },

            &AstNode::ConstantDecl {loc, id, subtype_indication, value} => {
                format!("{{\"type\": \"ConstantDecl\", \"id\": {}{}\
                         , \"subtype_indication\": {}, \"value\": {}}}",
                    id.debug_print(sp), loc.debug_print(sp),
                    op_n.get(subtype_indication).debug_print(sp, op_n, op_s),
                    if let Some(value) = value {
                        op_n.get(value).debug_print(sp, op_n, op_s)
                    } else {
                        String::from("null")
                    })
            },

            &AstNode::GenericFunctionDecl {loc, designator, is_pure} => {
                format!("{{\"type\": \"GenericFunctionDecl\"\
                         , \"designator\": {}{}, \"pure\": {}}}",
                    designator.debug_print(sp), loc.debug_print(sp),
                    if is_pure { "true" } else { "false" })
            },

            &AstNode::FuncInstantiation {loc, designator, generic_func} => {
                format!("{{\"type\": \"FuncInstantiation\"\
                         , \"designator\": {}{}, \"tgt\": {}}}",
                    designator.debug_print(sp), loc.debug_print(sp),
                    match op_n.get(generic_func) {
                        &AstNode::GenericFunctionDecl {designator, ..} =>
                            designator.debug_print(sp),
                        _ => panic!("AST invariant violated!"),
                    })
            },

            _ => panic!("don't know how to print this AstNode!")
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    use std::ffi::OsStr;

    #[test]
    fn scope_basic() {
        let mut sp = StringPool::new();
        let mut op = ObjPool::<AstNode>::new();

        let mut test1_scope = Scope::new();
        let test1_1 = Identifier::new_unicode(&mut sp, "a", false).unwrap();
        let test1_node = op.alloc();
        test1_scope.add(ScopeItemName::Identifier(test1_1), test1_node);
        let test1_2 = Identifier::new_unicode(&mut sp, "a", false).unwrap();
        let test1_result =
            test1_scope.get(ScopeItemName::Identifier(test1_2)).unwrap();
        assert_eq!(test1_result.len(), 1);
        assert_eq!(test1_result[0], test1_node);

        let mut test2_scope = Scope::new();
        let test2_node = op.alloc();
        test2_scope.add(ScopeItemName::CharLiteral(b'a'), test2_node);
        let test2_result =
            test2_scope.get(ScopeItemName::CharLiteral(b'a')).unwrap();
        assert_eq!(test2_result.len(), 1);
        assert_eq!(test2_result[0], test2_node);

        let mut test3_scope = Scope::new();
        let test3_1 = sp.add_latin1_str(b"a");
        let test3_node = op.alloc();
        test3_scope.add(ScopeItemName::StringLiteral(test3_1), test3_node);
        let test3_2 = sp.add_latin1_str(b"a");
        let test3_result =
            test3_scope.get(ScopeItemName::StringLiteral(test3_2)).unwrap();
        assert_eq!(test3_result.len(), 1);
        assert_eq!(test3_result[0], test3_node);
    }

    #[test]
    fn scope_type_isolation() {
        let mut sp = StringPool::new();
        let mut op = ObjPool::<AstNode>::new();

        let mut test1_scope = Scope::new();
        let test1_1 = ScopeItemName::Identifier(
            Identifier::new_unicode(&mut sp, "a", false).unwrap());
        let test1_2 = ScopeItemName::CharLiteral(b'a');
        let test1_3 = ScopeItemName::StringLiteral(sp.add_latin1_str(b"a"));
        let test1_node = op.alloc();
        test1_scope.add(test1_1, test1_node);
        let test1_result1 = test1_scope.get(test1_2);
        let test1_result2 = test1_scope.get(test1_3);
        assert!(test1_result1.is_none());
        assert!(test1_result2.is_none());

        let mut test2_scope = Scope::new();
        let test2_1 = ScopeItemName::Identifier(
            Identifier::new_unicode(&mut sp, "a", false).unwrap());
        let test2_2 = ScopeItemName::CharLiteral(b'a');
        let test2_3 = ScopeItemName::StringLiteral(sp.add_latin1_str(b"a"));
        let test2_node = op.alloc();
        test2_scope.add(test2_2, test2_node);
        let test2_result1 = test2_scope.get(test2_1);
        let test2_result2 = test2_scope.get(test2_3);
        assert!(test2_result1.is_none());
        assert!(test2_result2.is_none());

        let mut test3_scope = Scope::new();
        let test3_1 = ScopeItemName::Identifier(
            Identifier::new_unicode(&mut sp, "a", false).unwrap());
        let test3_2 = ScopeItemName::CharLiteral(b'a');
        let test3_3 = ScopeItemName::StringLiteral(sp.add_latin1_str(b"a"));
        let test3_node = op.alloc();
        test3_scope.add(test3_3, test3_node);
        let test3_result1 = test3_scope.get(test3_1);
        let test3_result2 = test3_scope.get(test3_2);
        assert!(test3_result1.is_none());
        assert!(test3_result2.is_none());
    }

    #[test]
    fn scope_overloading() {
        let mut sp = StringPool::new();
        let mut op = ObjPool::<AstNode>::new();

        let mut test1_scope = Scope::new();
        let test1_1 = ScopeItemName::CharLiteral(b'a');
        let test1_node1 = op.alloc();
        let test1_node2 = op.alloc();
        let test1_node3 = op.alloc();
        test1_scope.add(test1_1, test1_node1);
        test1_scope.add(test1_1, test1_node2);
        test1_scope.add(test1_1, test1_node3);
        let test1_2 = ScopeItemName::CharLiteral(b'a');
        let test1_result = test1_scope.get(test1_2).unwrap();
        assert_eq!(test1_result.len(), 3);
        assert_eq!(test1_result[0], test1_node1);
        assert_eq!(test1_result[1], test1_node2);
        assert_eq!(test1_result[2], test1_node3);
    }

    #[test]
    fn sourceloc_test() {
        let mut sp = StringPool::new();

        let test1 = SourceLoc::default();
        assert_eq!(test1.debug_print(&sp),
            ", \"first_line\": -1, \"first_column\": -1\
             , \"last_line\": -1, \"last_column\": -1");
        assert_eq!(test1.format_for_error(&sp), "<unknown>:-1:-1");

        let test2 = SourceLoc {
            first_line: 123,
            first_column: 456,
            last_line: 789,
            last_column: 888,
            file_name: None
        };
        assert_eq!(test2.debug_print(&sp),
            ", \"first_line\": 123, \"first_column\": 456\
             , \"last_line\": 789, \"last_column\": 888");
        assert_eq!(test2.format_for_error(&sp), "<unknown>:123:456");

        let test3_str = sp.add_osstr(OsStr::new("myfile"));
        let test3 = SourceLoc {
            first_line: 123,
            first_column: 456,
            last_line: 789,
            last_column: 888,
            file_name: Some(test3_str)
        };
        assert_eq!(test3.debug_print(&sp),
            ", \"first_line\": 123, \"first_column\": 456\
             , \"last_line\": 789, \"last_column\": 888\
             , \"file_name\": \"myfile\"");
        assert_eq!(test3.format_for_error(&sp), "myfile:123:456");
    }
}
