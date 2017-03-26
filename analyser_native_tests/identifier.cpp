#include <cassert>

#include "vhdl_analysis_identifier.h"
using namespace YaVHDL::Analyser;

int main(int argc, char **argv) {
    // Basic functionality
    {
        Identifier *test = Identifier::FromLatin1("foo", false);
        assert(test);
        assert(test->orig_name == "foo");
        assert(test->canonical_name == "foo");
        assert(test->pretty_name == "foo");
        assert(!test->is_extended_id);
        delete test;
    }
    {
        Identifier *test = Identifier::FromLatin1("FoO", false);
        assert(test);
        assert(test->orig_name == "FoO");
        assert(test->canonical_name == "foo");
        assert(test->pretty_name == "FoO");
        assert(!test->is_extended_id);
        delete test;
    }
    {
        Identifier *test = Identifier::FromLatin1("foo_", false);
        assert(test == nullptr);
    }
    {
        Identifier *test = Identifier::FromLatin1("FoO", true);
        assert(test);
        assert(test->orig_name == "FoO");
        assert(test->canonical_name == "FoO");
        assert(test->pretty_name == "FoO");
        assert(test->is_extended_id);
        delete test;
    }

    // More unusual Latin-1 tests
    {
        Identifier *test = Identifier::FromLatin1("f\xD6o", false);
        assert(test);
        assert(test->orig_name == "f\xD6o");
        assert(test->canonical_name == "f\xF6o");
        assert(test->pretty_name == "f\xC3\x96o");
        assert(!test->is_extended_id);
        delete test;
    }
    {
        Identifier *test = Identifier::FromLatin1("foo\xD7", false);
        assert(test == nullptr);
    }
    {
        Identifier *test = Identifier::FromLatin1("f\xD6o\xD7\xBC", true);
        assert(test);
        assert(test->orig_name == "f\xD6o\xD7\xBC");
        assert(test->canonical_name == "f\xD6o\xD7\xBC");
        assert(test->pretty_name == "f\xC3\x96o\xC3\x97\xC2\xBC");
        assert(test->is_extended_id);
        delete test;
    }

    // UTF-8 tests
    {
        Identifier *test = Identifier::FromUTF8("FoO", false);
        assert(test);
        assert(test->orig_name == "FoO");
        assert(test->canonical_name == "foo");
        assert(test->pretty_name == "FoO");
        assert(!test->is_extended_id);
        delete test;
    }
    {
        Identifier *test = Identifier::FromUTF8("f\xC3\x96o", false);
        assert(test);
        assert(test->orig_name == "f\xD6o");
        assert(test->canonical_name == "f\xF6o");
        assert(test->pretty_name == "f\xC3\x96o");
        assert(!test->is_extended_id);
        delete test;
    }
    {
        Identifier *test = Identifier::FromUTF8("foo\x80", true);
        assert(test == nullptr);
    }
    {
        Identifier *test = Identifier::FromUTF8("foo\xC4\x80", true);
        assert(test == nullptr);
    }
    {
        Identifier *test = Identifier::FromUTF8("f\xF0\x9F\x98\x80oo", true);
        assert(test == nullptr);
    }
}
