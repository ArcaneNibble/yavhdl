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
pub enum Library {
    Invalid,
    X {
        id: Identifier,

        db_by_name: HashMap<Identifier, ObjPoolIndex<AstNode>>,
        db_by_order: Vec<ObjPoolIndex<AstNode>>,
    }
}

impl Default for Library {
    fn default() -> Library {
        Library::Invalid
    }
}

impl Library {
    pub fn new(id: Identifier) -> Library {
        Library::X {
            id: id,
            db_by_name: HashMap::new(),
            db_by_order: Vec::new(),
        }
    }

    // FIXME: This matching stuff is pretty ugly
    pub fn add_design_unit(&mut self,
        name: Identifier, unit: ObjPoolIndex<AstNode>) {

        match self {
            &mut Library::Invalid => panic!("use of Invalid library"),
            &mut Library::X {ref mut db_by_name, ref mut db_by_order, ..} => {
                db_by_name.insert(name, unit);
                db_by_order.push(unit);
            }
        }
    }

    pub fn find_design_unit(&self, name: Identifier)
        -> Option<ObjPoolIndex<AstNode>> {

        match self {
            &Library::Invalid => panic!("use of Invalid library"),
            &Library::X {ref db_by_name, ..} => {
                db_by_name.get(&name).cloned()
            }
        }
    }

    pub fn debug_print(&self, sp: &StringPool, op_n: &ObjPool<AstNode>,
        op_s: &ObjPool<Scope>) -> String {

        match self {
            &Library::Invalid => panic!("use of Invalid library"),
            &Library::X {ref id, ref db_by_order, ..} => {
                    let mut s = String::new();

                    s += &format!("{{\"type\": \"Library\", \"id\": {}, \
                                   \"units\": [",
                        id.debug_print(sp));

                    let mut first = true;
                    for unit in db_by_order {
                        if !first {
                            s += ", ";
                        }
                        first = false;

                        s += &op_n.get(*unit).debug_print(sp, op_n, op_s);
                    }

                    s += "]}";

                    s
                }
        }

    }
}


#[derive(Debug)]
pub struct DesignDatabase {
    db_by_name: HashMap<Identifier, ObjPoolIndex<Library>>,
    db_by_order: Vec<ObjPoolIndex<Library>>,
}

impl DesignDatabase {
    pub fn new() -> DesignDatabase {
        DesignDatabase {
            db_by_name: HashMap::new(),
            db_by_order: Vec::new(),
        }
    }

    pub fn populate_builtins(&mut self) {
        // TODO
    }

    pub fn add_library(&mut self,
        name: Identifier, unit: ObjPoolIndex<Library>) {

        self.db_by_name.insert(name, unit);
        self.db_by_order.push(unit);
    }

    pub fn find_library(&self, name: Identifier)
        -> Option<ObjPoolIndex<Library>> {

        self.db_by_name.get(&name).cloned()
    }

    pub fn debug_print(&self, sp: &StringPool, op_l: &ObjPool<Library>,
        op_n: &ObjPool<AstNode>, op_s: &ObjPool<Scope>) -> String {


        let mut s = String::new();

        s += "{\"type\": \"DesignDatabase\", \"libraries\": [";

        let mut first = true;
        for lib in &self.db_by_order {
            if !first {
                s += ", ";
            }
            first = false;

            s += &op_l.get(*lib).debug_print(sp, op_n, op_s);
        }

        s += "]}";

        s
    }
}

#[cfg(tests)]
mod tests {

}
