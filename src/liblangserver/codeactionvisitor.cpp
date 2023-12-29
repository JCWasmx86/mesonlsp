#include "codeactionvisitor.hpp"

#include "langserverutils.hpp"
#include "log.hpp"
#include "lsptypes.hpp"
#include "node.hpp"
#include "utils.hpp"

#include <format>

static Logger LOG("CodeActionVisitor"); // NOLINT

bool CodeActionVisitor::inRange(const Node *node, bool add) {
  auto startPos =
      LSPPosition(node->location->startLine, node->location->startColumn);
  auto endPos = LSPPosition(node->location->endLine, node->location->endColumn);
  auto nodeRange = LSPRange(startPos, endPos);
  auto pointsMatch =
      this->range.contains(startPos) || this->range.contains(endPos);
  auto rangesMatch = nodeRange.contains(this->range.start) ||
                     nodeRange.contains(this->range.end);
  if (pointsMatch || rangesMatch) {
    LOG.info("Found node at range: " + node->location->format());
    if (!add) {
      return true;
    }
    makeIntegerToBaseAction(node);
    makeCopyFileAction(node);
    makeDeclareDependencyAction(node);
    makeLibraryToGenericAction(node);
    makeSharedLibraryToModuleAction(node);
    return true;
  }
  return false;
}

void CodeActionVisitor::visitArgumentList(ArgumentList *node) {
  if (this->inRange(node)) {
    node->visitChildren(this);
  }
}

void CodeActionVisitor::visitArrayLiteral(ArrayLiteral *node) {
  if (this->inRange(node)) {
    node->visitChildren(this);
  }
}

void CodeActionVisitor::visitAssignmentStatement(AssignmentStatement *node) {
  if (this->inRange(node)) {
    node->visitChildren(this);
  }
}

void CodeActionVisitor::visitBinaryExpression(BinaryExpression *node) {
  if (this->inRange(node)) {
    node->visitChildren(this);
  }
}

void CodeActionVisitor::visitBooleanLiteral(BooleanLiteral *node) {
  if (this->inRange(node)) {
    node->visitChildren(this);
  }
}

void CodeActionVisitor::visitBuildDefinition(BuildDefinition *node) {
  if (this->inRange(node, false)) {
    node->visitChildren(this);
  }
}

void CodeActionVisitor::visitConditionalExpression(
    ConditionalExpression *node) {
  if (this->inRange(node)) {
    node->visitChildren(this);
  }
}

void CodeActionVisitor::visitDictionaryLiteral(DictionaryLiteral *node) {
  if (this->inRange(node)) {
    node->visitChildren(this);
  }
}

void CodeActionVisitor::visitFunctionExpression(FunctionExpression *node) {
  if (this->inRange(node)) {
    node->visitChildren(this);
  }
}

void CodeActionVisitor::visitIdExpression(IdExpression *node) {
  if (this->inRange(node)) {
    node->visitChildren(this);
  }
}

void CodeActionVisitor::visitIntegerLiteral(IntegerLiteral *node) {
  if (this->inRange(node)) {
    node->visitChildren(this);
  }
}

void CodeActionVisitor::visitIterationStatement(IterationStatement *node) {
  if (this->inRange(node)) {
    node->visitChildren(this);
  }
}

void CodeActionVisitor::visitKeyValueItem(KeyValueItem *node) {
  if (this->inRange(node)) {
    node->visitChildren(this);
  }
}

void CodeActionVisitor::visitKeywordItem(KeywordItem *node) {
  if (this->inRange(node)) {
    node->visitChildren(this);
  }
}

void CodeActionVisitor::visitMethodExpression(MethodExpression *node) {
  if (this->inRange(node)) {
    node->visitChildren(this);
  }
}

void CodeActionVisitor::visitSelectionStatement(SelectionStatement *node) {
  if (this->inRange(node)) {
    node->visitChildren(this);
  }
}

void CodeActionVisitor::visitStringLiteral(StringLiteral *node) {
  if (this->inRange(node)) {
    node->visitChildren(this);
  }
}

void CodeActionVisitor::visitSubscriptExpression(SubscriptExpression *node) {
  if (this->inRange(node)) {
    node->visitChildren(this);
  }
}

void CodeActionVisitor::visitUnaryExpression(UnaryExpression *node) {
  if (this->inRange(node)) {
    node->visitChildren(this);
  }
}

void CodeActionVisitor::visitErrorNode(ErrorNode *node) {
  if (this->inRange(node, false)) {
    node->visitChildren(this);
  }
}

void CodeActionVisitor::visitBreakNode(BreakNode *node) {
  if (this->inRange(node)) {
    node->visitChildren(this);
  }
}

void CodeActionVisitor::visitContinueNode(ContinueNode *node) {
  if (this->inRange(node)) {
    node->visitChildren(this);
  }
}

void CodeActionVisitor::makeCopyFileAction(const Node *node) {
  const auto *fExpr = dynamic_cast<const FunctionExpression *>(node);
  if (!fExpr) {
    return;
  }
  auto func = fExpr->function;
  if (!func || func->id() != "configure_file") {
    return;
  }
  const auto *args = dynamic_cast<const ArgumentList *>(fExpr->args.get());
  if (!args || !this->expectedArgsForCopyFile(args)) {
    return;
  }
  auto input = args->getKwarg("input").value();
  auto output = args->getKwarg("output").value();
  auto str = input->file->extractNodeValue(input->location) + ",\n" +
             output->file->extractNodeValue(output->location) + ",\n";
  for (const auto &kwargName : std::vector<std::string>{
           "install", "install_dir", "install_mode", "install_tag"}) {
    auto kwarg = args->getKwarg(kwargName);
    if (!kwarg.has_value()) {
      continue;
    }
    str += std::format(
        "{}: {},\n", kwargName,
        kwarg.value()->file->extractNodeValue(kwarg.value()->location));
  }
  std::string replacementString = "import('fs').copyfile";
  const auto varname = this->tree->scope.findVariableOfType(
      this->tree->ns.types.at("fs_module"));
  if (varname.has_value()) {
    replacementString = std::format("{}.copyfile", varname.value());
  }
  auto editArgumentList = TextEdit(nodeToRange(args), str);
  const auto fnIdNode = fExpr->id;
  auto editFunctionName =
      TextEdit(nodeToRange(fnIdNode.get()), replacementString);
  WorkspaceEdit edit;
  edit.changes[this->uri] = {editArgumentList, editFunctionName};
  this->actions.emplace_back(
      "Use fs.copyfile() instead of configure_file to copy files", edit);
}

void CodeActionVisitor::makeIntegerToBaseAction(const Node *node) {
  const auto *il = dynamic_cast<const IntegerLiteral *>(node);
  if (!il) {
    return;
  }
  auto strValue = lowercase(il->value);
  if (!strValue.starts_with("0x")) {
    this->makeActionForBase(il, "Convert to hexadecimal literal", "0x",
                            std::format("{:#x}", il->valueAsInt));
  }
  if (!strValue.starts_with("0b")) {
    this->makeActionForBase(il, "Convert to binary literal", "0b",
                            std::format("{:#b}", il->valueAsInt));
  }
  if (!strValue.starts_with("0o")) {
    this->makeActionForBase(
        il, "Convert to octal literal", "0o",
        std::format("{:#o}", il->valueAsInt)
            .substr(1)); // This adds leading 0 we want removed, as we want to
                         // have a 0o before
  }
  if (strValue.starts_with("0o") || strValue.starts_with("0x") ||
      strValue.starts_with("0b")) {
    this->makeActionForBase(il, "Convert to decimal literal", "",
                            std::format("{}", il->valueAsInt));
  }
}

void CodeActionVisitor::makeActionForBase(const IntegerLiteral *il,
                                          const std::string &title,
                                          const std::string &prefix,
                                          const std::string &val) {
  auto newValue = val.starts_with(prefix) ? val : (prefix + val);
  auto range = nodeToRange(il);
  WorkspaceEdit edit;
  edit.changes[this->uri] = {TextEdit(range, newValue)};
  this->actions.emplace_back(std::format("{} ({})", title, newValue), edit);
}

bool CodeActionVisitor::expectedArgsForCopyFile(const ArgumentList *al) {
  auto copy = al->getKwarg("copy");
  if (!copy.has_value()) {
    return false;
  }
  if (!al->getKwarg("input").has_value()) {
    return false;
  }
  if (!al->getKwarg("output").has_value()) {
    return false;
  }
  for (const auto &arg : al->args) {
    const auto *kwi = dynamic_cast<const KeywordItem *>(arg.get());
    if (!kwi) {
      return false;
    }
    auto nameOpt = kwi->name;
    if (!nameOpt.has_value()) {
      return false;
    }
    auto name = nameOpt.value();
    if (name == "copy" || name == "input" || name == "output" ||
        name == "install" || name == "install_dir" || name == "install_mode" ||
        name == "install_tag") {
      continue;
    }
    return false;
  }
  const auto *boolLit = dynamic_cast<const BooleanLiteral *>(copy->get());
  if (!boolLit) {
    return false;
  }
  return boolLit->value;
}

void CodeActionVisitor::makeLibraryToGenericAction(const Node *node) {
  const auto *fExpr = dynamic_cast<const FunctionExpression *>(node);
  if (!fExpr) {
    return;
  }
  auto name = fExpr->functionName();
  if (name != "static_library" && name != "shared_library" &&
      name != "both_libraries") {
    return;
  }
  auto range = nodeToRange(fExpr->id.get());
  WorkspaceEdit edit;
  edit.changes[this->uri] = {TextEdit(range, "library")};
  this->actions.emplace_back(std::format("Use library() instead of {}()", name),
                             edit);
}

void CodeActionVisitor::makeSharedLibraryToModuleAction(const Node *node) {
  const auto *fExpr = dynamic_cast<const FunctionExpression *>(node);
  if (!fExpr) {
    return;
  }
  auto name = fExpr->functionName();
  if (name != "shared_library") {
    return;
  }
  const auto *args = dynamic_cast<const ArgumentList *>(fExpr->args.get());
  if (!args) {
    return;
  }
  if (args->getKwarg("darwin_versions").has_value() ||
      args->getKwarg("soversion").has_value() ||
      args->getKwarg("version").has_value()) {
    return;
  }
  auto range = nodeToRange(fExpr->id.get());
  WorkspaceEdit edit;
  edit.changes[this->uri] = {TextEdit(range, "shared_module")};
  this->actions.emplace_back(
      std::format("Use shared_module() instead of shared_library()", name),
      edit);
}

void CodeActionVisitor::makeDeclareDependencyAction(const Node *node) {
  const auto *fExpr = dynamic_cast<const FunctionExpression *>(node);
  if (!fExpr) {
    return;
  }
  auto func = fExpr->function;
  if (!func || !CodeActionVisitor::createsLibrary(func)) {
    return;
  }
  auto libnameOpt = CodeActionVisitor::extractVariablename(fExpr);
  if (!libnameOpt.has_value()) {
    return;
  }
  auto libname = libnameOpt.value();
  const auto *args = dynamic_cast<const ArgumentList *>(fExpr->args.get());
  if (!args) {
    return;
  }
  std::string dependencyName;
  if (libname.size() >= 4 &&
      libname.compare(libname.size() - 4, 4, "_lib") == 0) {
    dependencyName = libname;
    dependencyName.replace(dependencyName.size() - 4, 4, "_dep");
  } else if (libname.size() >= 4 && libname.compare(0, 4, "lib_") == 0) {
    dependencyName = libname;
    dependencyName.replace(0, 4, "dep_");
  } else {
    dependencyName = "dep_" + libname;
  }
  if (this->tree->scope.variables.contains(dependencyName)) {
    return;
  }
  auto depname = "dep_" + libname;
  if (this->tree->scope.variables.contains(depname)) {
    return;
  }
  depname = libname;
  depname = replace(depname, "lib_", "dep_");
  auto tmpDepname = libname;
  replace(tmpDepname, "lib_", "dep_");
  if (this->tree->scope.variables.contains(tmpDepname) && depname != libname) {
    return;
  }
  depname = libname;
  depname = replace(depname, "_lib", "_dep");
  if (this->tree->scope.variables.contains(depname) && depname != libname) {
    return;
  }
  auto nextLine = fExpr->parent->location->endLine + 1;
  auto str = std::format("{} = declare_dependency(\n", dependencyName);
  for (const auto &kwargName : std::vector<std::string>{
           "d_import_dirs", "d_module_versions", "dependencies",
           "include_directories", "link_args", "link_whole", "link_with",
           "objects", "version"}) {
    auto kwarg = args->getKwarg(kwargName);
    if (!kwarg.has_value()) {
      if (kwargName == "link_with") {
        str += std::format("link_with: [{}],\n", libname);
      }
      continue;
    }
    if (kwargName == "link_with") {
      const auto *idExpr = dynamic_cast<const IdExpression *>(kwarg->get());
      if (idExpr) {
        str += std::format("link_with: [{}, {}],\n", idExpr->id, libname);
      }
      const auto *arrLi = dynamic_cast<const ArrayLiteral *>(kwarg->get());
      if (arrLi) {
        auto str = kwarg.value()
                       ->file->extractNodeValue(kwarg.value()->location)
                       .substr(1);
        str += std::format("link_with: [{}, {}, \n", libname, str);
      }
      continue;
    }
    str += std::format(
        "{}: {},\n", kwargName,
        kwarg.value()->file->extractNodeValue(kwarg.value()->location));
  }
  str += ")\n";
  auto range = LSPRange(LSPPosition(nextLine, 0), LSPPosition(nextLine, 0));
  auto textEdit = TextEdit(range, str);
  WorkspaceEdit edit;
  edit.changes[this->uri] = {textEdit};
  this->actions.emplace_back(
      std::format("Declare dependency {} for library", dependencyName), edit);
}
