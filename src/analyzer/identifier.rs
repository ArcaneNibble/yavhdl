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

use analyzer::objpools::*;
use analyzer::util::*;

pub struct Identifier {
    pub orig_name: StringPoolIndex,
    pub canonical_name: StringPoolIndex,
    pub is_extended_id: bool,
}

impl Identifier {
    pub fn new_latin1(sp: &mut StringPool, name: StringPoolIndex, ext: bool)
        -> Result<Identifier, &'static str> {

        let canonical_name_vec = {
            // Borrow the name because we're going to need to look at it
            let name_ = sp.retrieve_latin1_str(name);

            // Validation
            if ext && !name_.valid_for_ext_id() {
                return Err("name is unacceptable as an identifier");
            }
            if !ext && !name_.valid_for_basic_id() {
                return Err("name is unacceptable as an identifier");
            }

            // Possibly lowercase canonical name for basic identifiers
            if ext {
                None
            } else {
                let mut lcase_name = Vec::<u8>::new();
                for c in name_.raw_name() {
                    lcase_name.push(LATIN1_LCASE_TABLE[*c as usize]);
                }
                Some(lcase_name)
            }
        };

        // We needed to make name_ out of scope before we can actually try
        // to add the new canonical name
        let mut canonical_name = name;
        if let Some(lcase_name) = canonical_name_vec {
            canonical_name = sp.add_latin1_str(&lcase_name);
        }

        Ok(Identifier {
            orig_name: name,
            canonical_name: canonical_name,
            is_extended_id: ext,
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn identifier_basic() {
        let mut sp = StringPool::new();

        let sp_idx = sp.add_latin1_str(b"foo");
        let test1 = Identifier::new_latin1(&mut sp, sp_idx, false).unwrap();
        assert_eq!(sp.retrieve_latin1_str(
            test1.orig_name).raw_name(), b"foo");
        assert_eq!(sp.retrieve_latin1_str(
            test1.canonical_name).raw_name(), b"foo");
        assert_eq!(sp.retrieve_latin1_str(
            test1.orig_name).pretty_name(), "foo");
        assert!(!test1.is_extended_id);

        let sp_idx = sp.add_latin1_str(b"FoO");
        let test2 = Identifier::new_latin1(&mut sp, sp_idx, false).unwrap();
        assert_eq!(sp.retrieve_latin1_str(
            test2.orig_name).raw_name(), b"FoO");
        assert_eq!(sp.retrieve_latin1_str(
            test2.canonical_name).raw_name(), b"foo");
        assert_eq!(sp.retrieve_latin1_str(
            test2.orig_name).pretty_name(), "FoO");
        assert!(!test2.is_extended_id);

        let sp_idx = sp.add_latin1_str(b"foo_");
        let test3 = Identifier::new_latin1(&mut sp, sp_idx, false);
        assert!(test3.is_err());

        let sp_idx = sp.add_latin1_str(b"FoO");
        let test4 = Identifier::new_latin1(&mut sp, sp_idx, true).unwrap();
        assert_eq!(sp.retrieve_latin1_str(
            test4.orig_name).raw_name(), b"FoO");
        assert_eq!(sp.retrieve_latin1_str(
            test4.canonical_name).raw_name(), b"FoO");
        assert_eq!(sp.retrieve_latin1_str(
            test4.orig_name).pretty_name(), "FoO");
        assert!(test4.is_extended_id);
    }

    #[test]
    fn identifier_latin1_unusual() {
        let mut sp = StringPool::new();

        let sp_idx = sp.add_latin1_str(b"f\xD6o");
        let test1 = Identifier::new_latin1(&mut sp, sp_idx, false).unwrap();
        assert_eq!(sp.retrieve_latin1_str(
            test1.orig_name).raw_name(), b"f\xD6o");
        assert_eq!(sp.retrieve_latin1_str(
            test1.canonical_name).raw_name(), b"f\xF6o");
        assert_eq!(sp.retrieve_latin1_str(
            test1.orig_name).pretty_name(), "fÖo");
        assert!(!test1.is_extended_id);

        let sp_idx = sp.add_latin1_str(b"foo\xD7");
        let test2 = Identifier::new_latin1(&mut sp, sp_idx, false);
        assert!(test2.is_err());

        let sp_idx = sp.add_latin1_str(b"f\xD6o\xD7\xBC");
        let test3 = Identifier::new_latin1(&mut sp, sp_idx, true).unwrap();
        assert_eq!(sp.retrieve_latin1_str(
            test3.orig_name).raw_name(), b"f\xD6o\xD7\xBC");
        assert_eq!(sp.retrieve_latin1_str(
            test3.canonical_name).raw_name(), b"f\xD6o\xD7\xBC");
        assert_eq!(sp.retrieve_latin1_str(
            test3.orig_name).pretty_name(), "fÖo×¼");
        assert!(test3.is_extended_id);
    }
}
