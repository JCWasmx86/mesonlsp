#include <catch2/catch_test_macros.hpp>

// Demonstrate some basic assertions.
TEST_CASE("AddTest", "BasicAssertions") {
    REQUIRE(6 + 7 == 13);
}
