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

#[derive(Debug)]
pub enum AstNode {
    Invalid
}

impl Default for AstNode {
    fn default() -> AstNode { AstNode::Invalid }
}

#[derive(Copy, Clone, Eq, PartialEq, Hash, Debug)]
pub enum ScopeItemName {
    Identifier(Identifier),
    CharLiteral(u8),
    StringLiteral(StringPoolIndex),
}

pub struct Scope {
    items: HashMap<ScopeItemName, Vec<ObjPoolIndex<AstNode>>>,
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

#[cfg(test)]
mod tests {
    use super::*;

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
}
