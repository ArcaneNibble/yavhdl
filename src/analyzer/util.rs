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

use std::fmt;

static LATIN1_LCASE_TABLE: [u8; 256] = [
    // 0x00-0x0f
    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
    0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,
    // 0x10-0x1f
    0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17,
    0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f,
    // 0x20-0x2f
    b' ', b'!', b'"', b'#', b'$', b'%', b'&', b'\'',
    b'(', b')', b'*', b'+', b',', b'-', b'.', b'/',
    // 0x30-0x3f
    b'0', b'1', b'2', b'3', b'4', b'5', b'6', b'7',
    b'8', b'9', b':', b';', b'<', b'=', b'>', b'?',
    // 0x40-0x4f
    b'@', b'a', b'b', b'c', b'd', b'e', b'f', b'g',
    b'h', b'i', b'j', b'k', b'l', b'm', b'n', b'o',
    // 0x50-0x5f
    b'p', b'q', b'r', b's', b't', b'u', b'v', b'w',
    b'x', b'y', b'z', b'[', b'\\',b']', b'^', b'_',
    // 0x60-0x6f
    b'`', b'a', b'b', b'c', b'd', b'e', b'f', b'g',
    b'h', b'i', b'j', b'k', b'l', b'm', b'n', b'o',
    // 0x70-0x7f
    b'p', b'q', b'r', b's', b't', b'u', b'v', b'w',
    b'x', b'y', b'z', b'{', b'|', b'}', b'~', 0x7f,
    // 0x80-0x8f
    0x80, 0x81, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87,
    0x88, 0x89, 0x8a, 0x8b, 0x8c, 0x8d, 0x8e, 0x8f,
    // 0x90-0x9f
    0x90, 0x91, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97,
    0x98, 0x99, 0x9a, 0x9b, 0x9c, 0x9d, 0x9e, 0x9f,
    // 0xa0-0xaf
    0xa0, 0xa1, 0xa2, 0xa3, 0xa4, 0xa5, 0xa6, 0xa7,
    0xa8, 0xa9, 0xaa, 0xab, 0xac, 0xad, 0xae, 0xaf,
    // 0xb0-0xbf
    0xb0, 0xb1, 0xb2, 0xb3, 0xb4, 0xb5, 0xb6, 0xb7,
    0xb8, 0xb9, 0xba, 0xbb, 0xbc, 0xbd, 0xbe, 0xbf,
    // 0xc0-0xcf
    0xe0, 0xe1, 0xe2, 0xe3, 0xe4, 0xe5, 0xe6, 0xe7,
    0xe8, 0xe9, 0xea, 0xeb, 0xec, 0xed, 0xee, 0xef,
    // 0xd0-0xdf
    0xf0, 0xf1, 0xf2, 0xf3, 0xf4, 0xf5, 0xf6, 0xd7,
    0xf8, 0xf9, 0xfa, 0xfb, 0xfc, 0xfd, 0xfe, 0xdf,
    // 0xe0-0xef
    0xe0, 0xe1, 0xe2, 0xe3, 0xe4, 0xe5, 0xe6, 0xe7,
    0xe8, 0xe9, 0xea, 0xeb, 0xec, 0xed, 0xee, 0xef,
    // 0xf0-0xff
    0xf0, 0xf1, 0xf2, 0xf3, 0xf4, 0xf5, 0xf6, 0xf7,
    0xf8, 0xf9, 0xfa, 0xfb, 0xfc, 0xfd, 0xfe, 0xff,
];

// Ensure this table is UTF-8!
static LATIN1_PRETTYPRINT_TABLE: [&str; 256] = [
    // 0x00-0x0f
    "␀",     "␁",     "␂",     "␃",     "␄",     "␅",     "␆",     "␇",
    "␈",     "␉",     "␊",     "␋",     "␌",     "␍",     "␎",     "␏",
    // 0x10-0x1f
    "␐",     "␑",     "␒",     "␓",     "␔",     "␕",     "␖",     "␗",
    "␘",     "␙",     "␚",     "␛",     "␜",     "␝",     "␞",     "␟",
    // 0x20-0x2f
    " ",     "!",     "\"",    "#",     "$",     "%",     "&",     "'",
    "(",     ")",     "*",     "+",     ",",     "-",     ".",     "/",
    // 0x30-0x3f
    "0",     "1",     "2",     "3",     "4",     "5",     "6",     "7",
    "8",     "9",     ":",     ";",     "<",     "=",     ">",     "?",
    // 0x40-0x4f
    "@",     "A",     "B",     "C",     "D",     "E",     "F",     "G",
    "H",     "I",     "J",     "K",     "L",     "M",     "N",     "O",
    // 0x50-0x5f
    "P",     "Q",     "R",     "S",     "T",     "U",     "V",     "W",
    "X",     "Y",     "Z",     "[",     "\\",    "]",     "^",     "_",
    // 0x60-0x6f
    "`",     "a",     "b",     "c",     "d",     "e",     "f",     "g",
    "h",     "i",     "j",     "k",     "l",     "m",     "n",     "o",
    // 0x70-0x7f
    "p",     "q",     "r",     "s",     "t",     "u",     "v",     "w",
    "x",     "y",     "z",     "{",     "|",     "}",     "~",     "␡",
    // 0x80-0x8f
    "\\x80", "\\x81", "\\x82", "\\x83", "\\x84", "\\x85", "\\x86", "\\x87",
    "\\x88", "\\x89", "\\x8a", "\\x8b", "\\x8c", "\\x8d", "\\x8e", "\\x8f",
    // 0x90-0x9f
    "\\x90", "\\x91", "\\x92", "\\x93", "\\x94", "\\x95", "\\x96", "\\x97",
    "\\x98", "\\x99", "\\x9a", "\\x9b", "\\x9c", "\\x9d", "\\x9e", "\\x9f",
    // 0xa0-0xaf
    "\\xa0", "¡",     "¢",     "£",     "¤",     "¥",     "¦",     "§",
    "¨",     "©",     "ª",     "«",     "¬",     "\\xad", "®",     "¯",
    // 0xb0-0xbf
    "°",     "±",     "²",     "³",     "´",     "µ",     "¶",     "·",
    "¸",     "¹",     "º",     "»",     "¼",     "½",     "¾",     "¿",
    // 0xc0-0xcf
    "À",     "Á",     "Â",     "Ã",     "Ä",     "Å",     "Æ",     "Ç",
    "È",     "É",     "Ê",     "Ë",     "Ì",     "Í",     "Î",     "Ï",
    // 0xd0-0xdf
    "Ð",     "Ñ",     "Ò",     "Ó",     "Ô",     "Õ",     "Ö",     "×",
    "Ø",     "Ù",     "Ú",     "Û",     "Ü",     "Ý",     "Þ",     "ß",
    // 0xe0-0xef
    "à",     "á",     "â",     "ã",     "ä",     "å",     "æ",     "ç",
    "è",     "é",     "ê",     "ë",     "ì",     "í",     "î",     "ï",
    // 0xf0-0xff
    "ð",     "ñ",     "ò",     "ó",     "ô",     "õ",     "ö",     "÷",
    "ø",     "ù",     "ú",     "û",     "ü",     "ý",     "þ",     "ÿ",
];

fn char_valid_for_basic_id(c: u8) -> bool {
    match c {
        // Upper-case letters
        0x41...0x5a => true,
        0xc0...0xd6 => true,
        0xd8...0xde => true,
        // Lower-case letters
        0x61...0x7a => true,
        0xdf...0xf6 => true,
        0xf8...0xff => true,
        // Underscore
        0x5f => true,
        // Digits
        0x30...0x39 => true,
        _ => false
    }
}

fn char_valid_for_ext_id(c: u8) -> bool {
    match c {
        // Cannot be C0 controls
        0x00...0x1f => false,
        // Cannot be C1 controls
        0x80...0x9f => false,
        // Cannot be delete
        0x7f => false,
        _ => true
    }
}

struct Latin1Str<'a> {
    bytes: &'a [u8],
}

impl<'a> Latin1Str<'a> {
    pub fn pretty_name(&self) -> String {
        let mut utf8str = String::new();
        for c in self.bytes {
            utf8str.push_str(LATIN1_PRETTYPRINT_TABLE[*c as usize]);
        }
        utf8str
    }

    pub fn valid_for_basic_id(&self) -> bool {
        // Needs to be at least one character long
        if self.bytes.len() == 0 {
            return false;
        }

        // Validate all characters
        for c in self.bytes {
            if !(char_valid_for_basic_id(*c)) {
                return false;
            }
        }

        // First character cannot be a digit or underscore
        if !(match self.bytes[0] {
            0x30...0x39 => false,
            0x5f => false,
            _ => true
        }) {
            return false;
        }

        // Cannot have consecutive underscores
        for i in 1..self.bytes.len() {
            if self.bytes[i - 1] == 0x5f && self.bytes[i] == 0x5f {
                return false;
            }
        }

        // Cannot end with an underscore
        if self.bytes[self.bytes.len() - 1] == 0x5f {
            return false;
        }

        true
    }

    pub fn valid_for_ext_id(&self) -> bool {
        // Needs to be at least one character long
        if self.bytes.len() == 0 {
            return false;
        }

        // Validate all characters
        for c in self.bytes {
            if !(char_valid_for_ext_id(*c)) {
                return false;
            }
        }

        true
    }
}

impl<'a> fmt::Display for Latin1Str<'a> {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "{}", self.pretty_name())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn latin1_pretty_name() {
        let x = Latin1Str {bytes: b"test"};
        assert_eq!(x.pretty_name(), "test");
        let x = Latin1Str {bytes: b"te\xC0st\xFE"};
        assert_eq!(x.pretty_name(), "teÀstþ");
    }

    #[test]
    fn basic_id_validator() {
        assert!((Latin1Str {bytes: b"foo"}).valid_for_basic_id());
        assert!((Latin1Str {bytes: b"foo012"}).valid_for_basic_id());
        assert!((Latin1Str {bytes: b"foo_012"}).valid_for_basic_id());
        assert!(!(Latin1Str {bytes: b"f__oo"}).valid_for_basic_id());
        assert!(!(Latin1Str {bytes: b"foo_"}).valid_for_basic_id());
        assert!(!(Latin1Str {bytes: b"_foo"}).valid_for_basic_id());
    }
}
