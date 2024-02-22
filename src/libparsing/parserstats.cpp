#include "lexer.hpp"
#include "node.hpp"
#include "parser.hpp"
#include "polyfill.hpp"
#include "utils.hpp"

#include <cstddef>
#include <cstdint>
#include <filesystem>
#include <format>
#include <fstream>
#include <iostream>
#include <string>
#include <vector>

class StatsExtractor : public CodeVisitor {
public:
  void visitArgumentList(ArgumentList *node) override;
  void visitArrayLiteral(ArrayLiteral *node) override;
  void visitAssignmentStatement(AssignmentStatement *node) override;
  void visitBinaryExpression(BinaryExpression *node) override;
  void visitBooleanLiteral(BooleanLiteral *node) override;
  void visitBuildDefinition(BuildDefinition *node) override;
  void visitConditionalExpression(ConditionalExpression *node) override;
  void visitDictionaryLiteral(DictionaryLiteral *node) override;
  void visitFunctionExpression(FunctionExpression *node) override;
  void visitIdExpression(IdExpression *node) override;
  void visitIntegerLiteral(IntegerLiteral *node) override;
  void visitIterationStatement(IterationStatement *node) override;
  void visitKeyValueItem(KeyValueItem *node) override;
  void visitKeywordItem(KeywordItem *node) override;
  void visitMethodExpression(MethodExpression *node) override;
  void visitSelectionStatement(SelectionStatement *node) override;
  void visitStringLiteral(StringLiteral *node) override;
  void visitSubscriptExpression(SubscriptExpression *node) override;
  void visitUnaryExpression(UnaryExpression *node) override;
  void visitErrorNode(ErrorNode *node) override;
  void visitBreakNode(BreakNode *node) override;
  void visitContinueNode(ContinueNode *node) override;
  void print() const;

private:
  uint64_t numArgumentLists = 0;
  uint64_t numArgumentListsNonNull = 0;
  uint64_t totalArgumentListsLen = 0;
  uint64_t numArrayLiterals = 0;
  uint64_t numArrayLiteralsNonNull = 0;
  uint64_t totalArrayLiteralLen = 0;
  uint64_t numDictLiterals = 0;
  uint64_t numDictLiteralsNonNull = 0;
  uint64_t totalDictLiteralLen = 0;
  uint64_t numIterationStatements = 0;
  uint64_t totalIterationStatementLen = 0;
  uint64_t numBuildDefinitions = 0;
  uint64_t totalBuildDefinitionLength = 0;
  uint64_t numSelectionStatements = 0;
  uint64_t totalNumBlocks = 0;
  uint64_t totalNumConditions = 0;
  uint64_t totalNumStmtsInBlocks = 0;
  std::vector<std::pair<size_t, size_t>> buildDefinitionSizes;
};

std::pair<double, double>
computeLinearEquation(const std::vector<std::pair<size_t, size_t>> &points) {
  size_t sumX = 0;
  size_t sumY = 0;
  size_t sumXY = 0;
  size_t sumXSquare = 0;
  size_t nPoints = points.size();

  for (const auto &[pX, pY] : points) {
    sumX += pX;
    sumY += pY;
    sumXY += pX * pY;
    sumXSquare += pX * pX;
  }

  double slope = (double)(nPoints * sumXY - sumX * sumY) /
                 (double)(nPoints * sumXSquare - sumX * sumX);
  double yIntercept = ((double)sumY - slope * (double)sumX) / (double)nPoints;

  return std::make_pair(slope, yIntercept);
}

static void print(const std::string &label, uint64_t number, uint64_t total,
                  const std::string &unit) {
  auto avg = ((double)total) / (double)number;
  std::cerr << std::format("{}: {} {} ({} {})", label, avg, unit, number, total)
            << std::endl;
}

void StatsExtractor::print() const {
  ::print("Argumentlists", numArgumentLists, totalArgumentListsLen,
          "args/list");
  ::print("Argumentlists (NN)", numArgumentListsNonNull, totalArgumentListsLen,
          "args/list");
  ::print("Array Items", numArrayLiterals, totalArrayLiteralLen, "items/array");
  ::print("Array Items (NN)", numArrayLiteralsNonNull, totalArrayLiteralLen,
          "items/array");
  ::print("Dict Items", numDictLiterals, totalDictLiteralLen, "items/dict");
  ::print("Dict Items (NN)", numDictLiterals, totalDictLiteralLen,
          "items/dict");
  ::print("ITS", numIterationStatements, totalIterationStatementLen,
          "stmts/its");
  ::print("BD", numBuildDefinitions, totalBuildDefinitionLength, "stmts/bd");
  ::print("SST (conditions)", numSelectionStatements, totalNumConditions,
          "conditions/SST");
  ::print("SST (blocks)", numSelectionStatements, totalNumBlocks, "blocks/SST");
  ::print("SST (stmts/block)", totalNumBlocks, totalNumStmtsInBlocks,
          "stmts/SST block");
  const auto &[slope, yIntercept] =
      computeLinearEquation(this->buildDefinitionSizes);
  std::cerr << std::format("f(fileSize) = {}x + {}", slope, yIntercept)
            << std::endl;
}

void StatsExtractor::visitArgumentList(ArgumentList *node) {
  node->visitChildren(this);
  numArgumentLists++;
  totalArgumentListsLen += node->args.size();
  if (!node->args.empty()) {
    numArgumentListsNonNull++;
  }
}

void StatsExtractor::visitArrayLiteral(ArrayLiteral *node) {
  node->visitChildren(this);
  numArrayLiterals++;
  if (!node->args.empty()) {
    numArrayLiteralsNonNull++;
  }
  totalArrayLiteralLen += node->args.size();
}

void StatsExtractor::visitAssignmentStatement(AssignmentStatement *node) {
  node->visitChildren(this);
}

void StatsExtractor::visitBinaryExpression(BinaryExpression *node) {
  node->visitChildren(this);
}

void StatsExtractor::visitBooleanLiteral(BooleanLiteral *node) {
  node->visitChildren(this);
}

void StatsExtractor::visitBuildDefinition(BuildDefinition *node) {
  node->visitChildren(this);
  buildDefinitionSizes.emplace_back(node->file->contents().size(),
                                    node->stmts.size());
  numBuildDefinitions++;
  totalBuildDefinitionLength += node->stmts.size();
}

void StatsExtractor::visitConditionalExpression(ConditionalExpression *node) {
  node->visitChildren(this);
}

void StatsExtractor::visitDictionaryLiteral(DictionaryLiteral *node) {
  node->visitChildren(this);
  numDictLiterals++;
  totalDictLiteralLen += node->values.size();
  if (!node->values.empty()) {
    numDictLiteralsNonNull++;
  }
}

void StatsExtractor::visitFunctionExpression(FunctionExpression *node) {
  node->visitChildren(this);
}

void StatsExtractor::visitIdExpression(IdExpression *node) {
  node->visitChildren(this);
}

void StatsExtractor::visitIntegerLiteral(IntegerLiteral *node) {
  node->visitChildren(this);
}

void StatsExtractor::visitIterationStatement(IterationStatement *node) {
  node->visitChildren(this);
  numIterationStatements++;
  totalIterationStatementLen += node->stmts.size();
}

void StatsExtractor::visitKeyValueItem(KeyValueItem *node) {
  node->visitChildren(this);
}

void StatsExtractor::visitKeywordItem(KeywordItem *node) {
  node->visitChildren(this);
}

void StatsExtractor::visitMethodExpression(MethodExpression *node) {
  node->visitChildren(this);
}

void StatsExtractor::visitSelectionStatement(SelectionStatement *node) {
  node->visitChildren(this);
  numSelectionStatements++;
  totalNumConditions += node->conditions.size();
  totalNumBlocks += node->conditions.size();
  for (const auto &block : node->blocks) {
    totalNumStmtsInBlocks += block.size();
  }
}

void StatsExtractor::visitStringLiteral(StringLiteral *node) {
  node->visitChildren(this);
}

void StatsExtractor::visitSubscriptExpression(SubscriptExpression *node) {
  node->visitChildren(this);
}

void StatsExtractor::visitUnaryExpression(UnaryExpression *node) {
  node->visitChildren(this);
}

void StatsExtractor::visitErrorNode(ErrorNode *node) {
  node->visitChildren(this);
}

void StatsExtractor::visitBreakNode(BreakNode *node) {
  node->visitChildren(this);
}

void StatsExtractor::visitContinueNode(ContinueNode *node) {
  node->visitChildren(this);
}

int main(int /*argc*/, char **argv) {
  std::filesystem::path listingsFile = argv[1];
  std::string line;
  std::ifstream inputFile(listingsFile);
  StatsExtractor extractor;
  while (std::getline(inputFile, line)) {
    auto contents = readFile(line);
    Lexer lexer(contents);
    lexer.tokenize();
    auto sourceFile = std::make_shared<MemorySourceFile>(contents, line);
    Parser parser(lexer, sourceFile);
    auto rootNode = parser.parse(lexer.errors);
    rootNode->visit(&extractor);
  }
  extractor.print();
}
