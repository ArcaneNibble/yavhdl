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

use std::hash::{Hash, Hasher};

use analyzer::objpools::*;
use analyzer::util::*;

#[derive(Copy, Clone, Eq, Debug)]
pub struct Identifier {
    pub orig_name: StringPoolIndexLatin1,
    pub canonical_name: StringPoolIndexLatin1,
    pub is_extended_id: bool,
}

impl PartialEq for Identifier {
    fn eq(&self, other: &Identifier) -> bool {
        (self.is_extended_id == other.is_extended_id) &&
        (self.canonical_name == other.canonical_name)
    }
}

impl Hash for Identifier {
    fn hash<H: Hasher>(&self, state: &mut H) {
        self.canonical_name.hash(state);
        self.is_extended_id.hash(state);
    }
}

impl Identifier {
    pub fn new_latin1(
        sp: &mut StringPool, name: StringPoolIndexLatin1, ext: bool)
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

    pub fn new_unicode(sp: &mut StringPool, name: &str, ext: bool)
        -> Result<Identifier, &'static str> {

        let mut latin1_name = Vec::<u8>::new();
        for c in name.chars() {
            if c >= '\u{0100}' {
                return Err("name contains characters outside Latin-1 range");
            }

            latin1_name.push(c as u8);
        }

        let sp_idx = sp.add_latin1_str(&latin1_name);
        Identifier::new_latin1(sp, sp_idx, ext)
    }

    pub fn debug_print(&self, sp: &StringPool) -> String {
        if self.is_extended_id {
            format!("\"\\\\{}\\\\\"", sp.retrieve_latin1_str(
                self.orig_name).debug_escaped_name())
        } else {
            format!("\"{}\"", sp.retrieve_latin1_str(
                self.orig_name).debug_escaped_name())
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::hash::SipHasher;

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

    #[test]
    fn identifier_unicode() {
        let mut sp = StringPool::new();

        let test1 = Identifier::new_unicode(&mut sp, "FoO", false).unwrap();
        assert_eq!(sp.retrieve_latin1_str(
            test1.orig_name).raw_name(), b"FoO");
        assert_eq!(sp.retrieve_latin1_str(
            test1.canonical_name).raw_name(), b"foo");
        assert_eq!(sp.retrieve_latin1_str(
            test1.orig_name).pretty_name(), "FoO");
        assert!(!test1.is_extended_id);

        let test2 = Identifier::new_unicode(&mut sp, "fÖo", false).unwrap();
        assert_eq!(sp.retrieve_latin1_str(
            test2.orig_name).raw_name(), b"f\xD6o");
        assert_eq!(sp.retrieve_latin1_str(
            test2.canonical_name).raw_name(), b"f\xF6o");
        assert_eq!(sp.retrieve_latin1_str(
            test2.orig_name).pretty_name(), "fÖo");
        assert!(!test2.is_extended_id);

        let test3 = Identifier::new_unicode(&mut sp, "fooĀ", false);
        assert!(test3.is_err());

        let test4 = Identifier::new_unicode(&mut sp, "f😀oo", false);
        assert!(test4.is_err());
    }

    fn hash<T: Hash>(t: &T) -> u64 {
        let mut s = SipHasher::new();
        t.hash(&mut s);
        s.finish()
    }

    #[test]
    fn identifier_eq_and_hash() {
        let mut sp = StringPool::new();

        let test1 = Identifier::new_unicode(&mut sp, "foo", false).unwrap();
        let test2 = Identifier::new_unicode(&mut sp, "fOo", false).unwrap();
        assert_eq!(hash(&test1), hash(&test2));
        assert_eq!(test1, test2);

        let test1 = Identifier::new_unicode(&mut sp, "foo", false).unwrap();
        let test2 = Identifier::new_unicode(&mut sp, "foo", true).unwrap();
        assert!(test1 != test2);

        let test1 = Identifier::new_unicode(&mut sp, "foo", true).unwrap();
        let test2 = Identifier::new_unicode(&mut sp, "foo", true).unwrap();
        assert_eq!(hash(&test1), hash(&test2));
        assert_eq!(test1, test2);

        let test1 = Identifier::new_unicode(&mut sp, "foo", true).unwrap();
        let test2 = Identifier::new_unicode(&mut sp, "fOo", true).unwrap();
        assert!(test1 != test2);
    }

    #[test]
    fn identifier_debug_print() {
        let mut sp = StringPool::new();

        let test1 = Identifier::new_unicode(&mut sp, "foo", false).unwrap();
        assert_eq!(test1.debug_print(&sp), "\"foo\"");

        let test1 = Identifier::new_unicode(&mut sp, "foo", true).unwrap();
        assert_eq!(test1.debug_print(&sp), "\"\\\\foo\\\\\"");

        let test1 = Identifier::new_unicode(&mut sp, "fÖo", false).unwrap();
        assert_eq!(test1.debug_print(&sp), "\"f\\u00d6o\"");
    }
}
