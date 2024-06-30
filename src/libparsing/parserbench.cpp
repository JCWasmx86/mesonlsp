

#include "lexer.hpp"
#include "parser.hpp"
#include "sourcefile.hpp"
#include "utils.hpp"

int main(int argc, char **argv) {
  auto contents = readFile(argv[1]);
  auto sourceFile = std::make_shared<MemorySourceFile>(contents, argv[1]);
  for (size_t i = 0; i < 100000; i++) {
    Lexer lexer(contents);
    lexer.tokenize();
    Parser parser(lexer, sourceFile);
    parser.parse(lexer.errors);
  }
}
