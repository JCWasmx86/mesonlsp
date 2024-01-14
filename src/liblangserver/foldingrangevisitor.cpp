#include "foldingrangevisitor.hpp"

#include "node.hpp"

#include <cstddef>

void FoldingRangeVisitor::visitArgumentList(ArgumentList *node) {
  node->visitChildren(this);
}

void FoldingRangeVisitor::visitArrayLiteral(ArrayLiteral *node) {
  node->visitChildren(this);
}

void FoldingRangeVisitor::visitAssignmentStatement(AssignmentStatement *node) {
  node->visitChildren(this);
}

void FoldingRangeVisitor::visitBinaryExpression(BinaryExpression *node) {
  node->visitChildren(this);
}

void FoldingRangeVisitor::visitBooleanLiteral(BooleanLiteral *node) {
  node->visitChildren(this);
}

void FoldingRangeVisitor::visitBuildDefinition(BuildDefinition *node) {
  node->visitChildren(this);
}

void FoldingRangeVisitor::visitConditionalExpression(
    ConditionalExpression *node) {
  node->visitChildren(this);
}

void FoldingRangeVisitor::visitDictionaryLiteral(DictionaryLiteral *node) {
  node->visitChildren(this);
}

void FoldingRangeVisitor::visitFunctionExpression(FunctionExpression *node) {
  node->visitChildren(this);
}

void FoldingRangeVisitor::visitIdExpression(IdExpression *node) {
  node->visitChildren(this);
}

void FoldingRangeVisitor::visitIntegerLiteral(IntegerLiteral *node) {
  node->visitChildren(this);
}

void FoldingRangeVisitor::visitIterationStatement(IterationStatement *node) {
  node->visitChildren(this);
  if (node->stmts.empty()) {
    return;
  }
  this->ranges.emplace_back(node->location.startLine,
                            node->location.endLine - 1);
}

void FoldingRangeVisitor::visitKeyValueItem(KeyValueItem *node) {
  node->visitChildren(this);
}

void FoldingRangeVisitor::visitKeywordItem(KeywordItem *node) {
  node->visitChildren(this);
}

void FoldingRangeVisitor::visitMethodExpression(MethodExpression *node) {
  node->visitChildren(this);
}

void FoldingRangeVisitor::visitSelectionStatement(SelectionStatement *node) {
  node->visitChildren(this);

  for (size_t idx = 0; idx < node->blocks.size();) {
    auto block = node->blocks[idx];
    idx++;
    if (block.empty()) {
      continue;
    }
    auto startLine = block[0]->location.startLine - 1;
    if (idx - 1 < node->conditions.size()) {
      startLine = node->conditions[idx - 1]->location.endLine;
    }
    this->ranges.emplace_back(startLine, block.back()->location.endLine);
  }
}

void FoldingRangeVisitor::visitStringLiteral(StringLiteral *node) {
  node->visitChildren(this);
}

void FoldingRangeVisitor::visitSubscriptExpression(SubscriptExpression *node) {
  node->visitChildren(this);
}

void FoldingRangeVisitor::visitUnaryExpression(UnaryExpression *node) {
  node->visitChildren(this);
}

void FoldingRangeVisitor::visitErrorNode(ErrorNode *node) {
  node->visitChildren(this);
}

void FoldingRangeVisitor::visitBreakNode(BreakNode *node) {
  node->visitChildren(this);
}

void FoldingRangeVisitor::visitContinueNode(ContinueNode *node) {
  node->visitChildren(this);
}
