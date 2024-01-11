#include "typeanalyzer.hpp"

#include "function.hpp"
#include "log.hpp"
#include "mesonmetadata.hpp"
#include "mesonoption.hpp"
#include "node.hpp"
#include "partialinterpreter.hpp"
#include "type.hpp"
#include "typenamespace.hpp"
#include "utils.hpp"
#include "version.hpp"

#include <algorithm>
#include <cassert>
#include <cctype>
#include <cstddef>
#include <filesystem>
#include <format>
#include <map>
#include <memory>
#include <optional>
#include <ranges>
#include <set>
#include <string>
#include <utility>
#include <vector>

#define TYPE_STRING_LENGTH 12
static Logger LOG("analyze::typeanalyzer"); // NOLINT

static std::set<std::string> COMPILER_IDS = /*NOLINT*/ {
    "arm",           "armclang",   "ccomp",      "ccrx",      "clang",
    "clang-cl",      "dmd",        "emscripten", "flang",     "g95",
    "gcc",           "intel",      "intel-cl",   "icc",       "intel-llvm",
    "intel-llvm-cl", "lcc",        "llvm",       "mono",      "msvc",
    "nagfor",        "nvidia_hpc", "open64",     "pathscale", "pgi",
    "rustc",         "sun",        "c2000",      "ti",        "valac",
    "xc16",          "cython",     "nasm",       "yasm",      "ml",
    "armasm",        "mwasmarm",   "mwasmeppc",
};

static std::set<std::string> ARGUMENT_SYNTAXES /*NOLINT*/ = {"gcc", "msvc",
                                                             "gnu", ""};
static std::set<std::string> LINKER_IDS /*NOLINT*/ = {
    "ld.bfd", "ld.gold",  "ld.lld",  "ld.mold",  "ld.solaris", "ld.wasm",
    "ld64",   "ld64.lld", "link",    "lld-link", "xilink",     "optlink",
    "rlink",  "xc16-ar",  "ar2000",  "ti-ar",    "armlink",    "pgi",
    "nvlink", "ccomp",    "mwldarm", "mwldeppc",
};

static std::set<std::string> CPU_FAMILIES /*NOLINT*/ = {
    "aarch64", "alpha",      "arc",    "arm",    "avr",     "c2000",
    "csky",    "dspic",      "e2k",    "ft32",   "ia64",    "loongarch64",
    "m68k",    "microblaze", "mips",   "mips32", "mips64",  "msp430",
    "parisc",  "pic24",      "ppc",    "ppc64",  "riscv32", "riscv64",
    "rl78",    "rx",         "s390",   "s390x",  "sh4",     "sparc",
    "sparc64", "wasm32",     "wasm64", "x86",    "x86_64",
};

static std::set<std::string> OS_NAMES /*NOLINT*/ = {
    "android", "cygwin", "darwin", "dragonfly", "emscripten", "freebsd", "gnu",
    "haiku",   "linux",  "netbsd", "openbsd",   "windows",    "sunos",
};

static std::set<std::string> PURE_FUNCTIONS /*NOLINT*/ = {
    "disabler",
    "environment",
    "files",
    "generator",
    "get_variable",
    "import",
    "include_directories",
    "is_disabler",
    "is_variable",
    "join_paths",
    "structured_sources",
};

static std::set<std::string> PURE_METHODS /* NOLINT */ = {
    "build_machine.cpu",
    "build_machine.cpu_family",
    "build_machine.endian",
    "build_machine.system",
    "meson.backend",
    "meson.build_options",
    "meson.build_root",
    "meson.can_run_host_binaries",
    "meson.current_build_dir",
    "meson.current_source_dir",
    "meson.get_cross_property",
    "meson.get_external_property",
    "meson.global_build_root",
    "meson.global_source_root",
    "meson.has_exe_wrapper",
    "meson.has_external_property",
    "meson.is_cross_build",
    "meson.is_subproject",
    "meson.is_unity",
    "meson.project_build_root",
    "meson.project_license",
    "meson.project_license_files",
    "meson.project_name",
    "meson.project_source_root",
    "meson.project_version",
    "meson.source_root",
    "meson.version",
    "both_libs.get_shared_lib",
    "both_libs.get_static_lib",
    "build_tgt.extract_all_objects",
    "build_tgt.extract_objects",
    "build_tgt.found",
    "build_tgt.full_path",
    "build_tgt.full_path",
    "build_tgt.name",
    "build_tgt.path",
    "build_tgt.private_dir_include",
    "cfg_data.get",
    "cfg_data.get_unquoted",
    "cfg_data.has",
    "cfg_data.keys",
    "custom_idx.full_path",
    "custom_tgt.full_path",
    "custom_tgt.to_list",
    "dep.as_link_whole",
    "dep.as_system",
    "dep.found",
    "dep.get_configtool_variable",
    "dep.get_pkgconfig_variable",
    "dep.get_variable",
    "dep.include_type",
    "dep.name",
    "dep.partial_dependency",
    "dep.type_name",
    "dep.version",
    "disabler.found",
    "external_program.found",
    "external_program.full_path",
    "external_program.path",
    "external_program.version",
    "feature.allowed",
    "feature.auto",
    "feature.disabled",
    "feature.enabled",
    "module.found",
    "runresult.compiled",
    "runresult.returncode",
    "runresult.stderr",
    "runresult.stdout",
    "subproject.found",
    "subproject.get_variable",
    "str.contains",
    "str.endswith",
    "str.format",
    "str.join",
    "str.replace",
    "str.split",
    "str.startswith",
    "str.strip",
    "str.substring",
    "str.to_lower",
    "str.to_upper",
    "str.underscorify",
    "str.version_compare",
    "bool.to_int",
    "bool.to_string",
    "dict.get",
    "dict.has_key",
    "dict.keys",
    "int.even",
    "int.is_odd",
    "int.to_string",
    "list.contains",
    "list.get",
    "list.length",
};

static std::vector<std::shared_ptr<Type>>
dedup(const TypeNamespace &ns, std::vector<std::shared_ptr<Type>> types);
static bool isSnakeCase(const std::string &str);
static bool isShoutingSnakeCase(const std::string &str);
static bool isType(const std::shared_ptr<Type> &type, const std::string &name);
static bool sameType(const std::shared_ptr<Type> &first,
                     const std::shared_ptr<Type> &second,
                     const std::string &name);

void TypeAnalyzer::applyToStack(const std::string &name,
                                std::vector<std::shared_ptr<Type>> types) {
  if (this->stack.empty()) {
    return;
  }
  if (this->scope.variables.contains(name)) {
    auto orVCount = this->overriddenVariables.size() - 1;
    auto &atIdx = this->overriddenVariables[orVCount];
    const auto &vars = this->scope.variables[name];
    if (atIdx.contains(name)) {
      atIdx[name].insert(atIdx[name].begin(), vars.begin(), vars.end());
    } else {
      atIdx[name] = vars;
    }
  }
  auto ssc = this->stack.size() - 1;
  if (this->stack[ssc].contains(name)) {
    auto &old = this->stack[ssc][name];
    old.insert(old.end(), types.begin(), types.end());
  } else {
    this->stack[ssc][name] = types;
  }
}

void TypeAnalyzer::visitArgumentList(ArgumentList *node) {
  node->visitChildren(this);
}

void TypeAnalyzer::visitArrayLiteral(ArrayLiteral *node) {
  node->visitChildren(this);
  std::vector<std::shared_ptr<Type>> types;
  for (const auto &arg : node->args) {
    for (const auto &type : arg->types) {
      types.emplace_back(type);
    }
  }
  node->types = std::vector<std::shared_ptr<Type>>{
      std::make_shared<List>(dedup(this->ns, types))};
}

void TypeAnalyzer::extractVoidAssignment(AssignmentStatement *node) const {
  std::string name;
  auto *fe = dynamic_cast<FunctionExpression *>(node->rhs.get());
  if (fe && fe->function) {
    name = fe->function->id();
  } else {
    auto *me = dynamic_cast<MethodExpression *>(node->rhs.get());
    if (me && me->method) {
      name = me->method->id();
    }
  }
  if (!name.starts_with("install_")) {
    this->metadata->registerDiagnostic(
        node->lhs.get(),
        Diagnostic(Severity::Error, node->lhs.get(), "Can't assign from void"));
  }
}

void TypeAnalyzer::checkIdentifier(IdExpression *node) const {
  if (this->analysisOptions.disableNameLinting) {
    return;
  }
  if (isSnakeCase(node->id) || isShoutingSnakeCase(node->id)) {
    return;
  }
  this->metadata->registerDiagnostic(
      node, Diagnostic(Severity::Warning, node, "Expected snake case"));
}

void TypeAnalyzer::evaluatePureAssignment(AssignmentStatement *node,
                                          IdExpression *lhsIdExpr) {
  auto arr = node->rhs->types;
  if (arr.empty()) {
    auto *arrLit = dynamic_cast<ArrayLiteral *>(node->rhs.get());
    if (arrLit && arrLit->args.empty()) {
      arr = {std::make_shared<List>(std::vector<std::shared_ptr<Type>>{})};
    }
    auto *dictLit = dynamic_cast<DictionaryLiteral *>(node->rhs.get());
    if (dictLit && dictLit->values.empty()) {
      arr = {std::make_shared<Dict>(std::vector<std::shared_ptr<Type>>{})};
    }
  }
  const auto &assignmentName = lhsIdExpr->id;
  if (assignmentName == "meson" || assignmentName == "build_machine" ||
      assignmentName == "target_machine" || assignmentName == "host_machine") {
    this->metadata->registerDiagnostic(
        lhsIdExpr,
        Diagnostic(Severity::Error, lhsIdExpr,
                   "Attempted to re-assign to existing, read-only variable"));
    return;
  }
  lhsIdExpr->types = arr;
  this->checkIdentifier(lhsIdExpr);
  this->applyToStack(lhsIdExpr->id, arr);
  this->scope.variables[lhsIdExpr->id] = arr;
  this->registerNeedForUse(lhsIdExpr);
}

void TypeAnalyzer::registerNeedForUse(IdExpression *node) {
  this->variablesNeedingUse.back().push_back(node);
}

std::optional<std::shared_ptr<Type>>
TypeAnalyzer::evalPlusEquals(const std::shared_ptr<Type> &left,
                             const std::shared_ptr<Type> &right) {
  if (dynamic_cast<IntType *>(left.get()) &&
      dynamic_cast<IntType *>(right.get())) {
    return this->ns.intType;
  }
  if (dynamic_cast<Str *>(left.get()) && dynamic_cast<Str *>(right.get())) {
    return this->ns.strType;
  }
  auto *listL = dynamic_cast<List *>(left.get());
  if (listL) {
    auto *listR = dynamic_cast<List *>(right.get());
    auto newTypes = listL->types;
    if (listR) {
      auto rTypes = listR->types;
      newTypes.insert(newTypes.end(), rTypes.begin(), rTypes.end());
    } else {
      newTypes.emplace_back(right);
    }
    return std::make_shared<List>(dedup(this->ns, newTypes));
  }
  auto *dictL = dynamic_cast<Dict *>(left.get());
  if (dictL) {
    auto *dictR = dynamic_cast<Dict *>(right.get());
    auto newTypes = dictL->types;
    if (dictR) {
      auto rTypes = dictR->types;
      newTypes.insert(newTypes.end(), rTypes.begin(), rTypes.end());
    } else {
      newTypes.emplace_back(right);
    }
    return std::make_shared<Dict>(dedup(this->ns, newTypes));
  }
  return std::nullopt;
}

void TypeAnalyzer::evalAssignmentTypes(
    const std::shared_ptr<Type> &left, const std::shared_ptr<Type> &right,
    AssignmentOperator op, std::vector<std::shared_ptr<Type>> *newTypes) {
  switch (op) {
  case DivEquals:
    if (dynamic_cast<IntType *>(left.get()) &&
        dynamic_cast<IntType *>(right.get())) {
      newTypes->push_back(this->ns.intType);
    }
    if (dynamic_cast<Str *>(left.get()) && dynamic_cast<Str *>(right.get())) {
      newTypes->push_back(this->ns.strType);
    }
    break;
  case MinusEquals:
  case ModEquals:
  case MulEquals:
    if (dynamic_cast<IntType *>(left.get()) &&
        dynamic_cast<IntType *>(right.get())) {
      newTypes->push_back(this->ns.intType);
    }
    break;
  case PlusEquals: {
    auto type = this->evalPlusEquals(left, right);
    if (type.has_value()) {
      newTypes->push_back(type.value());
    }
    break;
  }
  default:
    break;
  }
}

std::vector<std::shared_ptr<Type>>
TypeAnalyzer::evalAssignment(AssignmentOperator op,
                             const std::vector<std::shared_ptr<Type>> &lhs,
                             const std::vector<std::shared_ptr<Type>> &rhs) {
  std::vector<std::shared_ptr<Type>> ret;
  for (const auto &left : lhs) {
    for (const auto &right : rhs) {
      this->evalAssignmentTypes(left, right, op, &ret);
    }
  }
  return ret;
}

void TypeAnalyzer::evaluateFullAssignment(AssignmentStatement *node,
                                          IdExpression *lhsIdExpr) {
  this->metadata->registerIdentifier(lhsIdExpr);
  if (node->op == AssignmentOperator::Equals) {
    this->evaluatePureAssignment(node, lhsIdExpr);
    return;
  }
  const auto &newTypes =
      dedup(this->ns,
            this->evalAssignment(node->op, node->lhs->types, node->rhs->types));
  lhsIdExpr->types = newTypes;
  this->applyToStack(lhsIdExpr->id, newTypes);
  this->scope.variables[lhsIdExpr->id] = newTypes;
}

void TypeAnalyzer::visitAssignmentStatement(AssignmentStatement *node) {
  node->visitChildren(this);
  auto *idExpr = dynamic_cast<IdExpression *>(node->lhs.get());
  if (!idExpr) {
    this->metadata->registerDiagnostic(
        node->lhs.get(), Diagnostic(Severity::Error, node->lhs.get(),
                                    "Can only assign to variables"));
    return;
  }
  if (node->op == AssignmentOpOther) {
    this->metadata->registerDiagnostic(
        node->lhs.get(), Diagnostic(Severity::Error, node->lhs.get(),
                                    "Unknown assignment operator"));
    return;
  }
  auto rhsTypes = node->rhs->types;
  if (rhsTypes.empty() &&
      (dynamic_cast<FunctionExpression *>(node->rhs.get()) ||
       dynamic_cast<MethodExpression *>(node->rhs.get()))) {
    this->metadata->registerIdentifier(idExpr);
    this->extractVoidAssignment(node);
    return;
  }
  this->evaluateFullAssignment(node, idExpr);
}

bool TypeAnalyzer::isSpecial(std::vector<std::shared_ptr<Type>> &types) {
  if (types.size() != 3) {
    return false;
  }
  auto counter = 0;
  for (const auto &type : types) {
    if (dynamic_cast<Any *>(type.get())) {
      counter++;
      continue;
    }
    auto *asList = dynamic_cast<List *>(type.get());
    if (asList && asList->types.size() == 1 &&
        dynamic_cast<Any *>(asList->types[0].get())) {
      counter++;
      continue;
    }
    auto *asDict = dynamic_cast<Dict *>(type.get());
    if (asDict && asDict->types.size() == 1 &&
        dynamic_cast<Any *>(asDict->types[0].get())) {
      counter++;
      continue;
    }
    return false;
  }
  return counter == 3;
}

std::vector<std::shared_ptr<Type>> TypeAnalyzer::evalBinaryExpression(
    BinaryOperator op, std::vector<std::shared_ptr<Type>> lhs,
    const std::vector<std::shared_ptr<Type>> &rhs, unsigned int *numErrors) {
  std::vector<std::shared_ptr<Type>> newTypes;
  for (const auto &lType : lhs) {
    for (const auto &rType : rhs) {
      if (rType->name == "any" && lType->name == "any") {
        ++*numErrors;
        continue;
      }
      switch (op) {
      case And:
      case Or:
        if (sameType(lType, rType, "bool")) {
          newTypes.emplace_back(this->ns.boolType);
        } else {
          ++*numErrors;
        }
        break;
      case Div:
        if (sameType(lType, rType, "int")) {
          newTypes.emplace_back(this->ns.intType);
        } else if (sameType(lType, rType, "str")) {
          newTypes.emplace_back(this->ns.strType);
        } else {
          ++*numErrors;
        }
        break;
      case EqualsEquals:
      case NotEquals:
        if (sameType(lType, rType, "int") || sameType(lType, rType, "str") ||
            sameType(lType, rType, "bool") || sameType(lType, rType, "dict") ||
            sameType(lType, rType, "list") ||
            ((dynamic_cast<AbstractObject *>(lType.get()) != nullptr) &&
             lType->name == rType->name)) {
          newTypes.emplace_back(this->ns.boolType);
        } else {
          ++*numErrors;
        }
        break;
      case Ge:
      case Gt:
      case Le:
      case Lt:
        if (sameType(lType, rType, "int") || sameType(lType, rType, "str")) {
          newTypes.emplace_back(this->ns.boolType);
        } else {
          ++*numErrors;
        }
        break;
      case In:
      case NotIn:
        newTypes.emplace_back(this->ns.boolType);
        break;
      case Minus:
      case Modulo:
      case Mul:
        if (sameType(lType, rType, "int")) {
          newTypes.emplace_back(this->ns.intType);
        } else {
          ++*numErrors;
        }
        break;
      case Plus: {
        if (sameType(lType, rType, "int") || sameType(lType, rType, "str")) {
          newTypes.emplace_back(this->ns.types.at(lType->name));
          break;
        }
        auto *list1 = dynamic_cast<List *>(lType.get());
        auto *list2 = dynamic_cast<List *>(rType.get());
        if (list1) {
          auto types = list1->types;
          if (list2) {
            types.insert(types.end(), list2->types.begin(), list2->types.end());
          } else {
            types.push_back(rType);
          }
          newTypes.emplace_back(std::make_shared<List>(types));
          break;
        }
        auto *dict1 = dynamic_cast<Dict *>(lType.get());
        auto *dict2 = dynamic_cast<Dict *>(rType.get());
        if (dict1 && dict2) {
          auto types = dict1->types;
          types.insert(types.end(), dict2->types.begin(), dict2->types.end());
          newTypes.emplace_back(std::make_shared<Dict>(types));
          break;
        }
        ++*numErrors;
        break;
      }
      case BinOpOther:
      default:
        LOG.error("Whoops???");
        ++*numErrors;
        break;
      }
    }
  }
  if (*numErrors == lhs.size() * rhs.size()) {
    return lhs;
  }
  return newTypes;
}

void TypeAnalyzer::visitBinaryExpression(BinaryExpression *node) {
  node->visitChildren(this);
  if (node->op == BinaryOperator::BinOpOther) {
    auto types = node->lhs->types;
    types.insert(types.end(), node->rhs->types.begin(), node->rhs->types.end());
    node->types = types;
    this->metadata->registerDiagnostic(
        node, Diagnostic(Severity::Error, node, "Unknown operator"));
    return;
  }
  auto nErrors = 0U;
  auto newTypes = this->evalBinaryExpression(node->op, node->lhs->types,
                                             node->rhs->types, &nErrors);
  auto nTimes = node->lhs->types.size() * node->rhs->types.size();
  if (nTimes != 0 && nErrors == nTimes && (!node->lhs->types.empty()) &&
      (!node->rhs->types.empty()) && !this->isSpecial(node->lhs->types) &&
      !this->isSpecial(node->rhs->types)) {
    auto lTypes = joinTypes(node->lhs->types);
    auto rTypes = joinTypes(node->rhs->types);
    auto msg = std::format("Unable to apply operator {} to types {} and {}",
                           enum2String(node->op), lTypes, rTypes);
    this->metadata->registerDiagnostic(node,
                                       Diagnostic(Severity::Error, node, msg));
  }
  node->types = dedup(this->ns, newTypes);
  auto *parent = node->parent;
  if (dynamic_cast<AssignmentStatement *>(parent) ||
      dynamic_cast<SelectionStatement *>(parent)) {
    auto *me = dynamic_cast<MethodExpression *>(node->lhs.get());
    auto *sl = dynamic_cast<StringLiteral *>(node->rhs.get());
    if (me && sl) {
      this->checkIfSpecialComparison(me, sl);
      return;
    }
    me = dynamic_cast<MethodExpression *>(node->rhs.get());
    sl = dynamic_cast<StringLiteral *>(node->lhs.get());
    if (me && sl) {
      this->checkIfSpecialComparison(me, sl);
      return;
    }
  }
}

void TypeAnalyzer::checkIfSpecialComparison(MethodExpression *me,
                                            StringLiteral *sl) const {
  if (this->analysisOptions.disableAllIdLinting) {
    return;
  }
  auto method = me->method;
  if (!method) {
    return;
  }
  const auto &mid = method->id();
  const auto &arg = sl->id;
  if (mid == "compiler.get_id" &&
      !this->analysisOptions.disableCompilerIdLinting &&
      !COMPILER_IDS.contains(arg)) {
    this->metadata->registerDiagnostic(
        sl, Diagnostic(Severity::Warning, sl, "Unknown compiler id"));
  } else if (mid == "compiler.get_argument_syntax" &&
             !this->analysisOptions.disableCompilerArgumentIdLinting &&
             !ARGUMENT_SYNTAXES.contains(arg)) {
    this->metadata->registerDiagnostic(
        sl,
        Diagnostic(Severity::Warning, sl, "Unknown compiler argument syntax"));
  } else if (mid == "compiler.get_linker_id" &&
             !this->analysisOptions.disableLinkerIdLinting &&
             !LINKER_IDS.contains(arg)) {
    this->metadata->registerDiagnostic(
        sl, Diagnostic(Severity::Warning, sl, "Unknown linker id"));
  } else if (mid == "build_machine.cpu_family" &&
             !this->analysisOptions.disableCpuFamilyLinting &&
             !CPU_FAMILIES.contains(arg)) {
    this->metadata->registerDiagnostic(
        sl, Diagnostic(Severity::Warning, sl, "Unknown CPU family"));
  } else if (mid == "build_machine.system" &&
             !this->analysisOptions.disableOsFamilyLinting &&
             !OS_NAMES.contains(arg)) {
    this->metadata->registerDiagnostic(
        sl, Diagnostic(Severity::Warning, sl, "Unknown OS family"));
  }
}

void TypeAnalyzer::visitBooleanLiteral(BooleanLiteral *node) {
  node->visitChildren(this);
  node->types.emplace_back(this->ns.boolType);
}

void TypeAnalyzer::checkProjectCall(BuildDefinition *node) {
  if (this->sourceFileStack.size() != 1) {
    return;
  }
  if (node->stmts.empty()) {
    this->metadata->registerDiagnostic(
        node, Diagnostic(Severity::Error, node,
                         "Missing project() call at top of file"));
    return;
  }
  auto first = node->stmts[0];
  auto *asCall = dynamic_cast<FunctionExpression *>(first.get());
  if (asCall == nullptr || asCall->functionName() != "project") {
    this->metadata->registerDiagnostic(
        node, Diagnostic(Severity::Error, node,
                         "Missing project() call at top of file"));
    return;
  }
  auto alNode = asCall->args;
  if (!alNode) {
    return;
  }
  auto *al = dynamic_cast<ArgumentList *>(alNode.get());
  if (!al) {
    return;
  }
  auto mesonVersionKwarg = al->getKwarg("meson_version");
  if (!mesonVersionKwarg) {
    return;
  }
  auto *mesonVersionSL =
      dynamic_cast<StringLiteral *>(mesonVersionKwarg->get());
  if (!mesonVersionSL) {
    return;
  }
  LOG.info(std::format("Meson version = {}", mesonVersionSL->id));
  auto subStr = 0;
  for (const auto chr : mesonVersionSL->id) {
    if (chr == '>' || chr == '=' || chr == '<' || chr == ' ') {
      subStr++;
      continue;
    }
    break;
  }
  this->tree->version = Version(mesonVersionSL->id.substr(subStr));
}

void TypeAnalyzer::checkNoEffect(Node *node) const {
  auto noEffect = false;
  if (dynamic_cast<IntegerLiteral *>(node) ||
      dynamic_cast<StringLiteral *>(node) ||
      dynamic_cast<BooleanLiteral *>(node) ||
      dynamic_cast<ArrayLiteral *>(node) ||
      dynamic_cast<DictionaryLiteral *>(node)) {
    noEffect = true;
    goto end;
  }
  if (auto *fe = dynamic_cast<FunctionExpression *>(node)) {
    auto fnid = fe->function;
    if (fnid && PURE_FUNCTIONS.contains(fnid->name)) {
      noEffect = true;
      goto end;
    }
    return;
  }
  if (auto *me = dynamic_cast<MethodExpression *>(node)) {
    auto method = me->method;
    if (method && PURE_METHODS.contains(method->id())) {
      noEffect = true;
      goto end;
    }
    return;
  }
  return;
end:
  if (!noEffect) {
    return;
  }
  this->metadata->registerDiagnostic(
      node, Diagnostic(Severity::Warning, node,
                       "Statement does not have an effect or the result to the "
                       "call is unused"));
}

bool TypeAnalyzer::isDead(const std::shared_ptr<Node> &node) {
  auto *asFuncExpr = dynamic_cast<FunctionExpression *>(node.get());
  if (!asFuncExpr) {
    return false;
  }
  const auto &name = asFuncExpr->functionName();
  return name == "error" || name == "subdir_done";
}

void TypeAnalyzer::applyDead(std::shared_ptr<Node> &lastAlive,
                             std::shared_ptr<Node> &firstDead,
                             std::shared_ptr<Node> &lastDead) const {
  if (!lastAlive || !firstDead || !lastDead) {
    return;
  }
  if (!lastAlive.get() || !firstDead.get() || !lastDead.get()) {
    return;
  }
  this->metadata->registerDiagnostic(
      firstDead.get(), Diagnostic(Severity::Warning, firstDead.get(),
                                  lastDead.get(), "Dead code", false, true));
}

void TypeAnalyzer::checkDeadNodes(BuildDefinition *node) {
  std::shared_ptr<Node> lastAlive = nullptr;
  std::shared_ptr<Node> firstDead = nullptr;
  std::shared_ptr<Node> lastDead = nullptr;
  for (const auto &stmt : node->stmts) {
    this->checkNoEffect(stmt.get());
    if (!lastAlive) {
      if (this->isDead(stmt)) {
        lastAlive = stmt;
      }
    } else {
      if (!firstDead) {
        firstDead = stmt;
        lastDead = stmt;
      } else {
        lastDead = stmt;
      }
    }
  }
  this->applyDead(lastAlive, firstDead, lastDead);
}

void TypeAnalyzer::checkUnusedVariables() {
  auto needingUse = this->variablesNeedingUse.back();
  this->variablesNeedingUse.pop_back();
  if (!this->variablesNeedingUse.empty()) {
    auto toAppend = this->variablesNeedingUse.back();
    toAppend.insert(toAppend.end(), needingUse.begin(), needingUse.end());
    this->variablesNeedingUse.back() = toAppend;
    return;
  }
  for (auto *needed : needingUse) {
    auto *ass = dynamic_cast<AssignmentStatement *>(needed->parent);
    if (!ass) {
      continue;
    }
    auto *rhs = dynamic_cast<FunctionExpression *>(ass->rhs.get());
    if (rhs) {
      const auto &fnid = rhs->functionName();
      if (fnid == "declare_dependency") {
        continue;
      }
    }
    this->metadata->registerDiagnostic(
        needed, Diagnostic(Severity::Warning, needed, "Unused assignment"));
  }
}

void TypeAnalyzer::visitBuildDefinition(BuildDefinition *node) {
  this->variablesNeedingUse.emplace_back();
  this->sourceFileStack.push_back(node->file->file);
  this->tree->ownedFiles.insert(node->file->file);
  this->checkProjectCall(node);
  node->visitChildren(this);
  this->checkDeadNodes(node);
  this->checkUnusedVariables();
  this->sourceFileStack.pop_back();
}

void TypeAnalyzer::visitConditionalExpression(ConditionalExpression *node) {
  node->visitChildren(this);
  std::vector<std::shared_ptr<Type>> types(node->ifTrue->types);
  types.insert(types.end(), node->ifFalse->types.begin(),
               node->ifFalse->types.end());
  node->types = types;
  for (const auto &type : node->condition->types) {
    if (dynamic_cast<Any *>(type.get())) {
      return;
    }
    if (dynamic_cast<BoolType *>(type.get())) {
      return;
    }
    if (dynamic_cast<Disabler *>(type.get())) {
      return;
    }
  }
  this->metadata->registerDiagnostic(
      node, Diagnostic(Severity::Error, node,
                       "Condition is not bool: " +
                           joinTypes(node->condition->types)));
}

void TypeAnalyzer::checkDuplicateNodeKeys(DictionaryLiteral *node) const {
  std::set<std::string> seenKeys;
  for (const auto &keyV : node->values) {
    auto *asKVI = dynamic_cast<KeyValueItem *>(keyV.get());
    if (!asKVI) {
      continue;
    }
    auto *keyNode = dynamic_cast<StringLiteral *>(asKVI->key.get());
    if (!keyNode) {
      continue;
    }
    const auto &keyName = keyNode->id;
    if (!seenKeys.contains(keyName)) {
      seenKeys.insert(keyName);
      continue;
    }
    this->metadata->registerDiagnostic(
        keyNode, Diagnostic(Severity::Warning, keyNode,
                            std::format("Duplicate key \"{}\"", keyName)));
  }
}

void TypeAnalyzer::visitDictionaryLiteral(DictionaryLiteral *node) {
  node->visitChildren(this);
  std::vector<std::shared_ptr<Type>> types;
  for (const auto &arg : node->values) {
    for (const auto &type : arg->types) {
      types.emplace_back(type);
    }
  }
  node->types = std::vector<std::shared_ptr<Type>>{
      std::make_shared<Dict>(dedup(this->ns, types))};
  this->checkDuplicateNodeKeys(node);
}

void TypeAnalyzer::setFunctionCallTypes(FunctionExpression *node,
                                        const std::shared_ptr<Function> &func) {
  const auto &name = func->name;
  if (name == "subproject") {
    const auto &values = ::guessSetVariable(node, this->options);
    if (values.empty()) {
      return;
    }
    std::set<std::string> asSet{values.begin(), values.end()};
    node->types = {std::make_shared<Subproject>(
        std::vector<std::string>{asSet.begin(), asSet.end()})};
    LOG.info("Values for `subproject` call: " + joinStrings(asSet, '|'));
    if (!this->tree->state->used || asSet.size() > 1) {
      return;
    }
    auto *subprojState = this->tree->state;
    if (subprojState->hasSubproject(*asSet.begin())) {
      return;
    }
    this->metadata->registerDiagnostic(
        node,
        Diagnostic(Severity::Error, node,
                   std::format("Unknown subproject `{}`", *asSet.begin())));
    return;
  }
  if (name == "get_option") {
    const auto &values = ::guessSetVariable(node, this->options);
    std::set<std::string> const asSet{values.begin(), values.end()};
    std::vector<std::shared_ptr<Type>> types;
    for (auto val : asSet) {
      auto opt = this->options.findOption(val);
      if (!opt) {
        if (asSet.size() > 1) {
          continue;
        }
        this->metadata->registerDiagnostic(
            node, Diagnostic(Severity::Error, node,
                             std::format("Unknown option `{}`", val)));
        continue;
      }
      if (asSet.size() == 1 && opt->deprecated) {
        this->metadata->registerDiagnostic(
            node, Diagnostic(Severity::Warning, node,
                             std::format("Deprecated option"), true, false));
      }
      if (dynamic_cast<StringOption *>(opt.get()) ||
          dynamic_cast<ComboOption *>(opt.get())) {
        types.emplace_back(this->ns.strType);
        continue;
      }
      if (dynamic_cast<IntOption *>(opt.get())) {
        types.emplace_back(this->ns.intType);
        continue;
      }
      if (dynamic_cast<BoolOption *>(opt.get())) {
        types.emplace_back(this->ns.boolType);
        continue;
      }
      if (dynamic_cast<FeatureOption *>(opt.get())) {
        types.emplace_back(this->ns.types.at("feature"));
        continue;
      }
      if (dynamic_cast<ArrayOption *>(opt.get())) {
        types.emplace_back(std::make_shared<List>(
            std::vector<std::shared_ptr<Type>>{this->ns.strType}));
        continue;
      }
    }
    if (types.empty()) {
      node->types = func->returnTypes;
    } else {
      node->types = dedup(this->ns, types);
    }
    return;
  }
  if (name == "build_target") {
    const auto &values = ::guessSetVariable(node, "target_type", this->options);
    std::set<std::string> const asSet{values.begin(), values.end()};
    std::vector<std::shared_ptr<Type>> types;
    for (const auto &tgtType : asSet) {
      if (tgtType == "executable") {
        types.emplace_back(this->ns.types.at("exe"));
      } else if (tgtType == "shared_library" || tgtType == "static_library" ||
                 tgtType == "library") {
        types.emplace_back(this->ns.types.at("lib"));
      } else if (tgtType == "shared_module") {
        types.emplace_back(this->ns.types.at("build_tgt"));
      } else if (tgtType == "both_libraries") {
        types.emplace_back(this->ns.types.at("both_libs"));
      } else if (tgtType == "jar") {
        types.emplace_back(this->ns.types.at("jar"));
      }
    }
    if (!types.empty()) {
      node->types = dedup(this->ns, types);
    } else {
      node->types = func->returnTypes;
    }
    return;
  }
  if (name == "import") {
    const auto &values = ::guessSetVariable(node, this->options);
    std::set<std::string> const asSet{values.begin(), values.end()};
    std::vector<std::shared_ptr<Type>> types;
    for (const auto &modname : asSet) {
      if (modname == "cmake") {
        types.emplace_back(this->ns.types.at("cmake_module"));
        continue;
      }
      if (modname == "fs") {
        types.emplace_back(this->ns.types.at("fs_module"));
        continue;
      }
      if (modname == "gnome") {
        types.emplace_back(this->ns.types.at("gnome_module"));
        continue;
      }
      if (modname == "i18n") {
        types.emplace_back(this->ns.types.at("i18n_module"));
        continue;
      }
      if (modname == "rust" || modname == "unstable-rust") {
        types.emplace_back(this->ns.types.at("rust_module"));
        continue;
      }
      if (modname == "python") {
        types.emplace_back(this->ns.types.at("python_module"));
        continue;
      }
      if (modname == "python3") {
        types.emplace_back(this->ns.types.at("python3_module"));
        continue;
      }
      if (modname == "pkgconfig") {
        types.emplace_back(this->ns.types.at("pkgconfig_module"));
        continue;
      }
      if (modname == "keyval" || modname == "unstable-keyval") {
        types.emplace_back(this->ns.types.at("keyval_module"));
        continue;
      }
      if (modname == "dlang") {
        types.emplace_back(this->ns.types.at("dlang_module"));
        continue;
      }
      if (modname == "unstable-external_project" ||
          modname == "external_project") {
        types.emplace_back(this->ns.types.at("external_project_module"));
        continue;
      }
      if (modname == "hotdoc") {
        types.emplace_back(this->ns.types.at("hotdoc_module"));
        continue;
      }
      if (modname == "java") {
        types.emplace_back(this->ns.types.at("java_module"));
        continue;
      }
      if (modname == "windows") {
        types.emplace_back(this->ns.types.at("windows_module"));
        continue;
      }
      if (modname == "unstable-cuda" || modname == "cuda") {
        types.emplace_back(this->ns.types.at("cuda_module"));
        continue;
      }
      if (modname == "icestorm" || modname == "unstable-icestorm") {
        types.emplace_back(this->ns.types.at("icestorm_module"));
        continue;
      }
      if (modname == "qt4") {
        types.emplace_back(this->ns.types.at("qt4_module"));
        continue;
      }
      if (modname == "qt5") {
        types.emplace_back(this->ns.types.at("qt5_module"));
        continue;
      }
      if (modname == "qt6") {
        types.emplace_back(this->ns.types.at("qt6_module"));
        continue;
      }
      if (modname == "unstable-wayland" || modname == "wayland") {
        types.emplace_back(this->ns.types.at("wayland_module"));
        continue;
      }
      if (modname == "simd" || modname == "unstable-simd") {
        types.emplace_back(this->ns.types.at("simd_module"));
        continue;
      }
      if (modname == "sourceset") {
        types.emplace_back(this->ns.types.at("sourceset_module"));
        continue;
      }
      types.emplace_back(this->ns.types.at("module"));
      this->metadata->registerDiagnostic(
          node, Diagnostic(Severity::Warning, node,
                           std::format("Unknown module `{}`", modname)));
    }
    node->types = dedup(this->ns, types);
    return;
  }
  if (name == "get_variable") {
    std::vector<std::shared_ptr<Type>> types;
    auto *al = dynamic_cast<ArgumentList *>(node->args.get());
    if (!al) {
      return;
    }
    if (al->args.size() == 2 &&
        !dynamic_cast<KeywordItem *>(al->args[1].get())) {
      auto defaultArg = al->args[1];
      types.insert(types.end(), defaultArg->types.begin(),
                   defaultArg->types.end());
    }
    const auto &values = ::guessSetVariable(node, this->options);
    std::set<std::string> const asSet{values.begin(), values.end()};
    for (const auto &varname : asSet) {
      if (!this->scope.variables.contains(varname)) {
        continue;
      }
      const auto &vTypes = this->scope.variables[varname];
      types.insert(types.end(), vTypes.begin(), vTypes.end());
    }
    if (asSet.empty()) {
      types.insert(types.end(), func->returnTypes.begin(),
                   func->returnTypes.end());
    }
    node->types = dedup(this->ns, types);
    LOG.info(std::format("get_variable: {} = {} ({}:{})",
                         joinStrings(asSet, '|'), joinTypes(node->types),
                         node->file->file.generic_string(),
                         node->location->format()));
    return;
  }
}

void TypeAnalyzer::checkKwargsAfterPositionalArguments(
    const std::vector<std::shared_ptr<Node>> &args) const {
  auto kwargsOnly = false;
  for (const auto &arg : args) {
    if (dynamic_cast<KeywordItem *>(arg.get())) {
      kwargsOnly = true;
      continue;
    }
    if (!kwargsOnly) {
      continue;
    }
    this->metadata->registerDiagnostic(
        arg.get(),
        Diagnostic(Severity::Error, arg.get(),
                   "Unexpected positional argument after a keyword argument"));
  }
}

void TypeAnalyzer::checkKwargs(const std::shared_ptr<Function> &func,
                               const std::vector<std::shared_ptr<Node>> &args,
                               Node *node) const {
  std::set<std::string> usedKwargs;
  for (const auto &arg : args) {
    auto *kwi = dynamic_cast<KeywordItem *>(arg.get());
    if (!kwi) {
      continue;
    }
    auto *kId = dynamic_cast<IdExpression *>(kwi->key.get());
    if (!kId) {
      continue;
    }
    usedKwargs.insert(kId->id);
    if (func->kwargs.contains(kId->id)) {
      const auto &kwarg = func->kwargs[kId->id];
      if (kwarg->deprecationState.deprecated) {
        const auto &alternatives = kwarg->deprecationState.replacements;
        auto sinceWhen = kwarg->deprecationState.sinceWhen;
        if (sinceWhen.has_value() && sinceWhen->after(this->tree->version)) {
          continue;
        }
        auto versionString =
            sinceWhen.has_value()
                ? std::format(" (Since {})", sinceWhen->versionString)
                : "";
        auto alternativesStr =
            alternatives.empty()
                ? ""
                : (" Try one of: " + joinStrings(alternatives, ','));
        this->metadata->registerDiagnostic(
            kwi->key.get(),
            Diagnostic(Severity::Warning, kwi->key.get(),
                       std::format("Deprecated keyword argument{}{}",
                                   versionString, alternativesStr),
                       true, false));
      }
      continue;
    }
    if (kId->id == "kwargs") {
      continue;
    }
    this->metadata->registerDiagnostic(
        arg.get(),
        Diagnostic(Severity::Error, arg.get(),
                   std::format("Unknown key word argument '{}'", kId->id)));
  }
  if (usedKwargs.contains("kwargs")) {
    return;
  }
  for (const auto &requiredKwarg : func->requiredKwargs) {
    if (usedKwargs.contains(requiredKwarg)) {
      continue;
    }
    this->metadata->registerDiagnostic(
        node, Diagnostic(Severity::Error, node,
                         std::format("Missing required key word argument '{}'",
                                     requiredKwarg)));
  }
}

bool TypeAnalyzer::compatible(const std::shared_ptr<Type> &given,
                              const std::shared_ptr<Type> &expected) {
  if (given->toString() == expected->toString()) {
    return true;
  }
  auto *gAO = dynamic_cast<AbstractObject *>(given.get());
  if (gAO) {
    auto parent = gAO->parent;
    if (parent.has_value() && this->compatible(parent.value(), expected)) {
      return true;
    }
  }
  auto *gList = dynamic_cast<List *>(given.get());
  auto *eList = dynamic_cast<List *>(expected.get());
  if (gList && eList) {
    return this->atleastPartiallyCompatible(eList->types, gList->types);
  }
  if ((eList != nullptr) &&
      this->atleastPartiallyCompatible(eList->types, {given})) {
    return true;
  }
  if ((gList != nullptr) &&
      this->atleastPartiallyCompatible({expected}, gList->types)) {
    return true;
  }
  auto *gDict = dynamic_cast<Dict *>(given.get());
  auto *eDict = dynamic_cast<Dict *>(expected.get());
  if (gDict && eDict) {
    return this->atleastPartiallyCompatible(eDict->types, gDict->types);
  }
  return false;
}

bool TypeAnalyzer::atleastPartiallyCompatible(
    const std::vector<std::shared_ptr<Type>> &expectedTypes,
    const std::vector<std::shared_ptr<Type>> &givenTypes) {
  if (givenTypes.empty()) {
    return true;
  }
  for (const auto &given : givenTypes) {
    if (dynamic_cast<Any *>(given.get()) ||
        dynamic_cast<Disabler *>(given.get())) {
      return true;
    }
    for (const auto &expected : expectedTypes) {
      if (dynamic_cast<Any *>(expected.get()) ||
          dynamic_cast<Disabler *>(expected.get())) {
        return true;
      }
      if (this->compatible(given, expected) ||
          (dynamic_cast<Any *>(given.get()) != nullptr)) {
        return true;
      }
    }
  }
  return false;
}

void TypeAnalyzer::checkTypes(
    const std::shared_ptr<Node> &arg,
    const std::vector<std::shared_ptr<Type>> &expectedTypes,
    const std::vector<std::shared_ptr<Type>> &givenTypes) {
  if (this->atleastPartiallyCompatible(expectedTypes, givenTypes)) {
    return;
  }
  this->metadata->registerDiagnostic(
      arg.get(),
      Diagnostic(Severity::Error, arg.get(),
                 std::format("Expected {}, got {}", joinTypes(expectedTypes),
                             joinTypes(givenTypes))));
}

void TypeAnalyzer::checkArgTypes(
    const std::shared_ptr<Function> &func,
    const std::vector<std::shared_ptr<Node>> &args) {
  auto posArgsIdx = 0;
  for (const auto &arg : args) {
    if (auto *kwi = dynamic_cast<KeywordItem *>(arg.get())) {
      const auto &givenTypes = kwi->value->types;
      const auto &kwargName = kwi->name.value();
      if (!func->kwargs.contains(kwargName)) {
        continue;
      }
      const auto &expectedTypes = func->kwargs[kwargName]->types;
      this->checkTypes(arg, expectedTypes, givenTypes);
    } else {
      auto *posArg = func->posArg(posArgsIdx);
      if (posArg) {
        this->checkTypes(arg, posArg->types, arg->types);
      }
      posArgsIdx++;
    }
  }
}

void TypeAnalyzer::checkCall(Node *node) {
  std::shared_ptr<Function> func;
  auto *fe = dynamic_cast<FunctionExpression *>(node);
  auto nPos = 0ULL;
  if (fe) {
    func = fe->function;
    if (auto *al = dynamic_cast<ArgumentList *>(fe->args.get())) {
      const auto &args = al->args;
      if (func) {
        this->checkKwargsAfterPositionalArguments(args);
        this->checkKwargs(func, args, node);
        this->checkArgTypes(func, args);
        for (const auto &arg : args) {
          if (!dynamic_cast<KeywordItem *>(arg.get())) {
            nPos++;
          }
        }
      }
    }
  }
  auto *me = dynamic_cast<MethodExpression *>(node);
  if (me) {
    func = me->method;
    if (auto *al = dynamic_cast<ArgumentList *>(me->args.get())) {
      const auto &args = al->args;
      if (func) {
        this->checkKwargsAfterPositionalArguments(args);
        this->checkKwargs(func, args, node);
        this->checkArgTypes(func, args);
        for (const auto &arg : args) {
          if (!dynamic_cast<KeywordItem *>(arg.get())) {
            nPos++;
          }
        }
      }
    }
  }
  if (!me && !fe) {
    return;
  }
  if (!func) {
    return;
  }

  if (nPos < func->minPosArgs) {
    this->metadata->registerDiagnostic(
        node,
        Diagnostic(Severity::Error, node,
                   std::format(
                       "Expected at least {} positional arguments, but got {}!",
                       func->minPosArgs, nPos)));
  }
  if (nPos > func->maxPosArgs) {
    this->metadata->registerDiagnostic(
        node,
        Diagnostic(
            Severity::Error, node,
            std::format("Expected maximum {} positional arguments, but got {}!",
                        func->maxPosArgs, nPos)));
  }
}

void TypeAnalyzer::guessSetVariable(std::vector<std::shared_ptr<Node>> args,
                                    FunctionExpression *node) {
  auto guessed = ::guessSetVariable(node, this->options);
  std::set<std::string> const asSet(guessed.begin(), guessed.end());
  LOG.info(std::format("Guessed values for set_variable: {} at {}:{}",
                       joinStrings(asSet, '|'), node->file->file.c_str(),
                       node->location->format()));
  for (const auto &varname : asSet) {
    auto types = args[1]->types;
    this->scope.variables[varname] = types;
    this->applyToStack(varname, types);
  }
}

void TypeAnalyzer::checkSetVariable(FunctionExpression *node,
                                    ArgumentList *al) {
  auto args = al->args;
  if (args.empty()) {
    return;
  }
  auto firstArg = args[0];
  auto *variableName = dynamic_cast<StringLiteral *>(firstArg.get());
  if (!variableName) {
    this->guessSetVariable(args, node);
  } else if (args.size() > 1) {
    auto varname = variableName->id;
    auto types = args[1]->types;
    this->scope.variables[varname] = types;
    this->applyToStack(varname, types);
    LOG.info(std::format("set_variable {} = {}", varname, joinTypes(types)));
  }
}

void TypeAnalyzer::enterSubdir(FunctionExpression *node) {
  auto *al = dynamic_cast<ArgumentList *>(node->args.get());
  if (!al || al->args.empty()) {
    return;
  }
  const auto &guessed = ::guessSetVariable(node, this->options);
  std::set<std::string> const asSet{guessed.begin(), guessed.end()};
  auto msg = std::format("Found subdircall with dirs: {} at {}:{}",
                         joinStrings(asSet, '|'), node->file->file.c_str(),
                         node->location->format());
  if (asSet.empty()) {
    LOG.warn(msg);
  } else {
    LOG.info(msg);
  }
  this->metadata->registerSubdirCall(node, asSet);
  const auto &parentPath = node->file->file.parent_path();
  for (const auto &dir : asSet) {
    const auto &dirpath = parentPath / dir;
    if (!std::filesystem::exists(dirpath)) {
      if (asSet.size() == 1) {
        this->metadata->registerDiagnostic(
            node, Diagnostic(Severity::Error, node,
                             std::format("Directory does not exist: {}", dir)));
      }
      continue;
    }
    const auto &mesonpath = dirpath / "meson.build";
    if (!std::filesystem::exists(mesonpath)) {
      if (asSet.size() == 1) {
        this->metadata->registerDiagnostic(
            node, Diagnostic(
                      Severity::Error, node,
                      std::format("File does not exist: {}/meson.build", dir)));
      }
      continue;
    }
    const auto &ast = this->tree->parseFile(mesonpath);
    LOG.info(std::format("Entering {}", dir));
    ast->parent = node;
    if (!std::filesystem::equivalent(node->file->file, mesonpath)) {
      ast->visit(this);
    }
    LOG.info(std::format("Leaving {}", dir));
  }
}

void TypeAnalyzer::visitFunctionExpression(FunctionExpression *node) {
  node->visitChildren(this);
  this->metadata->registerFunctionCall(node);
  const auto &funcName = node->functionName();
  if (funcName == INVALID_FUNCTION_NAME) {
    this->metadata->registerDiagnostic(
        node, Diagnostic(Severity::Error, node,
                         std::format("Unknown function `{}`", funcName)));
    return;
  }
  auto functionOpt = this->ns.lookupFunction(funcName);
  if (!functionOpt.has_value()) {
    this->metadata->registerDiagnostic(
        node, Diagnostic(Severity::Error, node,
                         std::format("Unknown function `{}`", funcName)));
    return;
  }
  auto func = functionOpt.value();
  node->types = func->returnTypes;
  this->setFunctionCallTypes(node, func);
  node->function = func;
  if (node->function->deprecationState.deprecated) {
    const auto &alternatives = node->function->deprecationState.replacements;
    auto sinceWhen = node->function->deprecationState.sinceWhen;
    if (sinceWhen.has_value() && sinceWhen->after(this->tree->version)) {
      goto afterVersionCheck;
    }
    auto versionString =
        sinceWhen.has_value()
            ? std::format(" (Since {})", sinceWhen->versionString)
            : "";
    auto alternativesStr =
        alternatives.empty()
            ? ""
            : (" Try one of: " + joinStrings(alternatives, ','));
    this->metadata->registerDiagnostic(
        node, Diagnostic(Severity::Warning, node,
                         std::format("Deprecated function{}{}", versionString,
                                     alternativesStr),
                         true, false));
  }
afterVersionCheck:
  if (func->since.after(this->tree->version)) {
    this->metadata->registerDiagnostic(
        node, Diagnostic(Severity::Warning, node,
                         std::format("Meson version {} is requested, but {}() "
                                     "is only available since {}",
                                     this->tree->version.versionString,
                                     func->id(), func->since.versionString)));
  }
  const auto &args = node->args;
  if (!args || !dynamic_cast<ArgumentList *>(args.get())) {
    if (func->minPosArgs > 0) {
      this->metadata->registerDiagnostic(
          node,
          Diagnostic(
              Severity::Error, node,
              std::format("Expected {} positional arguments, but got none!",
                          func->minPosArgs)));
    }
  } else {
    this->checkCall(node);
    auto *asArgumentList = dynamic_cast<ArgumentList *>(args.get());
    if (!asArgumentList) {
      goto cont;
    }
    for (const auto &arg : asArgumentList->args) {
      auto *asKwi = dynamic_cast<KeywordItem *>(arg.get());
      if (!asKwi) {
        continue;
      }
      this->metadata->registerKwarg(asKwi, node->function);
    }
    if (func->name == "set_variable") {
      this->checkSetVariable(node, asArgumentList);
    }
  }
cont:

  if (func->name == "subdir") {
    this->enterSubdir(node);
  }
}

std::vector<std::shared_ptr<Type>> TypeAnalyzer::evalStack(std::string &name) {
  std::vector<std::shared_ptr<Type>> ret;
  for (const auto &overridden : this->overriddenVariables) {
    if (!overridden.contains(name)) {
      continue;
    }
    ret.insert(ret.end(), overridden.at(name).begin(),
               overridden.at(name).end());
  }
  return ret;
}

bool TypeAnalyzer::ignoreIdExpression(IdExpression *node) {
  auto *parent = node->parent;
  if (!parent) {
    return false;
  }
  auto *fe = dynamic_cast<FunctionExpression *>(parent);
  if (fe && fe->id->equals(node)) {
    return true;
  }
  auto *me = dynamic_cast<MethodExpression *>(parent);
  if (me && me->id->equals(node)) {
    return true;
  }
  auto *kwi = dynamic_cast<KeywordItem *>(parent);
  if (kwi && kwi->key->equals(node)) {
    return true;
  }
  auto *ass = dynamic_cast<AssignmentStatement *>(parent);
  if (ass && ass->lhs->equals(node)) {
    return true;
  }
  if (dynamic_cast<IterationStatement *>(parent)) {
    return true;
  }
  return std::find(this->ignoreUnknownIdentifier.begin(),
                   this->ignoreUnknownIdentifier.end(),
                   node->id) != this->ignoreUnknownIdentifier.end();
}

bool TypeAnalyzer::isKnownId(IdExpression *idExpr) {
  auto *parent = idExpr->parent;
  if (!parent) {
    return true;
  }
  auto *ass = dynamic_cast<AssignmentStatement *>(parent);
  if (ass) {
    auto *lhsIdExpr = dynamic_cast<IdExpression *>(ass->lhs.get());
    if (lhsIdExpr && lhsIdExpr->id == idExpr->id &&
        ass->op == AssignmentOperator::Equals) {
      return true;
    }
  }
  auto *its = dynamic_cast<IterationStatement *>(parent);
  if (its) {
    for (const auto &itsId : its->ids) {
      auto *idexpr = dynamic_cast<IdExpression *>(itsId.get());
      if (idexpr && idexpr->id == idExpr->id) {
        return true;
      }
    }
  }
  auto *kwi = dynamic_cast<KeywordItem *>(parent);
  if (kwi) {
    auto *key = dynamic_cast<IdExpression *>(kwi->key.get());
    if (key && key->id == idExpr->id) {
      return true;
    }
  }
  auto *fe = dynamic_cast<FunctionExpression *>(parent);
  if (fe) {
    auto *idexpr = dynamic_cast<IdExpression *>(fe->id.get());
    if (idexpr && idexpr->id == idExpr->id) {
      return true;
    }
  }
  auto *me = dynamic_cast<MethodExpression *>(parent);
  if (me) {
    auto *idexpr = dynamic_cast<IdExpression *>(me->id.get());
    if (idexpr && idexpr->id == idExpr->id) {
      return true;
    }
  }
  return this->scope.variables.contains(idExpr->id);
}

void TypeAnalyzer::visitIdExpression(IdExpression *node) {
  auto types = this->evalStack(node->id);
  if (this->scope.variables.contains(node->id)) {
    const auto &scopeVariables = this->scope.variables[node->id];
    types.insert(types.end(), scopeVariables.begin(), scopeVariables.end());
  }
  node->types = dedup(this->ns, types);
  node->visitChildren(this);
  auto *parent = node->parent;
  if (parent) {
    auto *ass = dynamic_cast<AssignmentStatement *>(parent);
    if (ass) {
      if (ass->op != AssignmentOperator::Equals || ass->rhs->equals(node)) {
        this->registerUsed(node->id);
      }
      goto cont;
    }
    auto *kwi = dynamic_cast<KeywordItem *>(parent);
    if (kwi && kwi->value->equals(node)) {
      this->registerUsed(node->id);
      goto cont;
    }
    if (dynamic_cast<FunctionExpression *>(parent)) {
      goto cont; // Do nothing
    }
    this->registerUsed(node->id);
  } else {
    this->registerUsed(node->id);
  }
cont:
  if (this->ignoreIdExpression(node)) {
    return;
  }
  if (!this->isKnownId(node)) {
    this->metadata->registerDiagnostic(
        node, Diagnostic(Severity::Error, node,
                         std::format("Unknown identifier `{}`", node->id)));
  }
  this->metadata->registerIdentifier(node);
}

void TypeAnalyzer::registerUsed(const std::string &varname) {
  for (auto &arr : this->variablesNeedingUse | std::ranges::views::reverse) {
    arr.erase(std::remove_if(arr.begin(), arr.end(),
                             [&varname](const auto &idExpr) {
                               return idExpr->id != varname;
                             }),
              arr.end());
  }
}

void TypeAnalyzer::visitIntegerLiteral(IntegerLiteral *node) {
  node->visitChildren(this);
  node->types.emplace_back(this->ns.intType);
}

void TypeAnalyzer::analyseIterationStatementSingleIdentifier(
    IterationStatement *node) {
  auto iterTypes = node->expression->types;
  std::vector<std::shared_ptr<Type>> res;
  auto errs = 0UL;
  auto foundDict = false;
  for (const auto &iterT : iterTypes) {
    if (dynamic_cast<Range *>(iterT.get())) {
      res.emplace_back(this->ns.intType);
      continue;
    }
    auto *asList = dynamic_cast<List *>(iterT.get());
    if (asList) {
      res.insert(res.end(), asList->types.begin(), asList->types.end());
      continue;
    }
    if (dynamic_cast<Dict *>(iterT.get())) {
      foundDict = true;
    }
    errs++;
  }
  if (errs != iterTypes.size()) {
    node->ids[0]->types = dedup(this->ns, res);
  } else {
    node->ids[0]->types = {};
    this->metadata->registerDiagnostic(
        node->expression.get(),
        Diagnostic(Severity::Error, node->expression.get(),
                   foundDict ? "Iterating over a dict requires two identifiers"
                             : "Expression yields no iterable result"));
  }
  auto *id0Expr = dynamic_cast<IdExpression *>(node->ids[0].get());
  if (!id0Expr) {
    return;
  }
  this->metadata->encounteredIds.push_back(id0Expr);
  this->applyToStack(id0Expr->id, node->ids[0]->types);
  this->scope.variables[id0Expr->id] = node->ids[0]->types;
  this->checkIdentifier(id0Expr);
}

void TypeAnalyzer::analyseIterationStatementTwoIdentifiers(
    IterationStatement *node) {
  auto iterTypes = node->expression->types;
  node->ids[0]->types = {this->ns.strType};
  auto found = false;
  auto foundBad = false;
  for (const auto &iterT : iterTypes) {
    auto *dict = dynamic_cast<Dict *>(iterT.get());
    foundBad |= dynamic_cast<List *>(iterT.get()) != nullptr ||
                dynamic_cast<Range *>(iterT.get()) != nullptr;
    if (!dict) {
      continue;
    }
    node->ids[1]->types = dict->types;
    found = true;
    break;
  }
  if (!found) {
    this->metadata->registerDiagnostic(
        node->expression.get(),
        Diagnostic(Severity::Error, node->expression.get(),
                   foundBad
                       ? "Iterating over a list/range requires one identifier"
                       : "Expression yields no iterable result"));
  }
  auto *id0Expr = dynamic_cast<IdExpression *>(node->ids[0].get());
  if (id0Expr) {
    this->metadata->encounteredIds.push_back(id0Expr);
    this->applyToStack(id0Expr->id, node->ids[0]->types);
    this->scope.variables[id0Expr->id] = node->ids[0]->types;
    this->checkIdentifier(id0Expr);
  }
  auto *id1Expr = dynamic_cast<IdExpression *>(node->ids[1].get());
  if (id1Expr) {
    this->metadata->encounteredIds.push_back(id1Expr);
    this->applyToStack(id1Expr->id, node->ids[1]->types);
    this->scope.variables[id1Expr->id] = node->ids[1]->types;
    this->checkIdentifier(id1Expr);
  }
}

void TypeAnalyzer::visitIterationStatement(IterationStatement *node) {
  node->expression->visit(this);
  for (const auto &itsId : node->ids) {
    itsId->visit(this);
  }
  auto count = node->ids.size();
  if (count == 1) {
    analyseIterationStatementSingleIdentifier(node);
  } else if (count == 2) {
    analyseIterationStatementTwoIdentifiers(node);
  } else {
    auto *fNode = node->ids[0].get();
    auto *eNode = node->ids[1].get();
    this->metadata->registerDiagnostic(
        fNode,
        Diagnostic(Severity::Error, fNode, eNode,
                   "Iteration statement expects only one or two identifiers"));
  }
  std::shared_ptr<Node> lastAlive = nullptr;
  std::shared_ptr<Node> firstDead = nullptr;
  std::shared_ptr<Node> lastDead = nullptr;
  for (const auto &stmt : node->stmts) {
    stmt->visit(this);
    this->checkNoEffect(stmt.get());
    if (!lastAlive) {
      if (this->isDead(stmt)) {
        lastAlive = stmt;
      }
    } else {
      if (!firstDead) {
        firstDead = stmt;
        lastDead = stmt;
      } else {
        lastDead = stmt;
      }
    }
  }
  this->applyDead(lastAlive, firstDead, lastDead);
}

void TypeAnalyzer::visitKeyValueItem(KeyValueItem *node) {
  node->visitChildren(this);
  node->types = node->value->types;
}

void TypeAnalyzer::visitKeywordItem(KeywordItem *node) {
  node->visitChildren(this);
}

bool TypeAnalyzer::findMethod(
    MethodExpression *node, const std::string &methodName, int *nAny, int *bits,
    std::vector<std::shared_ptr<Type>> &ownResultTypes) {
  auto found = false;
  const auto &types = node->obj->types;
  for (const auto &type : types) {
    if (dynamic_cast<Any *>(type.get())) {
      *nAny = *nAny + 1;
      *bits = (*bits) | (1 << 0);
      continue;
    }
    auto *listtype = dynamic_cast<List *>(type.get());
    if (listtype && listtype->types.size() == 1 &&
        dynamic_cast<Any *>(listtype->types[0].get())) {
      *nAny = *nAny + 1;
      *bits = (*bits) | (1 << 1);
    }
    auto *dicttype = dynamic_cast<Dict *>(type.get());
    if (dicttype && dicttype->types.size() == 1 &&
        dynamic_cast<Any *>(dicttype->types[0].get())) {
      *nAny = *nAny + 1;
      *bits = (*bits) | (1 << 2);
    }
    if (methodName == "get") {
      auto *al = dynamic_cast<ArgumentList *>(node->args.get());
      if (!al || al->args.empty()) {
        continue;
      }
      const auto &firstArg = al->args[0];
      if (firstArg->types.empty()) {
        continue;
      }
      for (const auto &argType : firstArg->types) {
        if (dynamic_cast<IntType *>(argType.get()) && listtype) {
          goto cont;
        }
        if (dynamic_cast<Str *>(argType.get()) && dicttype) {
          goto cont;
        }
        if (dynamic_cast<Str *>(argType.get()) &&
            dynamic_cast<CfgData *>(type.get())) {
          goto cont;
        }
      }
      LOG.info(std::format("Unexpected get() method for {}: {}",
                           type->toString(), joinTypes(firstArg->types)));
      continue;
    }
  cont:
    auto methodOpt = this->ns.lookupMethod(methodName, type);
    if (!methodOpt) {
      continue;
    }
    auto method = methodOpt.value();
    ownResultTypes.insert(ownResultTypes.end(), method->returnTypes.begin(),
                          method->returnTypes.end());
    auto *al = dynamic_cast<ArgumentList *>(node->args.get());
    if (al && al->args.size() == 2 && methodName == "get") {
      auto defaultArg = al->getPositionalArg(1);
      if (defaultArg.has_value()) {
        auto defaultTypes = defaultArg.value()->types;
        ownResultTypes.insert(ownResultTypes.end(), defaultTypes.begin(),
                              defaultTypes.end());
      }
    }
    node->method = method;
    found = true;
  }
  if (*nAny == 3 && *bits == 0b111) {
    return found;
  }
  if (!found && methodName == "get") {
    for (const auto &type : types) {
      if (dynamic_cast<Dict *>(type.get()) ||
          dynamic_cast<List *>(type.get()) ||
          dynamic_cast<CfgData *>(type.get())) {
        auto method = this->ns.lookupMethod("get", type);
        assert(method.has_value());
        node->method = method.value();
        ownResultTypes.insert(ownResultTypes.end(),
                              method.value()->returnTypes.begin(),
                              method.value()->returnTypes.end());
        auto *al = dynamic_cast<ArgumentList *>(node->args.get());
        if (al && al->args.size() == 2 && methodName == "get") {
          auto defaultArg = al->getPositionalArg(1);
          if (defaultArg.has_value()) {
            auto defaultTypes = defaultArg.value()->types;
            ownResultTypes.insert(ownResultTypes.end(), defaultTypes.begin(),
                                  defaultTypes.end());
          }
        }
        found = true;
        break;
      }
    }
  }
  return found;
}

bool TypeAnalyzer::guessMethod(
    MethodExpression *node, const std::string &methodName,
    std::vector<std::shared_ptr<Type>> &ownResultTypes) {
  auto guessedMethod = this->ns.lookupMethod(methodName);
  if (!guessedMethod) {
    return false;
  }
  auto method = guessedMethod.value();
  ownResultTypes.insert(ownResultTypes.end(), method->returnTypes.begin(),
                        method->returnTypes.end());
  node->method = method;
  node->types = dedup(this->ns, ownResultTypes);
  return true;
}

void TypeAnalyzer::visitMethodExpression(MethodExpression *node) {
  node->visitChildren(this);
  this->metadata->registerMethodCall(node);
  const auto &types = node->obj->types;
  std::vector<std::shared_ptr<Type>> ownResultTypes;
  auto *methodNameId = dynamic_cast<IdExpression *>(node->id.get());
  if (!methodNameId) {
    return;
  }
  const auto &methodName = methodNameId->id;
  auto nAny = 0;
  auto bits = 0;
  auto found = this->findMethod(node, methodName, &nAny, &bits, ownResultTypes);
  node->types = dedup(this->ns, ownResultTypes);
  if (!found && (((size_t)nAny == types.size()) ||
                 (bits == 0b111 /* NOLINT */ && types.size() == 3))) {
    found = this->guessMethod(node, methodName, ownResultTypes);
  }
  auto onlyDisabler = types.size() == 1 &&
                      (dynamic_cast<Disabler *>(types[0].get()) != nullptr);
  if (!found && !onlyDisabler) {
    const auto &typeStr = joinTypes(types);
    this->metadata->registerDiagnostic(
        node, Diagnostic(Severity::Error, node,
                         std::format("No method `{}` found for types `{}`",
                                     methodName, typeStr)));
    return;
  }
  if (!found && onlyDisabler) {
    LOG.warn("Ignoring invalid method for disabler");
    return;
  }
  if (node->method->deprecationState.deprecated) {
    const auto &alternatives = node->method->deprecationState.replacements;
    auto sinceWhen = node->method->deprecationState.sinceWhen;
    if (sinceWhen.has_value() && sinceWhen->after(this->tree->version)) {
      goto afterVersionCheck;
    }
    auto versionString =
        sinceWhen.has_value()
            ? std::format(" (Since {})", sinceWhen->versionString)
            : "";
    auto alternativesStr =
        alternatives.empty()
            ? ""
            : (" Try one of: " + joinStrings(alternatives, ','));
    this->metadata->registerDiagnostic(
        node, Diagnostic(Severity::Warning, node,
                         std::format("Deprecated method{}{}", versionString,
                                     alternativesStr),
                         true, false));
  }
afterVersionCheck:
  if (node->method->since.after(this->tree->version)) {
    this->metadata->registerDiagnostic(
        node, Diagnostic(Severity::Warning, node,
                         std::format("Meson version {} is requested, but {}() "
                                     "is only available since {}",
                                     this->tree->version.versionString,
                                     node->method->id(),
                                     node->method->since.versionString)));
  }
  if (node->args) {
    if (const auto &asArgumentList =
            dynamic_cast<ArgumentList *>(node->args.get())) {
      for (const auto &arg : asArgumentList->args) {
        auto *asKwi = dynamic_cast<KeywordItem *>(arg.get());
        if (!asKwi) {
          continue;
        }
        this->metadata->registerKwarg(asKwi, node->method);
      }
    }
  }
  if (node->method->id() == "subproject.get_variable" &&
      this->tree->state->used) {
    std::vector<std::shared_ptr<Type>> types;
    types.insert(types.end(), node->method->returnTypes.begin(),
                 node->method->returnTypes.end());
    const auto &values = ::guessGetVariableMethod(node, this->options);
    std::set<std::string> const asSet{values.begin(), values.end()};
    for (const auto &objType : node->obj->types) {
      auto *subprojType = dynamic_cast<Subproject *>(objType.get());
      if (!subprojType) {
        continue;
      }
      for (const auto &subprojName : subprojType->names) {
        const auto &subproj = this->tree->state->findSubproject(subprojName);
        if (!subproj) {
          LOG.warn(std::format("Unable to find subproject {}", subprojName));
          continue;
        }
        const auto &scope = subproj->tree->scope;
        for (const auto &varname : asSet) {
          if (!scope.variables.contains(varname)) {
            LOG.warn(std::format("Unable to find variable {} in subproject {}",
                                 varname, subprojName));
            if (asSet.size() == 1 && subprojType->names.size() == 1) {
              this->metadata->registerDiagnostic(
                  node,
                  Diagnostic(
                      Severity::Error, node,
                      std::format("Unable to find variable {} in subproject {}",
                                  varname, subprojName)));
            }
            continue;
          }
          const auto &varTypes = scope.variables.at(varname);
          types.insert(types.end(), varTypes.begin(), varTypes.end());
        }
      }
    }
    node->types = dedup(this->ns, types);
  }
  this->checkCall(node);
  auto *sl = dynamic_cast<StringLiteral *>(node->obj.get());
  auto *al = dynamic_cast<ArgumentList *>(node->args.get());
  if ((sl != nullptr) && node->method->id() == "str.format") {
    this->checkFormat(sl, al->args);
  }
}

void TypeAnalyzer::checkFormat(
    StringLiteral *sl, const std::vector<std::shared_ptr<Node>> &args) const {
  auto foundIntegers = extractIntegersBetweenAtSymbols(sl->id);
  for (size_t i = 0; i < args.size(); i++) {
    if (!foundIntegers.contains(i)) {
      this->metadata->registerDiagnostic(
          args[i].get(), Diagnostic(Severity::Warning, args[i].get(),
                                    "Unused parameter in format() call"));
    }
  }
  if (foundIntegers.empty()) {
    if (args.empty()) {
      this->metadata->registerDiagnostic(
          sl->parent, Diagnostic(Severity::Warning, sl->parent,
                                 "Pointless str.format() call"));
      return;
    }
  }
  std::vector<std::string> oobIntegers;
  for (auto integer : foundIntegers) {
    if (integer >= args.size()) {
      oobIntegers.push_back(std::format("@{}@", integer));
    }
  }
  if (oobIntegers.empty()) {
    return;
  }
  this->metadata->registerDiagnostic(
      sl,
      Diagnostic(Severity::Error, sl,
                 "Parameters out of bounds: " + joinStrings(oobIntegers, ',')));
}

bool TypeAnalyzer::checkCondition(Node *condition) {
  auto appended = false;
  auto *fe = dynamic_cast<FunctionExpression *>(condition);
  if ((fe != nullptr) && fe->functionName() == "is_variable") {
    auto *al = dynamic_cast<ArgumentList *>(fe->args.get());
    if (al && !al->args.empty()) {
      auto *testedIdentifier = dynamic_cast<StringLiteral *>(al->args[0].get());
      if (testedIdentifier) {
        this->ignoreUnknownIdentifier.emplace_back(testedIdentifier->id);
        appended = true;
      }
    }
  }
  auto foundBoolOrAny = false;
  for (const auto &type : condition->types) {
    if (dynamic_cast<Any *>(type.get()) ||
        dynamic_cast<BoolType *>(type.get()) ||
        dynamic_cast<Disabler *>(type.get())) {
      foundBoolOrAny = true;
      break;
    }
  }
  if (!foundBoolOrAny && !condition->types.empty()) {
    auto joined = joinTypes(condition->types);
    this->metadata->registerDiagnostic(
        condition, Diagnostic(Severity::Error, condition,
                              "Condition is not bool: " + joined));
  }
  return appended;
}

void TypeAnalyzer::visitSelectionStatement(SelectionStatement *node) {
  this->stack.emplace_back();
  this->overriddenVariables.emplace_back();
  std::map<std::string, std::vector<std::shared_ptr<Type>>> oldVars;
  for (const auto &oldVar : this->scope.variables) {
    oldVars[oldVar.first] = std::vector<std::shared_ptr<Type>>{
        oldVar.second.begin(), oldVar.second.end()};
  }
  auto idx = 0UL;
  std::vector<IdExpression *> allLeft;
  for (const auto &block : node->blocks) {
    auto appended = false;
    if (idx < node->conditions.size()) {
      const auto &cond = node->conditions[idx];
      cond->visit(this);
      appended = this->checkCondition(cond.get());
    }
    std::shared_ptr<Node> lastAlive = nullptr;
    std::shared_ptr<Node> firstDead = nullptr;
    std::shared_ptr<Node> lastDead = nullptr;
    this->variablesNeedingUse.emplace_back();
    for (const auto &stmt : block) {
      stmt->visit(this);
      this->checkNoEffect(stmt.get());
      if (!lastAlive) {
        if (this->isDead(stmt)) {
          lastAlive = stmt;
        }
      } else {
        if (!firstDead) {
          firstDead = stmt;
          lastDead = stmt;
        } else {
          lastDead = stmt;
        }
      }
    }
    this->applyDead(lastAlive, firstDead, lastDead);
    if (appended) {
      this->ignoreUnknownIdentifier.pop_back();
    }
    const auto &lastNeedingUse = this->variablesNeedingUse.back();
    allLeft.insert(allLeft.end(), lastNeedingUse.begin(), lastNeedingUse.end());
    this->variablesNeedingUse.pop_back();
    idx++;
  }
  std::set<std::string> dedupedUnusedAssignments;
  auto toInsert = this->variablesNeedingUse.back();
  for (auto *idExpr : allLeft) {
    if (!dedupedUnusedAssignments.contains(idExpr->id)) {
      continue;
    }
    dedupedUnusedAssignments.insert(idExpr->id);
    toInsert.emplace_back(idExpr);
  }
  this->variablesNeedingUse.back() = toInsert;
  const auto &types = this->stack.back();
  // If: 1 c, 1 b
  // If,else if: 2c, 2b
  // if, else if, else, 2c, 3b
  for (const auto &pair : types) {
    // This leaks some overwritten types. This can't be solved
    // without costly static analysis
    // x = 'Foo'
    // if bar
    //   x = 2
    // else
    //   x = true
    // endif
    // x is now str|int|bool instead of int|bool
    const auto &key = pair.first;
    auto arr = this->scope.variables.contains(key)
                   ? this->scope.variables[key]
                   : std::vector<std::shared_ptr<Type>>{};
    arr.insert(arr.end(), pair.second.begin(), pair.second.end());
    if (oldVars.contains(key)) {
      const auto &oldTypes = oldVars[key];
      arr.insert(arr.end(), oldTypes.begin(), oldTypes.end());
    }
    this->scope.variables[key] = dedup(this->ns, arr);
  }
  this->stack.pop_back();
  this->overriddenVariables.pop_back();
}

void TypeAnalyzer::visitStringLiteral(StringLiteral *node) {
  node->visitChildren(this);
  node->types.emplace_back(this->ns.strType);
  this->metadata->registerStringLiteral(node);
  const auto &str = node->id;
  const auto &matches = extractTextBetweenAtSymbols(str);
  if (!node->isFormat && !matches.empty()) {
    auto reallyFound = true;
    for (const auto &match : matches) {
      if (match.starts_with("OUTPUT") || match.starts_with("INPUT") ||
          match == "BASENAME" || match.starts_with("OUTDIR") ||
          match == "BUILD_ROOT" || match == "BUILD_DIR" ||
          match == "PLAINNAME" || match == "EXTRA_ARGS") {
        reallyFound = false;
        break;
      }
    }
    if (reallyFound) {
      this->metadata->registerDiagnostic(
          node, Diagnostic(Severity::Warning, node,
                           "Found format identifiers in string, but literal is "
                           "not a format string."));
    }
    return;
  }
  for (const auto &match : matches) {
    this->registerUsed(match);
  }
}

void TypeAnalyzer::visitSubscriptExpression(SubscriptExpression *node) {
  node->visitChildren(this);
  std::vector<std::shared_ptr<Type>> newTypes;
  for (const auto &type : node->outer->types) {
    auto *asDict = dynamic_cast<Dict *>(type.get());
    if (asDict != nullptr) {
      const auto &dTypes = asDict->types;
      newTypes.insert(newTypes.begin(), dTypes.begin(), dTypes.end());
      continue;
    }
    auto *asList = dynamic_cast<List *>(type.get());
    if (asList != nullptr) {
      const auto &lTypes = asList->types;
      newTypes.insert(newTypes.begin(), lTypes.begin(), lTypes.end());
      continue;
    }
    if (dynamic_cast<Str *>(type.get()) != nullptr) {
      newTypes.emplace_back(this->ns.strType);
      continue;
    }
    if (dynamic_cast<CustomTgt *>(type.get()) != nullptr) {
      newTypes.emplace_back(this->ns.types.at("custom_idx"));
      continue;
    }
  }
  this->metadata->registerArrayAccess(node);
  node->types = dedup(this->ns, newTypes);
}

void TypeAnalyzer::visitUnaryExpression(UnaryExpression *node) {
  node->visitChildren(this);
  switch (node->op) {
  case Not:
  case ExclamationMark:
    node->types.push_back(this->ns.boolType);
    break;
  case UnaryMinus:
    node->types.push_back(this->ns.intType);
    break;
  case UnaryOther:
  default:
    this->metadata->registerDiagnostic(
        node, Diagnostic(Severity::Error, node, "Bad unary operator"));
    break;
  }
}

void TypeAnalyzer::visitErrorNode(ErrorNode *node) {
  node->visitChildren(this);
  this->metadata->registerDiagnostic(
      node, Diagnostic(Severity::Error, node, node->message));
}

void TypeAnalyzer::visitBreakNode(BreakNode *node) {
  this->checkIfInLoop(node, "break");
}

void TypeAnalyzer::visitContinueNode(ContinueNode *node) {
  this->checkIfInLoop(node, "continue");
}

void TypeAnalyzer::checkIfInLoop(Node *node, std::string str) const {
  auto *parent = node->parent;
  while (parent) {
    if (dynamic_cast<IterationStatement *>(parent)) {
      return;
    }
    if (dynamic_cast<BuildDefinition *>(parent)) {
      break;
    }
    parent = parent->parent;
  }
  this->metadata->registerDiagnostic(
      node,
      Diagnostic(
          Severity::Error, node,
          std::format("{} statements are only allowed inside loops", str)));
}

static std::vector<std::shared_ptr<Type>>
dedup(const TypeNamespace &ns, std::vector<std::shared_ptr<Type>> types) {
  if (types.size() <= 1) {
    return types;
  }
  std::vector<std::shared_ptr<Type>> listtypes;
  std::vector<std::shared_ptr<Type>> dicttypes;
  std::set<std::string> subprojectNames;
  auto hasAny = false;
  auto hasBool = false;
  auto hasInt = false;
  auto hasStr = false;
  std::map<std::string, std::shared_ptr<Type>> objs;
  auto gotList = false;
  auto gotDict = false;
  auto gotSubproject = false;
  for (const auto &type : types) {
    auto *asRaw = type.get();
    if (dynamic_cast<Any *>(asRaw) != nullptr) {
      hasAny = true;
      continue;
    }
    if (dynamic_cast<BoolType *>(asRaw) != nullptr) {
      hasBool = true;
      continue;
    }
    if (dynamic_cast<IntType *>(asRaw) != nullptr) {
      hasInt = true;
      continue;
    }
    if (dynamic_cast<Str *>(asRaw) != nullptr) {
      hasStr = true;
      continue;
    }
    auto *asDict = dynamic_cast<Dict *>(asRaw);
    if (asDict != nullptr) {
      dicttypes.insert(dicttypes.end(), asDict->types.begin(),
                       asDict->types.end());
      gotDict = true;
      continue;
    }
    auto *asList = dynamic_cast<List *>(asRaw);
    if (asList != nullptr) {
      listtypes.insert(listtypes.end(), asList->types.begin(),
                       asList->types.end());
      gotList = true;
      continue;
    }
    auto *asSubproject = dynamic_cast<Subproject *>(asRaw);
    if (asSubproject != nullptr) {
      subprojectNames.insert(asSubproject->names.begin(),
                             asSubproject->names.end());
      gotSubproject = true;
      continue;
    }
    objs[type->name] = type;
  }
  std::vector<std::shared_ptr<Type>> ret;
  if ((!listtypes.empty()) || gotList) {
    ret.emplace_back(std::make_shared<List>(dedup(ns, listtypes)));
  }
  if ((!dicttypes.empty()) || gotDict) {
    ret.emplace_back(std::make_shared<Dict>(dedup(ns, dicttypes)));
  }
  if ((!subprojectNames.empty()) || gotSubproject) {
    ret.emplace_back(std::make_shared<Subproject>(std::vector<std::string>(
        subprojectNames.begin(), subprojectNames.end())));
  }
  if (hasAny) {
    ret.emplace_back(ns.types.at("any"));
  }
  if (hasBool) {
    ret.emplace_back(ns.boolType);
  }
  if (hasInt) {
    ret.emplace_back(ns.intType);
  }
  if (hasStr) {
    ret.emplace_back(ns.strType);
  }
  for (const auto &obj : objs) {
    ret.emplace_back(obj.second);
  }
  return ret;
}

std::string joinTypes(const std::vector<std::shared_ptr<Type>> &types) {
  std::vector<std::string> vector;
  vector.reserve(types.size());
  for (const auto &type : types) {
    vector.push_back(type->toString());
  }
  std::sort(vector.begin(), vector.end());
  std::string ret;
  ret.reserve(vector.size() * TYPE_STRING_LENGTH);
  for (size_t i = 0; i < vector.size(); i++) {
    ret.append(vector[i]);
    if (i != vector.size() - 1) {
      ret.append("|");
    }
  }
  return ret;
}

static bool isSnakeCase(const std::string &str) {
  return std::ranges::all_of(str.begin(), str.end(), [](char chr) {
    return (std::islower(chr) != 0) || (std::isdigit(chr) != 0) || chr == '_';
  });
}

static bool isShoutingSnakeCase(const std::string &str) {
  return std::ranges::all_of(str.begin(), str.end(), [](char chr) {
    return (std::isupper(chr) != 0) || (std::isdigit(chr) != 0) || chr == '_';
  });
}

static bool isType(const std::shared_ptr<Type> &type, const std::string &name) {
  return type->name == name || type->name == "any";
}

static bool sameType(const std::shared_ptr<Type> &first,
                     const std::shared_ptr<Type> &second,
                     const std::string &name) {
  return isType(first, name) && isType(second, name);
}
