#include "typenamespace.hpp"
#include <iostream>

int main(int argc, char **argv) {
  auto t = TypeNamespace();
  std::cout << (void *)&t << std::endl;
}
