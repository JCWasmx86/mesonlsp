#include "mesonmetadata.hpp"
#include "optiondiagnosticvisitor.hpp"
#include "optionextractor.hpp"

#include <gtest/gtest.h>
#include <tree_sitter/api.h>

extern "C" TSLanguage *tree_sitter_meson(); // NOLINT

#define ONLY_DIAGNOSTIC                                                        \
  ASSERT_TRUE(metadata.diagnostics.size() == 1);                               \
  const auto &diags = *metadata.diagnostics.begin();                           \
  ASSERT_EQ(1, diags.second.size());                                           \
  const auto &diag = diags.second[0];

#define NO_DIAGNOSTIC ASSERT_TRUE(metadata.diagnostics.empty());

#define MAKE_SET                                                               \
  std::set<std::string> diagnostics;                                           \
  for (const auto &diags : metadata.diagnostics)                               \
    for (const auto &diag : diags.second)                                      \
      diagnostics.insert(diag.message);

MesonMetadata buildMetadata(const std::string &fileContent) {
  auto visitor = OptionExtractor();
  MesonMetadata metadata;
  auto diagnosticVisitor = OptionDiagnosticVisitor(&metadata);
  TSParser *parser = ts_parser_new();
  ts_parser_set_language(parser, tree_sitter_meson());
  TSTree *tree = ts_parser_parse_string(parser, nullptr, fileContent.data(),
                                        fileContent.length());
  const TSNode rootNode = ts_tree_root_node(tree);
  auto sourceFile =
      std::make_shared<MemorySourceFile>(fileContent, "meson.options");
  auto root = makeNode(sourceFile, rootNode);
  root->setParents();
  root->visit(&visitor);
  root->visit(&diagnosticVisitor);
  ts_tree_delete(tree);
  ts_parser_delete(parser);
  return metadata;
}

TEST(TestOptionDiagnostics, testInvalidFunctionCall) {
  auto metadata = buildMetadata("info('')");
  ONLY_DIAGNOSTIC
  ASSERT_EQ("Invalid function call in meson options file: info", diag.message);
}

TEST(TestOptionDiagnostics, testMissingArgs) {
  auto metadata = buildMetadata("option()");
  ONLY_DIAGNOSTIC
  ASSERT_EQ("Missing arguments in call to `option`", diag.message);
}

TEST(TestOptionDiagnostics, testMissingOptionName) {
  auto metadata = buildMetadata("option(test: true)");
  ONLY_DIAGNOSTIC
  ASSERT_EQ("Missing option name", diag.message);
}

TEST(TestOptionDiagnostics, testNonStringLiteralAsOptionName) {
  auto metadata = buildMetadata("option(1)");
  ONLY_DIAGNOSTIC
  ASSERT_EQ("Expected string literal", diag.message);
}

TEST(TestOptionDiagnostics, testMissingOptionTypeKwarg) {
  auto metadata = buildMetadata("option('foo')");
  ONLY_DIAGNOSTIC
  ASSERT_EQ("Missing option type kwarg", diag.message);
}

TEST(TestOptionDiagnostics, testNonStringOptionTypeKwarg) {
  auto metadata = buildMetadata("option('foo', type: 1)");
  ONLY_DIAGNOSTIC
  ASSERT_EQ("Expected option type to be a string literal", diag.message);
}

TEST(TestOptionDiagnostics, testInvalidOptionType) {
  auto metadata = buildMetadata("option('foo', type: '1')");
  ONLY_DIAGNOSTIC
  ASSERT_EQ("Unknown option type: 1", diag.message);
}

TEST(TestOptionDiagnostics, testDuplicateOptionName) {
  auto metadata = buildMetadata(
      "option('foo', type: 'string')\noption('foo', type: 'string')");
  ONLY_DIAGNOSTIC
  ASSERT_EQ("Duplicate option: foo", diag.message);
}

TEST(TestOptionDiagnostics, testUsingReserved) {
  auto metadata = buildMetadata("option('b_lto', type: 'string')");
  ONLY_DIAGNOSTIC
  ASSERT_EQ("Declaration of reserved option: b_lto", diag.message);
}

TEST(TestOptionDiagnostics, testBadOptionName) {
  auto metadata = buildMetadata("option('...', type: 'string')");
  ONLY_DIAGNOSTIC
  ASSERT_EQ("Invalid chars in name: Expected `a-z`, `A-Z`, `0-9`, `-` or `_`",
            diag.message);
}

TEST(TestOptionDiagnostics, testBadDefaultString) {
  auto metadata = buildMetadata("option('testtt', type: 'string', value: 1)");
  ONLY_DIAGNOSTIC
  ASSERT_EQ("Expected string literal", diag.message);
}

TEST(TestOptionDiagnostics, testCorrectString) {
  auto metadata = buildMetadata("option('testtt', type: 'string', value: '1')");
  NO_DIAGNOSTIC
}

TEST(TestOptionDiagnostics, testBadDefaultInteger) {
  auto metadata =
      buildMetadata("option('testtt', type: 'integer', value: 'foooooooo')");
  MAKE_SET
  ASSERT_TRUE(diagnostics.contains("Unable to parse as integer literal"));
  ASSERT_TRUE(diagnostics.contains("Unable to parse as integer"));
}

TEST(TestOptionDiagnostics, testMinGtMax) {
  auto metadata = buildMetadata(
      "option('testtt', type: 'integer', value: 3, min: 5, max: 2)");
  MAKE_SET
  ASSERT_TRUE(
      diagnostics.contains("Minimum value is greater than the maximum value"));
  ASSERT_TRUE(
      diagnostics.contains("Default value is greater than the maximum value"));
}

TEST(TestOptionDiagnostics, testMinEqMax) {
  auto metadata = buildMetadata(
      "option('testtt', type: 'integer', value: 1, min: 5, max: 5)");
  MAKE_SET
  ASSERT_TRUE(
      diagnostics.contains("Minimum value is equals to the maximum value"));
  ASSERT_TRUE(
      diagnostics.contains("Default value is lower than the minimum value"));
}

TEST(TestOptionDiagnostics, testDefaultLtMin) {
  auto metadata =
      buildMetadata("option('testtt', type: 'integer', value: -1, min: 3)");
  ONLY_DIAGNOSTIC
  ASSERT_EQ("Default value is lower than the minimum value", diag.message);
}

TEST(TestOptionDiagnostics, testDefaultGtMax) {
  auto metadata =
      buildMetadata("option('testtt', type: 'integer', value: 100, max: 3)");
  ONLY_DIAGNOSTIC
  ASSERT_EQ("Default value is greater than the maximum value", diag.message);
}

TEST(TestOptionDiagnostics, testCorrectInteger) {
  auto metadata = buildMetadata(
      "option('testtt', type: 'integer', value: 1, min: 0, max: 5000000)");
  NO_DIAGNOSTIC
}

TEST(TestOptionDiagnostics, testWeirdStuffAsBool) {
  auto metadata = buildMetadata("option('testtt', type: 'boolean', value: 1)");
  ONLY_DIAGNOSTIC
  ASSERT_EQ("Expected boolean value for boolean option", diag.message);
}

TEST(TestOptionDiagnostics, testStringAsBool) {
  auto metadata =
      buildMetadata("option('testtt', type: 'boolean', value: 'true')");
  ONLY_DIAGNOSTIC
  ASSERT_EQ("String literals as value for boolean options are deprecated.",
            diag.message);
}

TEST(TestOptionDiagnostics, testInvalidStringAsBool) {
  auto metadata =
      buildMetadata("option('testtt', type: 'boolean', value: 'true1')");
  MAKE_SET
  ASSERT_TRUE(diagnostics.contains("Expected 'true' or 'false'"));
  ASSERT_TRUE(diagnostics.contains(
      "String literals as value for boolean options are deprecated."));
}

TEST(TestOptionDiagnostics, testCorrectBool) {
  auto metadata =
      buildMetadata("option('testtt', type: 'boolean', value: true)");
  NO_DIAGNOSTIC
}

TEST(TestOptionDiagnostics, testBadDefaultFeature) {
  auto metadata = buildMetadata("option('testtt', type: 'feature', value: 1)");
  ONLY_DIAGNOSTIC
  ASSERT_EQ("Expected string", diag.message);
}

TEST(TestOptionDiagnostics, testBadDefaultFeatureState) {
  auto metadata =
      buildMetadata("option('testtt', type: 'feature', value: 'true')");
  ONLY_DIAGNOSTIC
  ASSERT_EQ("Expected one of: 'enabled', 'disabled', 'auto'", diag.message);
}

TEST(TestOptionDiagnostics, testCorrectFeature) {
  auto metadata =
      buildMetadata("option('testtt', type: 'feature', value: 'enabled')");
  NO_DIAGNOSTIC
}

TEST(TestOptionDiagnostics, testInvalidDefaultCombo) {
  auto metadata = buildMetadata("option('testtt', type: 'combo', value: 1)");
  MAKE_SET
  ASSERT_TRUE(diagnostics.contains("Expected string literal"));
  ASSERT_TRUE(diagnostics.contains("Missing 'choices' kwarg"));
}

TEST(TestOptionDiagnostics, testMissingComboChoicesKwarg) {
  auto metadata = buildMetadata("option('testtt', type: 'combo', value: '1')");
  ONLY_DIAGNOSTIC
  ASSERT_EQ("Missing 'choices' kwarg", diag.message);
}

TEST(TestOptionDiagnostics, testWeirdComboChoices) {
  auto metadata =
      buildMetadata("option('testtt', type: 'combo', value: '1', choices: 1)");
  ONLY_DIAGNOSTIC
  ASSERT_EQ("Expected array of strings", diag.message);
}

TEST(TestOptionDiagnostics, testWeirdComboChoices2) {
  auto metadata = buildMetadata(
      "option('testtt', type: 'combo', value: '1', choices: [1])");
  MAKE_SET
  ASSERT_TRUE(diagnostics.contains("Expected string literal"));
  ASSERT_TRUE(diagnostics.contains(
      "Default value is not contained in the choices array."));
}

TEST(TestOptionDiagnostics, testDuplicateComboChoices) {
  auto metadata = buildMetadata("option('testtt', type: 'combo', value: 'a', "
                                "choices: ['a', 'b', 'c', 'a'])");
  ONLY_DIAGNOSTIC
  ASSERT_EQ("Duplicate choice 'a'", diag.message);
}

TEST(TestOptionDiagnostics, testNonExistentComboChoiceAsDefault) {
  auto metadata = buildMetadata("option('testtt', type: 'combo', value: '1', "
                                "choices: ['a', 'b', 'c'])");
  ONLY_DIAGNOSTIC
  ASSERT_EQ("Default value is not contained in the choices array.",
            diag.message);
}

TEST(TestOptionDiagnostics, testCorrectCombo) {
  auto metadata = buildMetadata("option('testtt', type: 'combo', value: 'a', "
                                "choices: ['a', 'b', 'c'])");
  NO_DIAGNOSTIC
}

TEST(TestOptionDiagnostics, testBadChoices) {
  auto metadata =
      buildMetadata("option('testtt', type: 'array', value: [], choices: 1)");
  ONLY_DIAGNOSTIC
  ASSERT_EQ("Expected array literal", diag.message);
}

TEST(TestOptionDiagnostics, testBadArrayElementChoices) {
  auto metadata =
      buildMetadata("option('testtt', type: 'array', value: [], choices: [1])");
  ONLY_DIAGNOSTIC
  ASSERT_EQ("Expected string literal", diag.message);
}

TEST(TestOptionDiagnostics, testDuplicateArrayElementChoices) {
  auto metadata = buildMetadata(
      "option('testtt', type: 'array', value: [], choices: ['1', 'a', '1'])");
  ONLY_DIAGNOSTIC
  ASSERT_EQ("Duplicate choice", diag.message);
}

TEST(TestOptionDiagnostics, testArrayBadDefault) {
  auto metadata = buildMetadata(
      "option('testtt', type: 'array', value: 1, choices: ['1', 'a'])");
  ONLY_DIAGNOSTIC
  ASSERT_EQ("Expected array literal", diag.message);
}

TEST(TestOptionDiagnostics, testArrayBadDefaultArrayElement) {
  auto metadata = buildMetadata(
      "option('testtt', type: 'array', value: [1], choices: ['1', 'a'])");
  ONLY_DIAGNOSTIC
  ASSERT_EQ("Expected string literal", diag.message);
}

TEST(TestOptionDiagnostics, testInvalidArrayChoice) {
  auto metadata = buildMetadata(
      "option('testtt', type: 'array', value: ['qqq'], choices: ['1', 'a'])");
  ONLY_DIAGNOSTIC
  ASSERT_EQ("Value is not a valid choice!", diag.message);
}

TEST(TestOptionDiagnostics, testCorrectArray) {
  auto metadata = buildMetadata(
      "option('testtt', type: 'array', value: ['a'], choices: ['1', 'a'])");
  NO_DIAGNOSTIC
}

int main(int argc, char **argv) {
  testing::InitGoogleTest(&argc, argv);
  return RUN_ALL_TESTS();
}
