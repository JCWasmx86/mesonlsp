#include "lexer.hpp"
#include "utils.hpp"

#include <filesystem>
#include <format>
#include <string>

extern "C" {
// Dirty hack
#define ast muon_ast
#include <lang/lexer.h>
#include <lang/parser.h>
#include <log.h>
#include <platform/filesystem.h>
#include <platform/init.h>
#undef ast
}

constexpr auto COUNT = 10000;

int main(int /*argc*/, char **argv) {
  std::string mode = argv[1];
  auto *file = argv[2];
  if (mode == "muon") {
    struct source src = {nullptr, nullptr, 0, source_reopen_type_none};
    fs_read_entire_file(file, &src);
    size_t size = 0;
    for (int i = 0; i < COUNT; i++) {
      struct tokens toks;
      struct source_data sdata = {nullptr, 0};
      lexer_lex(&toks, &sdata, &src, (enum lexer_mode)0);
      size = toks.tok.len;
      tokens_destroy(&toks);
      source_data_destroy(&sdata);
    }
    std::cerr << std::format("Tokens: {}, Filesize: {} bytes, Bytes/Token: {}",
                             size, src.len, (double)src.len / (double)size)
              << std::endl;
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
