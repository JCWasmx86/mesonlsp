#include "lexer.hpp"
#include "node.hpp"
#include "parser.hpp"
#include "sourcefile.hpp"
#include "utils.hpp"

#include <benchmark/benchmark.h>
#include <cctype>
#include <filesystem>
#include <tree_sitter/api.h>

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

extern "C" TSLanguage *tree_sitter_meson(); // NOLINT

void customParserLex(benchmark::State &state) {
  const std::filesystem::path path = "meson.build";
  const auto fileContent = readFile(path);
  for (auto _ : state) {
    Lexer lexer(fileContent);
    lexer.tokenize();
    benchmark::DoNotOptimize(&lexer.tokens);
    benchmark::ClobberMemory();
    (void)_;
  }
}

void customParserLexOnce(benchmark::State &state) {
  const std::filesystem::path path = "meson.build";
  const auto fileContent = readFile(path);
  Lexer lexer(fileContent);
  lexer.tokenize();
  for (auto _ : state) {
    auto sourceFile = std::make_shared<MemorySourceFile>(fileContent, path);
    Parser parser(lexer, sourceFile);
    auto rootNode = parser.parse(lexer.errors);
    rootNode->setParents();
    benchmark::DoNotOptimize(rootNode);
    benchmark::ClobberMemory();
    (void)_;
  }
}

void customParserParse(benchmark::State &state) {
  const std::filesystem::path path = "meson.build";
  const auto fileContent = readFile(path);
  for (auto _ : state) {
    Lexer lexer(fileContent);
    lexer.tokenize();
    auto sourceFile = std::make_shared<MemorySourceFile>(fileContent, path);
    Parser parser(lexer, sourceFile);
    auto rootNode = parser.parse(lexer.errors);
    rootNode->setParents();
    benchmark::DoNotOptimize(rootNode);
    benchmark::ClobberMemory();
    (void)_;
  }
}

void customParserParseWithoutSettingParents(benchmark::State &state) {
  const std::filesystem::path path = "meson.build";
  const auto fileContent = readFile(path);
  for (auto _ : state) {
    Lexer lexer(fileContent);
    lexer.tokenize();
    auto sourceFile = std::make_shared<MemorySourceFile>(fileContent, path);
    Parser parser(lexer, sourceFile);
    auto rootNode = parser.parse(lexer.errors);
    benchmark::DoNotOptimize(rootNode);
    benchmark::ClobberMemory();
    (void)_;
  }
}

void treeSitterParse(benchmark::State &state) {
  TSParser *parser = ts_parser_new();
  ts_parser_set_language(parser, tree_sitter_meson());
  const std::filesystem::path path = "meson.build";
  const auto fileContent = readFile(path);
  for (auto _ : state) {
    TSTree *tree = ts_parser_parse_string(parser, nullptr, fileContent.data(),
                                          (uint32_t)fileContent.length());
    auto sourceFile = std::make_shared<MemorySourceFile>(fileContent, path);
    auto rootNode = makeNode(sourceFile, ts_tree_root_node(tree));
    rootNode->setParents();
    benchmark::DoNotOptimize(rootNode);
    benchmark::ClobberMemory();
    ts_tree_delete(tree);
    (void)_;
  }
  ts_parser_delete(parser);
}

void treeSitterParseAllInLoop(benchmark::State &state) {
  const std::filesystem::path path = "meson.build";
  const auto fileContent = readFile(path);
  for (auto _ : state) {
    TSParser *parser = ts_parser_new();
    ts_parser_set_language(parser, tree_sitter_meson());
    TSTree *tree = ts_parser_parse_string(parser, nullptr, fileContent.data(),
                                          (uint32_t)fileContent.length());
    auto sourceFile = std::make_shared<MemorySourceFile>(fileContent, path);
    auto rootNode = makeNode(sourceFile, ts_tree_root_node(tree));
    rootNode->setParents();
    benchmark::DoNotOptimize(rootNode);
    benchmark::ClobberMemory();
    ts_tree_delete(tree);
    ts_parser_delete(parser);
    (void)_;
  }
}

void treeSitterParseWithoutNode(benchmark::State &state) {
  TSParser *parser = ts_parser_new();
  ts_parser_set_language(parser, tree_sitter_meson());
  const std::filesystem::path path = "meson.build";
  const auto fileContent = readFile(path);
  for (auto _ : state) {
    TSTree *tree = ts_parser_parse_string(parser, nullptr, fileContent.data(),
                                          (uint32_t)fileContent.length());
    benchmark::DoNotOptimize(tree);
    benchmark::ClobberMemory();
    ts_tree_delete(tree);
    (void)_;
  }
  ts_parser_delete(parser);
}

void treeSitterParseWithoutNodeAllInLoop(benchmark::State &state) {
  const std::filesystem::path path = "meson.build";
  const auto fileContent = readFile(path);
  for (auto _ : state) {
    TSParser *parser = ts_parser_new();
    ts_parser_set_language(parser, tree_sitter_meson());
    TSTree *tree = ts_parser_parse_string(parser, nullptr, fileContent.data(),
                                          (uint32_t)fileContent.length());
    benchmark::DoNotOptimize(tree);
    benchmark::ClobberMemory();
    ts_tree_delete(tree);
    ts_parser_delete(parser);
    (void)_;
  }
}

BENCHMARK(customParserLex);
BENCHMARK(customParserLexOnce);
BENCHMARK(customParserParse);
BENCHMARK(customParserParseWithoutSettingParents);
BENCHMARK(treeSitterParse);
BENCHMARK(treeSitterParseAllInLoop);
BENCHMARK(treeSitterParseWithoutNode);
BENCHMARK(treeSitterParseWithoutNodeAllInLoop);

BENCHMARK_MAIN();
