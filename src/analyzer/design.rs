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

use analyzer::ast::*;
use analyzer::identifier::*;
use analyzer::objpools::*;

#[derive(Debug)]
pub struct Library {
    id: Identifier,

    db_by_name: HashMap<Identifier, ObjPoolIndex<AstNode>>,
    db_by_order: Vec<ObjPoolIndex<AstNode>>,
    temp_id: Option<Identifier>,
    temp_node: Option<ObjPoolIndex<AstNode>>,
}

impl Library {
    pub fn new(id: Identifier) -> Library {
        Library {
            id: id,
            db_by_name: HashMap::new(),
            db_by_order: Vec::new(),
            temp_id: None,
            temp_node: None,
        }
    }

    pub fn add_design_unit(&mut self,
        name: Identifier, unit: ObjPoolIndex<AstNode>) {

        self.db_by_name.insert(name, unit);
        self.db_by_order.push(unit);
    }

    pub fn find_design_unit(&self, name: Identifier)
        -> Option<ObjPoolIndex<AstNode>> {

        // Check the tentative one first if we have one
        if let Some(temp_id) = self.temp_id {
            return self.temp_node;
        }

        self.db_by_name.get(&name).cloned()
    }

    pub fn tentative_add_design_unit(&mut self,
        name: Identifier, unit: ObjPoolIndex<AstNode>) {

        // Cannot add a new tentative thing if we already have one
        assert!(self.temp_node.is_none());

        self.temp_id = Some(name);
        self.temp_node = Some(unit);
    }

    pub fn commit_tentative_design_unit(&mut self) {
        let name = self.temp_id.take().unwrap();
        let node = self.temp_node.take().unwrap();

        self.add_design_unit(name, node);
    }

    pub fn drop_tentative_design_unit(&mut self) {
        self.temp_id.take();
        self.temp_node.take();
    }

    pub fn debug_print(&self, sp: &StringPool, op: &ObjPool<AstNode>)
        -> String {

        let mut s = String::new();

        s += &format!("{{\"type\": \"Library\", \"id\": {}, \"units\": [",
            self.id.debug_print(sp));

        let mut first = true;
        for unit in &self.db_by_order {
            if !first {
                s += ", ";
            }
            first = false;

            s += &op.get(*unit).debug_print(sp, op);
        }

        s += "]}";

        s
    }
}

#[cfg(tests)]
mod tests {

}
