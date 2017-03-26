#include <cassert>

#include "util.h"
using namespace YaVHDL::Util;

int main(int argc, char **argv) {
    assert(is_valid_basic_id("foo"));
    assert(is_valid_basic_id("foo012"));
    assert(is_valid_basic_id("foo_012"));
    assert(!is_valid_basic_id("f__oo"));
    assert(!is_valid_basic_id("foo_"));
    assert(!is_valid_basic_id("_foo"));
}
