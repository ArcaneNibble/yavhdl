#include <cassert>

#include "vhdl_analysis_identifier.h"
using namespace std;
using namespace YaVHDL::Analyser;

int main(int argc, char **argv) {
    {
        Identifier *test1 = Identifier::FromLatin1("foo", false);
        Identifier *test2 = Identifier::FromLatin1("fOo", false);
        assert(test1);
        assert(test2);
        assert(*test1 == *test2);
        assert(hash<Identifier>()(*test1) == hash<Identifier>()(*test2));
        delete test1;
        delete test2;
    }
    {
        Identifier *test1 = Identifier::FromLatin1("foo", false);
        Identifier *test2 = Identifier::FromLatin1("foo", true);
        assert(test1);
        assert(test2);
        assert(*test1 != *test2);
        delete test1;
        delete test2;
    }
    {
        Identifier *test1 = Identifier::FromLatin1("foo", true);
        Identifier *test2 = Identifier::FromLatin1("foo", true);
        assert(test1);
        assert(test2);
        assert(*test1 == *test2);
        assert(hash<Identifier>()(*test1) == hash<Identifier>()(*test2));
        delete test1;
        delete test2;
    }
    {
        Identifier *test1 = Identifier::FromLatin1("foo", true);
        Identifier *test2 = Identifier::FromLatin1("fOo", true);
        assert(test1);
        assert(test2);
        assert(*test1 != *test2);
        delete test1;
        delete test2;
    }
}
