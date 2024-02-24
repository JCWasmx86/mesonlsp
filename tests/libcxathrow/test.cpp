#include <stdexcept>

__attribute__((noinline)) void f4() { throw std::runtime_error("test"); }

__attribute__((noinline)) void f3() { f4(); }

__attribute__((noinline)) void f2() { f3(); }

__attribute__((noinline)) void f1() { f2(); }

__attribute__((noinline)) void g7() { throw 1; }

__attribute__((noinline)) void g6() { g7(); }

__attribute__((noinline)) void g5() { g6(); }

__attribute__((noinline)) void g4() { g5(); }

__attribute__((noinline)) void g3() { g4(); }

__attribute__((noinline)) void g2() { g3(); }

__attribute__((noinline)) void g1() { g2(); }

int main(int /*unused*/, char ** /*unused*/) noexcept {
  try {
    f1();
  } catch (...) {
  }

  try {
    g1();
  } catch (...) {
  }
}
