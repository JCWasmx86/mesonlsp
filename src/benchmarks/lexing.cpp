#include "lexer.hpp"
#include "polyfill.hpp"
#include "utils.hpp"

#include <filesystem>
#include <string>

extern "C" {
// Dirty hack
#define ast muon_ast
#define new fnew
#include <lang/lexer.h>
#include <lang/parser.h>
#include <log.h>
#include <platform/filesystem.h>
#include <platform/init.h>
#undef ast
#undef new
}

constexpr auto COUNT = 10000;

int main(int /*argc*/, char **argv) {
  std::string mode = argv[1];
  auto *file = argv[2];
  if (mode == "muon") {
    std::cerr << "UNIMPLEMENTED" << std::endl;
  } else if (mode == "custom") {
    const auto fileContent = readFile(file);
    size_t size = 0;
    for (int i = 0; i < COUNT; i++) {
      Lexer lexer(fileContent);
      lexer.tokenize();
      size = lexer.tokens.size();
    }
    std::cerr << std::format("Tokens: {}, Filesize: {} bytes, Bytes/Token: {}",
                             size, fileContent.size(),
                             (double)fileContent.size() / (double)size)
              << std::endl;
  }
}
