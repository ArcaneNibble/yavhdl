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
pub struct ScopeChainNode {
    pub this_scope: Scope,
    pub parent: Option<ObjPoolIndex<ScopeChainNode>>,
}

impl Default for ScopeChainNode {
    fn default() -> ScopeChainNode {
        ScopeChainNode {
            this_scope: Scope::new(),
            parent: None,
        }
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


#[derive(Debug)]
pub enum AstNode {
    Invalid,
    EnumerationLitDecl {
        lit: EnumerationLiteral,
        idx: u64,
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
        root_decl_region: ObjPoolIndex<ScopeChainNode>
    },
    SubtypeDecl {
        loc: SourceLoc,
        id: Identifier,
        // TODO
    }
}

impl Default for AstNode {
    fn default() -> AstNode { AstNode::Invalid }
}

impl AstNode {
    pub fn is_an_overloadable_decl(&self) -> bool {
        match self {
            &AstNode::EnumerationLitDecl{..} => true,
            _ => false,
        }
    }

    pub fn debug_print(&self, sp: &StringPool, op_n: &ObjPool<AstNode>,
        op_s: &ObjPool<Scope>) -> String {

        match self {
            &AstNode::EnumerationLitDecl {
                idx: idx, lit: lit,
                corresponding_type_decl: corresponding_type_decl_
            } => {
                let corresponding_type_decl =
                    op_n.get(corresponding_type_decl_);

                format!("{{\"type\": \"EnumerationLitDecl\"{}, \"idx\": {}\
                         , \"enum_name\": {}}}",
                    match lit {
                        EnumerationLiteral::Identifier(id) =>
                            format!(", \"id\": {}", id.debug_print(sp)),
                        EnumerationLiteral::CharLiteral(c) =>
                            format!(", \"chr\": \"{}\"", get_chr_escaped(c)),
                    },
                    idx,
                    match corresponding_type_decl {
                        &AstNode::EnumerationTypeDecl{id: id, ..} =>
                            id.debug_print(sp),
                        _ => panic!("AST invariant violated!")
                    })
            },

            &AstNode::EnumerationTypeDecl {loc: loc, id: id, ..} => {
                format!("{{\"type\": \"EnumerationTypeDecl\", \"id\": {}{}}}",
                    id.debug_print(sp), loc.debug_print(sp))
            },

            &AstNode::Entity {loc: loc, id: id, scope: scope, ..} => {
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

            &AstNode::SubtypeDecl {loc: loc, id: id} => {
                format!("{{\"type\": \"SubtypeDecl\", \"id\": {}{}}}",
                    id.debug_print(sp), loc.debug_print(sp))
            }

            _ => panic!("don't know how to print this AstNode!")
        }
    }

    pub fn loc(&self) -> Option<SourceLoc> {
        match self {
            &AstNode::EnumerationTypeDecl {loc: loc, ..} => Some(loc),
            &AstNode::Entity {loc: loc, ..} => Some(loc),
            &AstNode::SubtypeDecl {loc: loc, ..} => Some(loc),
            _ => None
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
