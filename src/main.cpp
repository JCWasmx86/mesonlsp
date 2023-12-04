#include <tree_sitter/api.h>

extern "C" TSLanguage *tree_sitter_meson();
int main(int argc, char **argv) {
  TSParser *parser = ts_parser_new();
  ts_parser_set_language(parser, tree_sitter_meson());
  ts_parser_delete(parser);
}