#include "lexer.hpp"
#include "log.hpp"
#include "parser.hpp"
#include "sourcefile.hpp"
#include "utils.hpp"

#include <format>
#include <memory>

const static Logger LOG("parsingtool") /*NOLINT*/;

int main(int /*argc*/, char **argv) {
  auto contents = readFile(argv[1]);
  auto sourceFile = std::make_shared<MemorySourceFile>(contents, argv[1]);
  for (size_t i = 0; i < contents.size(); i++) {
    LOG.info(std::format("Iteration ({}/{})", i, contents.size()));
    auto lexer = Lexer(contents.substr(0, i));
    lexer.tokenize();
    auto parser = Parser(lexer.tokens, sourceFile);
    parser.parse(lexer.errors);
  }
  for (size_t i = 0; i < contents.size(); i++) {
    LOG.info(std::format("Iteration ({}/{})", i, contents.size()));
    auto lexer = Lexer(contents.substr(i, 0));
    lexer.tokenize();
    auto parser = Parser(lexer.tokens, sourceFile);
    parser.parse(lexer.errors);
  }
  auto lexer = Lexer(contents);
  lexer.tokenize();
  LOG.info(std::format("Finished lexing: {} errors", lexer.errors.size()));
  for (const auto &errors : lexer.errors) {
    LOG.error(std::format("[{}:{}]: {}", errors.line + 1, errors.column,
                          errors.message));
  }
  auto parser = Parser(lexer.tokens, sourceFile);
  parser.parse(lexer.errors);
  LOG.info(std::format("Finished parsing: {} errors", parser.errors.size()));
  for (const auto &errors : parser.errors) {
    LOG.error(std::format("[{}:{}]: {}", errors.line + 1, errors.column,
                          errors.message));
  }
  return 0;
}
