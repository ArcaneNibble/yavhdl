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
use std::marker::PhantomData;

use analyzer::util::*;

// We need this because the Vec can be reallocated around, but we want to keep
// around some kind of reference into the storage that can keep working after
// the reallocation happens.
#[derive(Copy, Clone, Eq, PartialEq, Debug)]
pub struct StringPoolIndex {
    start: usize,
    end: usize,
}

pub struct StringPool {
    storage: Vec<u8>,
    hashtable: HashMap<Vec<u8>, StringPoolIndex>,
}

impl<'a> StringPool {
    pub fn new() -> StringPool {
        StringPool {
            storage: Vec::new(),
            hashtable: HashMap::new(),
        }
    }

    // TODO: Do we care about freeing things?
    pub fn add_latin1_str(&mut self, inp: &[u8]) -> StringPoolIndex {
        // We now need to intern the string because we need to ensure that
        // we always can compare string pool indices. This is needed so that
        // Identifiers can be compared without having to drag the string
        // pool around, which is in turn needed so that Identifiers can be
        // properly hashed.
        if let Some(existing_idx) = self.hashtable.get(inp) {
            return *existing_idx;
        }

        let addition_begin = self.storage.len();
        let addition_end = addition_begin + inp.len();

        self.storage.extend(inp.iter().cloned());

        let new_idx = StringPoolIndex {
            start: addition_begin,
            end: addition_end
        };

        self.hashtable.insert(inp.to_vec(), new_idx);

        new_idx
    }

    pub fn retrieve_latin1_str(&self, i: StringPoolIndex) -> Latin1Str {
        let the_slice = &self.storage[i.start..i.end];
        Latin1Str::new(the_slice)
    }
}


pub struct ObjPoolIndex<T> {
    i: usize,
    type_marker: PhantomData<T>
}

impl<T> Copy for ObjPoolIndex<T> { }

impl<T> Clone for ObjPoolIndex<T> {
    fn clone(&self) -> ObjPoolIndex<T> {
        *self
    }
}

pub struct ObjPool<T> {
    storage: Vec<T>
}

impl<T: Default> ObjPool<T> {
    pub fn new() -> ObjPool<T> {
        ObjPool {storage: Vec::new()}
    }

    pub fn alloc(&mut self) -> ObjPoolIndex<T> {
        let i = self.storage.len();
        let o = T::default();

        self.storage.push(o);

        ObjPoolIndex::<T> {i: i, type_marker: PhantomData}
    }

    pub fn get(&self, i: ObjPoolIndex<T>) -> &T {
        &self.storage[i.i]
    }

    pub fn get_mut(&mut self, i: ObjPoolIndex<T>) -> &mut T {
        &mut self.storage[i.i]
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn stringpool_basic_works() {
        let mut sp = StringPool::new();
        let x = sp.add_latin1_str(b"test1");
        let y = sp.add_latin1_str(b"test2");
        let sx = sp.retrieve_latin1_str(x);
        let sy = sp.retrieve_latin1_str(y);
        assert_eq!(sx.raw_name(), b"test1");
        assert_eq!(sy.raw_name(), b"test2");
    }

    #[test]
    fn stringpool_actually_pools() {
        let mut sp = StringPool::new();
        sp.add_latin1_str(b"test1");
        sp.add_latin1_str(b"test2");
        assert_eq!(sp.storage, b"test1test2");
    }

    #[test]
    fn stringpool_interns() {
        let mut sp = StringPool::new();
        let x = sp.add_latin1_str(b"test1");
        let y = sp.add_latin1_str(b"test1");
        assert_eq!(x, y);
        assert_eq!(sp.storage, b"test1");
    }

    #[derive(Default)]
    struct ObjPoolTestObject {
        foo: u32
    }

    #[test]
    fn objpool_basic_works() {
        let mut pool = ObjPool::<ObjPoolTestObject>::new();
        let x = pool.alloc();
        let y = pool.alloc();
        {
            let o = pool.get_mut(x);
            o.foo = 123;
        }
        {
            let o = pool.get_mut(y);
            o.foo = 456;
        }
        let ox = pool.get(x);
        let oy = pool.get(y);
        assert_eq!(ox.foo, 123);
        assert_eq!(oy.foo, 456);
    }
}
