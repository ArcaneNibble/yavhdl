#include <cassert>

#include "vhdl_analysis_scopetrait.h"
using namespace std;
using namespace YaVHDL::Analyser;
using namespace YaVHDL::Analyser::AST;

class TestScopedNode : public ScopeTrait {
    // We just need to force this into a concrete class.
};

class TestAbstractNode : public AbstractNode {
    void debug_print() {}
};

int main(int argc, char **argv) {
    // Basic tests
    {
        Identifier *id = Identifier::FromLatin1("a", true);
        TestScopedNode test;
        TestAbstractNode node1;
        test.AddItem(*id, &node1);
        delete id;
        id = Identifier::FromLatin1("a", true);
        auto result = test.FindItem(*id);
        assert(result.size() == 1);
        assert(result[0] == &node1);
        delete id;
    }
    {
        TestScopedNode test;
        TestAbstractNode node1;
        test.AddItem('a', &node1);
        auto result = test.FindItem('a');
        assert(result.size() == 1);
        assert(result[0] == &node1);
    }
    {
        TestScopedNode test;
        TestAbstractNode node1;
        test.AddItem("a", &node1);
        auto result = test.FindItem("a");
        assert(result.size() == 1);
        assert(result[0] == &node1);
    }
    // Not contaminating each other
    {
        Identifier *id = Identifier::FromLatin1("a", true);
        TestScopedNode test;
        TestAbstractNode node1;
        test.AddItem(*id, &node1);
        auto result = test.FindItem('a');
        assert(result.size() == 0);
        auto result2 = test.FindItem("a");
        assert(result2.size() == 0);
        delete id;
    }
    {
        Identifier *id = Identifier::FromLatin1("a", true);
        TestScopedNode test;
        TestAbstractNode node1;
        test.AddItem('a', &node1);
        auto result = test.FindItem(*id);
        assert(result.size() == 0);
        auto result2 = test.FindItem("a");
        assert(result2.size() == 0);
        delete id;
    }
    {
        Identifier *id = Identifier::FromLatin1("a", true);
        TestScopedNode test;
        TestAbstractNode node1;
        test.AddItem("a", &node1);
        auto result = test.FindItem(*id);
        assert(result.size() == 0);
        auto result2 = test.FindItem('a');
        assert(result2.size() == 0);
        delete id;
    }
    // Overloading test
    {
        TestScopedNode test;
        TestAbstractNode node1, node2, node3;
        test.AddItem('a', &node1);
        test.AddItem('a', &node2);
        test.AddItem('a', &node3);
        auto result = test.FindItem('a');
        assert(result.size() == 3);
        assert(result[0] == &node1);
        assert(result[1] == &node2);
        assert(result[2] == &node3);
    }
}
