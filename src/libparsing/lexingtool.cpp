#include "lexer.hpp"
#include "log.hpp"
#include "utils.hpp"

#include <format>

const static Logger LOG("lexingtool") /*NOLINT*/;

int main(int argc, char **argv) {
  auto contents = readFile(argv[1]);
  auto lexer = Lexer(contents);
  auto result = lexer.tokenize();
  LOG.info(std::format("Lexing result: {}, {} tokens, {} errors", result,
                       lexer.tokens.size(), lexer.errors.size()));
  for (const auto& token : lexer.tokens) {
  }
  return 0;
}
