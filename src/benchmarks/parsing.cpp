#include "node.hpp"
#include "sourcefile.hpp"
#include "utils.hpp"

#include <benchmark/benchmark.h>
#include <filesystem>
#include <tree_sitter/api.h>

extern "C" {
// Dirty hack
#define ast muon_ast
#include <lang/parser.h>
#include <log.h>
#include <platform/filesystem.h>
#include <platform/init.h>
#undef ast
}

extern "C" TSLanguage *tree_sitter_meson(); // NOLINT

void muonParse(benchmark::State &state) {
  struct source src = {nullptr, nullptr, 0, source_reopen_type_none};
  struct muon_ast ast = {{0, 0, 0, nullptr}, {}, 0, 0};
  fs_read_entire_file("meson.build", &src);
  for (auto _ : state) {
    struct source_data sdata = {nullptr, 0};
    parser_parse(nullptr, &ast, &sdata, &src,
                 pm_ignore_statement_with_no_effect);
    benchmark::DoNotOptimize(&ast);
    benchmark::ClobberMemory();
    ast_destroy(&ast);
    source_data_destroy(&sdata);
    (void)_;
  }
  fs_source_destroy(&src);
}

void muonParseAllInLoop(benchmark::State &state) {
  for (auto _ : state) {
    struct source src = {nullptr, nullptr, 0, source_reopen_type_none};
    struct muon_ast ast = {{0, 0, 0, nullptr}, {}, 0, 0};
    fs_read_entire_file("meson.build", &src);
    struct source_data sdata = {nullptr, 0};
    parser_parse(nullptr, &ast, &sdata, &src,
                 pm_ignore_statement_with_no_effect);
    benchmark::DoNotOptimize(&ast);
    benchmark::ClobberMemory();
    ast_destroy(&ast);
    source_data_destroy(&sdata);
    fs_source_destroy(&src);
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

BENCHMARK(muonParse);
BENCHMARK(treeSitterParse);
BENCHMARK(treeSitterParseAllInLoop);
BENCHMARK(muonParseAllInLoop);
BENCHMARK(treeSitterParseWithoutNode);
BENCHMARK(treeSitterParseWithoutNodeAllInLoop);

BENCHMARK_MAIN();
