#include "lexer.hpp"
#include "log.hpp"
#include "polyfill.hpp"
#include "utils.hpp"

const static Logger LOG("lexingtool") /*NOLINT*/;

int main(int /*argc*/, char **argv) {
  auto contents = readFile(argv[1]);
  for (size_t i = 0; i < contents.size(); i++) {
    auto lexer = Lexer(contents.substr(0, i));
    auto result = lexer.tokenize();
    LOG.info(std::format("At iteration {}: {} {} tokens, {} errors", i, result,
                         lexer.tokens.size(), lexer.errors.size()));
  }
  for (size_t i = 0; i < contents.size(); i++) {
    auto lexer = Lexer(contents.substr(i, 0));
    auto result = lexer.tokenize();
    LOG.info(std::format("At iteration {}: {} {} tokens, {} errors", i, result,
                         lexer.tokens.size(), lexer.errors.size()));
  }
  for (auto i = 0; i < 100; i++) {
    auto lexer = Lexer(contents);
    auto result = lexer.tokenize();
    LOG.info(std::format("Lexing result: {}, {} tokens, {} errors", result,
                         lexer.tokens.size(), lexer.errors.size()));
  }
  return 0;
}
