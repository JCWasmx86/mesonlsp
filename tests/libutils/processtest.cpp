#ifdef NDEBUG
#undef NDEBUG
#endif

#include "utils.hpp"

#include <cassert>

int main(int /*argc*/, char ** /*argv*/) {
  auto sout = captureProcessOutput("pkg-config", {"--list-all"});
  assert(sout.has_value());
  assert(sout.value().contains("curl"));
  auto sout2 = captureProcessOutput("does-not-exist-executable", {});
  assert(!sout2.has_value());
  auto sout3 = captureProcessOutput("pkg-config", {"--list-all"});
  assert(sout3.has_value());
  return 0;
}
