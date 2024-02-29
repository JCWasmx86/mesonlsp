#include "typeanalyzer.hpp"

#include "deprecationstate.hpp"
#include "function.hpp"
#include "log.hpp"
#include "mesonmetadata.hpp"
#include "mesonoption.hpp"
#include "node.hpp"
#include "partialinterpreter.hpp"
#include "polyfill.hpp"
#include "type.hpp"
#include "typenamespace.hpp"
#include "utils.hpp"
#include "version.hpp"

#include <algorithm>
#include <cassert>
#include <cctype>
#include <cstddef>
#include <cstdint>
#include <filesystem>
#include <map>
#include <memory>
#include <optional>
#include <ranges>
#include <set>
#include <string>
#include <utility>
#include <vector>

constexpr int TYPE_STRING_LENGTH = 12;
constexpr int ALL_TYPES_FOUND = 0b111;
const static Logger LOG("analyze::typeanalyzer"); // NOLINT

static const std::set<std::string> COMPILER_IDS = /*NOLINT*/ {
    "arm",           "armclang",   "ccomp",      "ccrx",      "clang",
    "clang-cl",      "dmd",        "emscripten", "flang",     "g95",
    "gcc",           "intel",      "intel-cl",   "icc",       "intel-llvm",
    "intel-llvm-cl", "lcc",        "llvm",       "mono",      "msvc",
    "nagfor",        "nvidia_hpc", "open64",     "pathscale", "pgi",
    "rustc",         "sun",        "c2000",      "ti",        "valac",
    "xc16",          "cython",     "nasm",       "yasm",      "ml",
    "armasm",        "mwasmarm",   "mwasmeppc",
};

static const std::set<std::string> ARGUMENT_SYNTAXES /*NOLINT*/ = {
    "gcc", "msvc", "gnu", ""};
static const std::set<std::string> LINKER_IDS /*NOLINT*/ = {
    "ld.bfd", "ld.gold",  "ld.lld",  "ld.mold",  "ld.solaris", "ld.wasm",
    "ld64",   "ld64.lld", "link",    "lld-link", "xilink",     "optlink",
    "rlink",  "xc16-ar",  "ar2000",  "ti-ar",    "armlink",    "pgi",
    "nvlink", "ccomp",    "mwldarm", "mwldeppc",
};

static const std::set<std::string> CPU_FAMILIES /*NOLINT*/ = {
    "aarch64", "alpha",      "arc",    "arm",    "avr",     "c2000",
    "csky",    "dspic",      "e2k",    "ft32",   "ia64",    "loongarch64",
    "m68k",    "microblaze", "mips",   "mips32", "mips64",  "msp430",
    "parisc",  "pic24",      "ppc",    "ppc64",  "riscv32", "riscv64",
    "rl78",    "rx",         "s390",   "s390x",  "sh4",     "sparc",
    "sparc64", "wasm32",     "wasm64", "x86",    "x86_64",
};

static const std::set<std::string> OS_NAMES /*NOLINT*/ = {
    "android", "cygwin", "darwin", "dragonfly", "emscripten", "freebsd", "gnu",
    "haiku",   "linux",  "netbsd", "openbsd",   "windows",    "sunos",
};

static const std::set<std::string> PURE_FUNCTIONS /*NOLINT*/ = {
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

static const std::set<std::string> PURE_METHODS /* NOLINT */ = {
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

static const std::map<std::string, std::string> MODULES /*NOLINT*/ = {
    {"cmake", "cmake_module"},
    {"cuda", "cuda_module"},
    {"dlang", "dlang_module"},
    {"external_project", "external_project_module"},
    {"unstable_external_project", "external_project_module"},
    {"fs", "fs_module"},
    {"gnome", "gnome_module"},
    {"hotdoc", "hotdoc_module"},
    {"i18n", "i18n_module"},
    {"icestorm", "icestorm_module"},
    {"java", "java_module"},
    {"keyval", "keyval_module"},
    {"pkgconfig", "pkgconfig_module"},
    {"python", "python_module"},
    {"python3", "python3_module"},
    {"qt4", "qt4_module"},
    {"qt5", "qt5_module"},
    {"qt6", "qt6_module"},
    {"rust", "rust_module"},
    {"simd", "simd_module"},
    {"sourceset", "sourceset_module"},
    {"unstable-cuda", "cuda_module"},
    {"unstable-external_project", "external_project_module"},
    {"unstable-icestorm", "icestorm_module"},
    {"unstable-keyval", "keyval_module"},
    {"unstable-rust", "rust_module"},
    {"unstable-simd", "simd_module"},
    {"wayland", "wayland_module"},
    {"unstable-wayland", "wayland_module"},
    {"windows", "windows_module"},
};

using enum TypeName;
using enum NodeType;

static std::vector<std::shared_ptr<Type>>
dedup(const TypeNamespace &ns, std::vector<std::shared_ptr<Type>> types);
static bool isSnakeCase(const std::string &str);
static bool isShoutingSnakeCase(const std::string &str);
static bool isType(const std::shared_ptr<Type> &type, TypeName tag);
static bool sameType(const std::shared_ptr<Type> &first,
                     const std::shared_ptr<Type> &second, TypeName tag);

void TypeAnalyzer::modifiedVariableType(
    const std::string &varname,
    const std::vector<std::shared_ptr<Type>> &newTypes) {
  if (this->selectionStatementStack.empty()) {
    return;
  }
  auto &currStackItem = this->selectionStatementStack.back();
  auto currStackItemIter = currStackItem.find(varname);
  if (currStackItemIter == currStackItem.end()) {
    auto iter = this->scope.variables.find(varname);
    auto curr = iter != this->scope.variables.end()
                    ? iter->second
                    : std::vector<std::shared_ptr<Type>>{};
    curr.insert(curr.end(), newTypes.begin(), newTypes.end());
    currStackItem[varname] = std::move(curr);
  } else {
    auto &curr = currStackItemIter->second;
    auto iter = this->scope.variables.find(varname);
    if (iter != this->scope.variables.end()) {
      const auto &fromScope = iter->second;
      curr.insert(curr.end(), fromScope.begin(), fromScope.end());
    }
    curr.insert(curr.end(), newTypes.begin(), newTypes.end());
  }
  this->selectionStatementStack.back() = currStackItem;
}

void TypeAnalyzer::applyToStack(
    const std::string &name, const std::vector<std::shared_ptr<Type>> &types) {
  if (this->stack.empty()) {
    return;
  }
  auto scopeIter = this->scope.variables.find(name);
  if (scopeIter != this->scope.variables.end()) {
    auto orVCount = this->overriddenVariables.size() - 1;
    auto &atIdx = this->overriddenVariables[orVCount];
    const auto &vars = scopeIter->second;
    const auto iter = atIdx.find(name);
    if (iter != atIdx.end()) {
      iter->second.insert(atIdx[name].begin(), vars.begin(), vars.end());
    } else {
      atIdx[name] = vars;
    }
  }
  auto ssc = this->stack.size() - 1;
  const auto iter = this->stack[ssc].find(name);
  if (iter != this->stack[ssc].end()) {
    auto &old = iter->second;
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
    types.insert(types.end(), arg->types.begin(), arg->types.end());
  }
  node->types = std::vector<std::shared_ptr<Type>>{
      std::make_shared<List>(dedup(this->ns, std::move(types)))};
}

void TypeAnalyzer::extractVoidAssignment(
    const AssignmentStatement *node) const {
  std::string name;
  const auto *fe = dynamic_cast<const FunctionExpression *>(node->rhs.get());
  if (fe && fe->function) {
    name = fe->function->id();
  } else {
    const auto *me = dynamic_cast<const MethodExpression *>(node->rhs.get());
    if (me && me->method) {
      name = me->method->id();
    }
  }
  if (!name.starts_with("install_")) {
    this->metadata->registerDiagnostic(
        node->lhs.get(),
        Diagnostic(Severity::ERROR, node->lhs.get(), "Can't assign from void"));
  }
}

void TypeAnalyzer::checkIdentifier(const IdExpression *node) const {
  if (this->analysisOptions.disableNameLinting) {
    return;
  }
  if (isSnakeCase(node->id) || isShoutingSnakeCase(node->id)) {
    return;
  }
  this->metadata->registerDiagnostic(
      node, Diagnostic(Severity::WARNING, node, "Expected snake case"));
}

void TypeAnalyzer::evaluatePureAssignment(const AssignmentStatement *node,
                                          IdExpression *lhsIdExpr) {
  auto arr = node->rhs->types;
  if (arr.empty()) {
    if (node->rhs->type == ARRAY_LITERAL) {
      const auto *arrLit = static_cast<ArrayLiteral *>(node->rhs.get());
      if (arrLit->args.empty()) {
        arr.push_back(std::make_shared<List>());
      }
    } else if (node->rhs->type == DICTIONARY_LITERAL) {
      const auto *dictLit = static_cast<DictionaryLiteral *>(node->rhs.get());
      if (dictLit->values.empty()) {
        arr.push_back(std::make_shared<Dict>());
      }
    }
  }
  const auto &assignmentName = lhsIdExpr->id;
  if (assignmentName == "meson" || assignmentName == "build_machine" ||
      assignmentName == "target_machine" || assignmentName == "host_machine") {
    this->metadata->registerDiagnostic(
        lhsIdExpr,
        Diagnostic(Severity::ERROR, lhsIdExpr,
                   "Attempted to re-assign to existing, read-only variable"));
    return;
  }
  lhsIdExpr->types = arr;
  this->checkIdentifier(lhsIdExpr);
  this->modifiedVariableType(lhsIdExpr->id, arr);
  this->applyToStack(lhsIdExpr->id, arr);
  this->scope.variables[lhsIdExpr->id] = std::move(arr);
  this->registerNeedForUse(lhsIdExpr);
  if (node->rhs->type != METHOD_EXPRESSION) {
    return;
  }
  const auto *me = static_cast<const MethodExpression *>(node->rhs.get());
  if (me && me->method && me->method->id() == "meson.version") [[unlikely]] {
    this->mesonVersionVars.insert(lhsIdExpr->id);
  }
}

void TypeAnalyzer::registerNeedForUse(IdExpression *node) {
  this->variablesNeedingUse.back().push_back(node);
}

std::optional<std::shared_ptr<Type>>
TypeAnalyzer::evalPlusEquals(const std::shared_ptr<Type> &left,
                             const std::shared_ptr<Type> &right) {
  if (left->tag == LIST) {
    const auto *listL = static_cast<List *>(left.get());
    auto newTypes = listL->types;
    if (right->tag == LIST) {
      const auto *listR = static_cast<List *>(right.get());
      const auto &rTypes = listR->types;
      newTypes.insert(newTypes.end(), rTypes.begin(), rTypes.end());
    } else {
      newTypes.emplace_back(right);
    }
    return std::make_shared<List>(dedup(this->ns, std::move(newTypes)));
  }
  if (left->tag == DICT) {
    const auto *dictL = static_cast<Dict *>(left.get());
    auto newTypes = dictL->types;
    if (right->tag == DICT) {
      const auto *dictR = static_cast<Dict *>(right.get());
      const auto &rTypes = dictR->types;
      newTypes.insert(newTypes.end(), rTypes.begin(), rTypes.end());
    } else {
      newTypes.emplace_back(right);
    }
    return std::make_shared<Dict>(dedup(this->ns, newTypes));
  }
  if (left->tag == right->tag && left->tag == STR) {
    return this->ns.strType;
  }
  if (left->tag == right->tag && left->tag == INT) {
    return this->ns.intType;
  }
  return std::nullopt;
}

void TypeAnalyzer::evalAssignmentTypes(
    const std::shared_ptr<Type> &left, const std::shared_ptr<Type> &right,
    AssignmentOperator op, std::vector<std::shared_ptr<Type>> *newTypes) {
  switch (op) {
    using enum AssignmentOperator;
  [[likely]] case PLUS_EQUALS: {
    auto type = this->evalPlusEquals(left, right);
    if (type.has_value()) {
      newTypes->push_back(type.value());
    }
    break;
  }
  case DIV_EQUALS:
    if (sameType(left, right, INT)) {
      newTypes->push_back(this->ns.intType);
    }
    if (sameType(left, right, STR)) {
      newTypes->push_back(this->ns.strType);
    }
    break;
  case MINUS_EQUALS:
  case MOD_EQUALS:
  case MUL_EQUALS:
    if (sameType(left, right, INT)) {
      newTypes->push_back(this->ns.intType);
    }
    break;
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

void TypeAnalyzer::evaluateFullAssignment(const AssignmentStatement *node,
                                          IdExpression *lhsIdExpr) {
  this->metadata->registerIdentifier(lhsIdExpr);
  if (node->op == AssignmentOperator::EQUALS) {
    this->evaluatePureAssignment(node, lhsIdExpr);
    return;
  }
  auto newTypes =
      dedup(this->ns,
            this->evalAssignment(node->op, node->lhs->types, node->rhs->types));
  lhsIdExpr->types = newTypes;
  this->modifiedVariableType(lhsIdExpr->id, newTypes);
  this->applyToStack(lhsIdExpr->id, newTypes);
  this->scope.variables[lhsIdExpr->id] = std::move(newTypes);
}

void TypeAnalyzer::visitAssignmentStatement(AssignmentStatement *node) {
  node->visitChildren(this);
  if (node->lhs->type != ID_EXPRESSION) [[unlikely]] {
    this->metadata->registerDiagnostic(
        node->lhs.get(), Diagnostic(Severity::ERROR, node->lhs.get(),
                                    "Can only assign to variables"));
    return;
  }
  auto *idExpr = static_cast<IdExpression *>(node->lhs.get());
  if (node->op == AssignmentOperator::ASSIGNMENT_OP_OTHER) {
    this->metadata->registerDiagnostic(
        node->lhs.get(), Diagnostic(Severity::ERROR, node->lhs.get(),
                                    "Unknown assignment operator"));
    return;
  }
  const auto &rhsTypes = node->rhs->types;
  if (rhsTypes.empty() &&
      (dynamic_cast<FunctionExpression *>(node->rhs.get()) ||
       dynamic_cast<MethodExpression *>(node->rhs.get()))) {
    this->metadata->registerIdentifier(idExpr);
    this->extractVoidAssignment(node);
    return;
  }
  this->evaluateFullAssignment(node, idExpr);
}

bool TypeAnalyzer::isSpecial(const std::vector<std::shared_ptr<Type>> &types) {
  if (types.size() != 3) {
    return false;
  }
  auto counter = 0;
  for (const auto &type : types) {
    if (type->tag == ANY) {
      counter++;
      continue;
    }
    if (type->tag == LIST) {
      auto *asList = static_cast<List *>(type.get());
      if (asList->types.size() == 1 && asList->types[0]->tag == ANY) {
        counter++;
      }
      continue;
    }
    if (type->tag == DICT) {
      auto *asDict = static_cast<Dict *>(type.get());
      if (asDict->types.size() == 1 && asDict->types[0]->tag == ANY) {
        counter++;
      }
      continue;
    }
    return false;
  }
  return counter == 3;
}

void TypeAnalyzer::evalBinaryExpression(
    BinaryOperator op, const std::shared_ptr<Type> &lType,
    const std::shared_ptr<Type> &rType,
    std::vector<std::shared_ptr<Type>> &newTypes, unsigned int *numErrors) {
  switch (op) {
    using enum BinaryOperator;
  [[likely]] case PLUS: {
    if (sameType(lType, rType, STR) || sameType(lType, rType, INT)) {
      newTypes.emplace_back(this->ns.types.at(lType->name));
      break;
    }
    if (lType->tag == LIST) {
      const auto *list1 = static_cast<List *>(lType.get());
      auto types = list1->types;
      if (rType->tag == LIST) {
        const auto *list2 = static_cast<List *>(rType.get());
        types.insert(types.end(), list2->types.begin(), list2->types.end());
      } else {
        types.push_back(rType);
      }
      newTypes.emplace_back(std::make_shared<List>(std::move(types)));
      break;
    }
    if (lType->tag == rType->tag && lType->tag == DICT) {
      const auto *dict1 = static_cast<Dict *>(lType.get());
      const auto *dict2 = static_cast<Dict *>(rType.get());
      auto types = dict1->types;
      types.insert(types.end(), dict2->types.begin(), dict2->types.end());
      newTypes.emplace_back(std::make_shared<Dict>(types));
      break;
    }
    ++*numErrors;
    break;
  }
  [[likely]] case EQUALS_EQUALS:
  case NOT_EQUALS:
    if (sameType(lType, rType, STR) || sameType(lType, rType, INT) ||
        sameType(lType, rType, BOOL) || sameType(lType, rType, DICT) ||
        sameType(lType, rType, LIST) ||
        ((dynamic_cast<AbstractObject *>(lType.get()) != nullptr) &&
         lType->tag == rType->tag)) {
      newTypes.emplace_back(this->ns.boolType);
      break;
    }
    ++*numErrors;
    break;
  case AND:
  case OR:
    if (sameType(lType, rType, BOOL)) {
      newTypes.emplace_back(this->ns.boolType);
      break;
    }
    ++*numErrors;
    break;
  case DIV:
    if (sameType(lType, rType, INT) || sameType(lType, rType, STR)) {
      newTypes.emplace_back(lType);
      break;
    }
    ++*numErrors;
    break;
  case GE:
  case GT:
  case LE:
  case LT:
    if (sameType(lType, rType, INT) || sameType(lType, rType, STR)) {
      newTypes.emplace_back(this->ns.boolType);
      break;
    }
    ++*numErrors;
    break;
  case IN:
  case NOT_IN:
    newTypes.emplace_back(this->ns.boolType);
    break;
  case MINUS:
  case MODULO:
  case MUL:
    if (sameType(lType, rType, INT)) {
      newTypes.emplace_back(this->ns.intType);
      break;
    }
    ++*numErrors;
    break;
  default:
    LOG.error("Whoops???");
    ++*numErrors;
    break;
  }
}

std::vector<std::shared_ptr<Type>> TypeAnalyzer::evalBinaryExpression(
    BinaryOperator op, std::vector<std::shared_ptr<Type>> lhs,
    const std::vector<std::shared_ptr<Type>> &rhs, unsigned int *numErrors) {
  std::vector<std::shared_ptr<Type>> newTypes;
  for (const auto &lType : lhs) {
    for (const auto &rType : rhs) {
      if (rType->tag == lType->tag && lType->tag == ANY) {
        ++*numErrors;
        continue;
      }
      evalBinaryExpression(op, lType, rType, newTypes, numErrors);
    }
  }
  if (*numErrors == lhs.size() * rhs.size()) {
    return lhs;
  }
  return newTypes;
}

void TypeAnalyzer::visitBinaryExpression(BinaryExpression *node) {
  node->visitChildren(this);
  if (node->op == BinaryOperator::BIN_OP_OTHER) {
    auto types = node->lhs->types;
    types.insert(types.end(), node->rhs->types.begin(), node->rhs->types.end());
    node->types = types;
    this->metadata->registerDiagnostic(
        node, Diagnostic(Severity::ERROR, node, "Unknown operator"));
    return;
  }
  auto nErrors = 0U;
  auto newTypes = this->evalBinaryExpression(node->op, node->lhs->types,
                                             node->rhs->types, &nErrors);
  auto nTimes = node->lhs->types.size() * node->rhs->types.size();
  if (nTimes != 0 && nErrors == nTimes && (!node->lhs->types.empty()) &&
      (!node->rhs->types.empty()) &&
      !TypeAnalyzer::isSpecial(node->lhs->types) &&
      !TypeAnalyzer::isSpecial(node->rhs->types)) {
    auto lTypes = joinTypes(node->lhs->types);
    auto rTypes = joinTypes(node->rhs->types);
    auto msg = std::format("Unable to apply operator {} to types {} and {}",
                           enum2String(node->op), lTypes, rTypes);
    this->metadata->registerDiagnostic(node,
                                       Diagnostic(Severity::ERROR, node, msg));
  }
  node->types = dedup(this->ns, newTypes);
  auto *parent = node->parent;
  if (parent->type == ASSIGNMENT_STATEMENT ||
      parent->type == SELECTION_STATEMENT) {
    if (node->lhs->type == METHOD_EXPRESSION &&
        node->rhs->type == STRING_LITERAL) {
      auto *me = static_cast<MethodExpression *>(node->lhs.get());
      auto *sl = static_cast<StringLiteral *>(node->rhs.get());
      this->checkIfSpecialComparison(me, sl);
    } else if (node->rhs->type == METHOD_EXPRESSION &&
               node->lhs->type == STRING_LITERAL) {
      auto *me = static_cast<MethodExpression *>(node->rhs.get());
      auto *sl = static_cast<StringLiteral *>(node->lhs.get());
      this->checkIfSpecialComparison(me, sl);
    }
  }
}

void TypeAnalyzer::checkIfSpecialComparison(const MethodExpression *me,
                                            const StringLiteral *sl) const {
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
        sl, Diagnostic(Severity::WARNING, sl, "Unknown compiler id"));
  } else if (mid == "compiler.get_argument_syntax" &&
             !this->analysisOptions.disableCompilerArgumentIdLinting &&
             !ARGUMENT_SYNTAXES.contains(arg)) {
    this->metadata->registerDiagnostic(
        sl,
        Diagnostic(Severity::WARNING, sl, "Unknown compiler argument syntax"));
  } else if (mid == "compiler.get_linker_id" &&
             !this->analysisOptions.disableLinkerIdLinting &&
             !LINKER_IDS.contains(arg)) {
    this->metadata->registerDiagnostic(
        sl, Diagnostic(Severity::WARNING, sl, "Unknown linker id"));
  } else if (mid == "build_machine.cpu_family" &&
             !this->analysisOptions.disableCpuFamilyLinting &&
             !CPU_FAMILIES.contains(arg)) {
    this->metadata->registerDiagnostic(
        sl, Diagnostic(Severity::WARNING, sl, "Unknown CPU family"));
  } else if (mid == "build_machine.system" &&
             !this->analysisOptions.disableOsFamilyLinting &&
             !OS_NAMES.contains(arg)) {
    this->metadata->registerDiagnostic(
        sl, Diagnostic(Severity::WARNING, sl, "Unknown OS family"));
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
        node, Diagnostic(Severity::ERROR, node,
                         "Missing project() call at top of file"));
    return;
  }
  auto first = node->stmts[0];
  auto *asCall = dynamic_cast<FunctionExpression *>(first.get());
  if (asCall == nullptr || asCall->functionName() != "project") {
    this->metadata->registerDiagnostic(
        node, Diagnostic(Severity::ERROR, node,
                         "Missing project() call at top of file"));
    return;
  }
  auto alNode = asCall->args;
  if (!alNode) {
    return;
  }
  const auto *al = dynamic_cast<ArgumentList *>(alNode.get());
  if (!al) {
    return;
  }
  auto mesonVersionKwarg = al->getKwarg("meson_version");
  if (!mesonVersionKwarg) {
    return;
  }
  const auto *mesonVersionSL =
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
  if (node->type == INTEGER_LITERAL || node->type == STRING_LITERAL ||
      node->type == BOOLEAN_LITERAL || node->type == ARRAY_LITERAL ||
      node->type == DICTIONARY_LITERAL) {
    noEffect = true;
    goto end;
  }
  if (node->type == FUNCTION_EXPRESSION) {
    const auto *fe = static_cast<FunctionExpression *>(node);
    auto fnid = fe->function;
    if (fnid && PURE_FUNCTIONS.contains(fnid->name)) {
      noEffect = true;
      goto end;
    }
    return;
  }
  if (node->type == METHOD_EXPRESSION) {
    const auto *me = static_cast<MethodExpression *>(node);
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
      node, Diagnostic(Severity::WARNING, node,
                       "Statement does not have an effect or the result to the "
                       "call is unused"));
}

bool TypeAnalyzer::isDead(const std::shared_ptr<Node> &node) {
  if (node->type != FUNCTION_EXPRESSION) {
    return false;
  }
  const auto *asFuncExpr = static_cast<FunctionExpression *>(node.get());
  const auto &name = asFuncExpr->functionName();
  return name == "error" || name == "subdir_done";
}

void TypeAnalyzer::applyDead(const std::shared_ptr<Node> &lastAlive,
                             const std::shared_ptr<Node> &firstDead,
                             const std::shared_ptr<Node> &lastDead) const {
  if (!lastAlive || !firstDead || !lastDead) {
    return;
  }
  if (!lastAlive.get() || !firstDead.get() || !lastDead.get()) {
    return;
  }
  this->metadata->registerDiagnostic(
      firstDead.get(), Diagnostic(Severity::WARNING, firstDead.get(),
                                  lastDead.get(), "Dead code", false, true));
}

void TypeAnalyzer::checkDeadNodes(const BuildDefinition *node) {
  std::shared_ptr<Node> lastAlive = nullptr;
  std::shared_ptr<Node> firstDead = nullptr;
  std::shared_ptr<Node> lastDead = nullptr;
  for (const auto &stmt : node->stmts) {
    this->checkNoEffect(stmt.get());
    if (!lastAlive) {
      if (TypeAnalyzer::isDead(stmt)) {
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
    auto &toAppend = this->variablesNeedingUse.back();
    toAppend.insert(toAppend.end(), needingUse.begin(), needingUse.end());
    this->variablesNeedingUse.back() = toAppend;
    return;
  }
  if (this->analysisOptions.disableUnusedVariableCheck) {
    return;
  }
  for (const auto *needed : needingUse) {
    if (needed->parent->type != ASSIGNMENT_STATEMENT) {
      continue;
    }
    const auto *ass = static_cast<AssignmentStatement *>(needed->parent);
    if (ass->rhs->type != FUNCTION_EXPRESSION) {
      continue;
    }
    const auto *rhs = static_cast<FunctionExpression *>(ass->rhs.get());
    if (rhs) {
      const auto &fnid = rhs->functionName();
      if (fnid == "declare_dependency") {
        continue;
      }
    }
    this->metadata->registerDiagnostic(
        needed, Diagnostic(Severity::WARNING, needed, "Unused assignment"));
  }
}

void TypeAnalyzer::visitBuildDefinition(BuildDefinition *node) {
  this->metadata->beginFile(node);
  this->variablesNeedingUse.emplace_back();
  this->sourceFileStack.push_back(node->file->file);
  this->tree->ownedFiles.insert(node->file->file);
  this->checkProjectCall(node);
  node->visitChildren(this);
  this->checkDeadNodes(node);
  this->checkUnusedVariables();
  this->sourceFileStack.pop_back();
  this->metadata->endFile(node->file->file);
  for (const auto &err : node->parsingErrors) {
    this->metadata->registerDiagnostic(node->file->file, err);
  }
}

void TypeAnalyzer::visitConditionalExpression(ConditionalExpression *node) {
  node->visitChildren(this);
  std::vector<std::shared_ptr<Type>> types(node->ifTrue->types);
  types.insert(types.end(), node->ifFalse->types.begin(),
               node->ifFalse->types.end());
  node->types = types;
  for (const auto &type : node->condition->types) {
    if (type->tag == ANY || type->tag == BOOL || type->tag == DISABLER) {
      return;
    }
  }
  this->metadata->registerDiagnostic(
      node, Diagnostic(Severity::ERROR, node,
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
        keyNode, Diagnostic(Severity::WARNING, keyNode,
                            std::format("Duplicate key \"{}\"", keyName)));
  }
}

void TypeAnalyzer::visitDictionaryLiteral(DictionaryLiteral *node) {
  node->visitChildren(this);
  std::vector<std::shared_ptr<Type>> types;
  for (const auto &arg : node->values) {
    types.insert(types.end(), arg->types.begin(), arg->types.end());
  }
  node->types = std::vector<std::shared_ptr<Type>>{
      std::make_shared<Dict>(dedup(this->ns, types))};
  this->checkDuplicateNodeKeys(node);
}

void TypeAnalyzer::setFunctionCallTypesImport(FunctionExpression *node) {
  const auto &values = ::guessSetVariable(node, this->options);
  std::set<std::string> const asSet{values.begin(), values.end()};
  std::vector<std::shared_ptr<Type>> types;
  for (const auto &modname : asSet) {
    if (MODULES.contains(modname)) {
      types.emplace_back(this->ns.types.at(MODULES.at(modname)));
      continue;
    }
    types.emplace_back(this->ns.types.at("module"));
    this->metadata->registerDiagnostic(
        node, Diagnostic(Severity::WARNING, node,
                         std::format("Unknown module `{}`", modname)));
  }
  node->types = dedup(this->ns, types);
}

void TypeAnalyzer::setFunctionCallTypesGetOption(
    FunctionExpression *node, const std::shared_ptr<Function> &func) {
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
          node, Diagnostic(Severity::ERROR, node,
                           std::format("Unknown option `{}`", val)));
      continue;
    }
    if (asSet.size() == 1 && opt->deprecated) {
      this->metadata->registerDiagnostic(
          node, Diagnostic(Severity::WARNING, node,
                           std::format("Deprecated option"), true, false));
    }
    if (dynamic_cast<StringOption *>(opt.get()) ||
        dynamic_cast<ComboOption *>(opt.get())) {
      types.emplace_back(this->ns.strType);
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
    if (dynamic_cast<IntOption *>(opt.get())) {
      types.emplace_back(this->ns.intType);
      continue;
    }
  }
  if (!types.empty()) {
    node->types = dedup(this->ns, types);
  } else {
    node->types = func->returnTypes;
  }
}

void TypeAnalyzer::setFunctionCallTypesSubproject(FunctionExpression *node) {
  const auto &values = ::guessSetVariable(node, this->options);
  if (values.empty()) {
    return;
  }
  std::set<std::string> const asSet{values.begin(), values.end()};
  node->types = {std::make_shared<Subproject>(
      std::vector<std::string>{asSet.begin(), asSet.end()})};
  LOG.info("Values for `subproject` call: " + joinStrings(asSet, '|'));
  if (!this->tree->state.used || asSet.size() > 1) {
    return;
  }
  auto &subprojState = this->tree->state;
  if (subprojState.hasSubproject(*asSet.begin())) {
    return;
  }
  if ((this->tree->parent != nullptr) &&
      this->tree->parent->state.hasSubproject(*asSet.begin())) {
    return;
  }
  this->metadata->registerDiagnostic(
      node, Diagnostic(Severity::ERROR, node,
                       std::format("Unknown subproject `{}`", *asSet.begin())));
}

void TypeAnalyzer::setFunctionCallTypesBuildTarget(FunctionExpression *node) {
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
    node->types = {this->ns.types.at("exe"), this->ns.types.at("lib"),
                   this->ns.types.at("build_tgt"),
                   this->ns.types.at("both_libs"), this->ns.types.at("jar")};
  }
}

void TypeAnalyzer::setFunctionCallTypesGetVariable(
    FunctionExpression *node, const std::shared_ptr<Function> &func) {
  std::vector<std::shared_ptr<Type>> types;
  auto *al = dynamic_cast<ArgumentList *>(node->args.get());
  if (!al) {
    return;
  }
  if (al->args.size() == 2 && !dynamic_cast<KeywordItem *>(al->args[1].get())) {
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
  LOG.info(std::format("get_variable: {} = {} ({}:{})", joinStrings(asSet, '|'),
                       joinTypes(node->types), node->file->file.native(),
                       node->location.format()));
}

void TypeAnalyzer::setFunctionCallTypes(FunctionExpression *node,
                                        const std::shared_ptr<Function> &func) {
  const auto &name = func->name;
  if (name == "get_option") {
    this->setFunctionCallTypesGetOption(node, func);
    return;
  }
  if (name == "import") {
    this->setFunctionCallTypesImport(node);
    return;
  }
  if (name == "subproject") {
    this->setFunctionCallTypesSubproject(node);
    return;
  }
  if (name == "build_target") {
    this->setFunctionCallTypesBuildTarget(node);
    return;
  }
  if (name == "get_variable") {
    this->setFunctionCallTypesGetVariable(node, func);
    return;
  }
}

void TypeAnalyzer::checkKwargsAfterPositionalArguments(
    const std::vector<std::shared_ptr<Node>> &args) const {
  auto kwargsOnly = false;
  for (const auto &arg : args) {
    if (arg->type == KEYWORD_ITEM) {
      kwargsOnly = true;
      continue;
    }
    if (!kwargsOnly) {
      continue;
    }
    this->metadata->registerDiagnostic(
        arg.get(),
        Diagnostic(Severity::ERROR, arg.get(),
                   "Unexpected positional argument after a keyword argument"));
  }
}

void TypeAnalyzer::createDeprecationWarning(
    const DeprecationState &deprecationState, const Node *node,
    const std::string &type) const {
  const auto &alternatives = deprecationState.replacements;
  auto sinceWhen = deprecationState.sinceWhen;
  const auto &currVersion = this->matchingVersion();
  if (sinceWhen.has_value() && sinceWhen->after(currVersion)) {
    return;
  }
  auto versionString =
      sinceWhen.has_value()
          ? std::format(" (Since {})", sinceWhen->versionString)
          : "";
  auto alternativesStr =
      alternatives.empty() ? ""
                           : (" Try one of: " + joinStrings(alternatives, ','));
  this->metadata->registerDiagnostic(
      node, Diagnostic(Severity::WARNING, node,
                       std::format("Deprecated {}{}{}", type, versionString,
                                   alternativesStr),
                       true, false));
}

void TypeAnalyzer::checkKwargs(const std::shared_ptr<Function> &func,
                               const std::vector<std::shared_ptr<Node>> &args,
                               Node *node) const {
  std::vector<std::string> usedKwargs; // Should be flat_set
  usedKwargs.reserve(args.size());
  bool hasKwargArgument = false;
  for (const auto &arg : args) {
    if (arg->type != KEYWORD_ITEM) {
      continue;
    }
    auto *kwi = static_cast<KeywordItem *>(arg.get());
    if (kwi->key->type != ID_EXPRESSION) {
      continue;
    }
    auto *kId = static_cast<IdExpression *>(kwi->key.get());
    usedKwargs.push_back(kId->id);
    auto iter = func->kwargs.find(kId->id);
    if (iter != func->kwargs.end()) {
      const auto &kwarg = iter->second;
      if (kwarg->deprecationState.deprecated) {
        this->createDeprecationWarning(kwarg->deprecationState, kwi->key.get(),
                                       "keyword argument");
      }
      continue;
    }
    if (kId->id == "kwargs") {
      hasKwargArgument = true;
      continue;
    }
    this->metadata->registerDiagnostic(
        arg.get(),
        Diagnostic(Severity::ERROR, arg.get(),
                   std::format("Unknown key word argument '{}'", kId->id)));
  }
  if (hasKwargArgument) {
    return;
  }
  for (const auto &requiredKwarg : func->requiredKwargs) {
    if (std::ranges::find(usedKwargs, requiredKwarg) != usedKwargs.end()) {
      continue;
    }
    this->metadata->registerDiagnostic(
        node, Diagnostic(Severity::ERROR, node,
                         std::format("Missing required key word argument '{}'",
                                     requiredKwarg)));
  }
}

bool TypeAnalyzer::compatible(const std::shared_ptr<Type> &given,
                              const std::shared_ptr<Type> &expected) {
  if (expected->simple && given->simple && expected->name == given->name) {
    return true;
  }
  if (given->toString() == expected->toString()) {
    return true;
  }
  if (given->complexObject) {
    auto *gAO = static_cast<AbstractObject *>(given.get());
    auto parent = gAO->parent;
    if (parent.has_value() && this->compatible(parent.value(), expected)) {
      return true;
    }
  }
  if (given->tag == LIST) {
    const auto *gList = static_cast<List *>(given.get());
    if (expected->tag == LIST) {
      const auto *eList = static_cast<List *>(expected.get());
      return this->atleastPartiallyCompatible(eList->types, gList->types);
    }
    return this->atleastPartiallyCompatible(expected, gList->types);
  }
  if (expected->tag == LIST) {
    const auto *eList = static_cast<List *>(expected.get());
    return this->atleastPartiallyCompatible(eList->types, given);
  }
  if (given->tag == expected->tag && given->tag == DICT) {
    const auto *gDict = static_cast<Dict *>(given.get());
    const auto *eDict = static_cast<Dict *>(expected.get());
    return this->atleastPartiallyCompatible(eDict->types, gDict->types);
  }
  return false;
}

bool TypeAnalyzer::atleastPartiallyCompatible(
    const std::shared_ptr<Type> &expectedType,
    const std::vector<std::shared_ptr<Type>> &givenTypes) {
  if (givenTypes.empty()) {
    return true;
  }
  if (expectedType->tag == ANY || expectedType->tag == DISABLER) {
    return true;
  }
  return std::ranges::any_of(
      givenTypes, [&expectedType, this](const auto &given) {
        return this->compatible(given, expectedType) || given->tag == ANY;
      });
}

bool TypeAnalyzer::atleastPartiallyCompatible(
    const std::vector<std::shared_ptr<Type>> &expectedTypes,
    const std::shared_ptr<Type> &givenType) {
  return std::ranges::any_of(
      expectedTypes, [this, &givenType](const auto &expected) {
        if (expected->tag == ANY || expected->tag == DISABLER) {
          return true;
        }
        return this->compatible(givenType, expected) || givenType->tag == ANY;
      });
}

bool TypeAnalyzer::atleastPartiallyCompatible(
    const std::vector<std::shared_ptr<Type>> &expectedTypes,
    const std::vector<std::shared_ptr<Type>> &givenTypes) {
  if (givenTypes.empty()) {
    return true;
  }
  return std::ranges::any_of(
      givenTypes, [&expectedTypes, this](const auto &given) {
        if (given->tag == ANY || given->tag == DISABLER) {
          return true;
        }
        return this->atleastPartiallyCompatible(expectedTypes, given);
      });
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
      Diagnostic(Severity::ERROR, arg.get(),
                 std::format("Expected {}, got {}", joinTypes(expectedTypes),
                             joinTypes(givenTypes))));
}

void TypeAnalyzer::checkArgTypes(
    const std::shared_ptr<Function> &func,
    const std::vector<std::shared_ptr<Node>> &args) {
  auto posArgsIdx = 0;
  for (const auto &arg : args) {
    if (arg->type == KEYWORD_ITEM) {
      auto *kwi = static_cast<KeywordItem *>(arg.get());
      const auto &givenTypes = kwi->value->types;
      const auto &kwargName = /*NOLINT*/ kwi->name.value();
      auto iter = func->kwargs.find(kwargName);
      if (iter == func->kwargs.end()) {
        continue;
      }
      const auto &expectedTypes = iter->second->types;
      this->checkTypes(arg, expectedTypes, givenTypes);
    } else {
      const auto *posArg = func->posArg(posArgsIdx);
      if (posArg) {
        this->checkTypes(arg, posArg->types, arg->types);
      }
      posArgsIdx++;
    }
  }
}

unsigned long long TypeAnalyzer::countPositionalArguments(
    const std::vector<std::shared_ptr<Node>> &args) {
  auto nPos = 0ULL;
  for (const auto &arg : args) {
    if (arg->type != KEYWORD_ITEM) {
      nPos++;
    }
  }
  return nPos;
}

void TypeAnalyzer::validatePositionalArgumentCount(
    unsigned long long nPos, const std::shared_ptr<Function> &func,
    const Node *node) const {
  if (nPos < func->minPosArgs) {
    this->metadata->registerDiagnostic(
        node,
        Diagnostic(Severity::ERROR, node,
                   std::format(
                       "Expected at least {} positional arguments, but got {}!",
                       func->minPosArgs, nPos)));
  }
  if (nPos > func->maxPosArgs) {
    this->metadata->registerDiagnostic(
        node,
        Diagnostic(
            Severity::ERROR, node,
            std::format("Expected maximum {} positional arguments, but got {}!",
                        func->maxPosArgs, nPos)));
  }
}

void TypeAnalyzer::checkCall(Node *node) {
  std::shared_ptr<Function> func;
  auto nPos = 0ULL;
  if (node->type == FUNCTION_EXPRESSION) {
    const auto *fe = static_cast<FunctionExpression *>(node);
    func = fe->function;
    if (fe->args && fe->args->type == ARGUMENT_LIST && func) {
      const auto *al = static_cast<ArgumentList *>(fe->args.get());
      const auto &args = al->args;
      this->checkKwargsAfterPositionalArguments(args);
      this->checkKwargs(func, args, node);
      this->checkArgTypes(func, args);
      nPos = TypeAnalyzer::countPositionalArguments(args);
    }
  }

  if (node->type == METHOD_EXPRESSION) {
    const auto *me = static_cast<MethodExpression *>(node);
    func = me->method;
    if (me->args && me->args->type == ARGUMENT_LIST && func) {
      const auto *al = static_cast<ArgumentList *>(me->args.get());
      const auto &args = al->args;
      this->checkKwargsAfterPositionalArguments(args);
      this->checkKwargs(func, args, node);
      this->checkArgTypes(func, args);
      nPos = TypeAnalyzer::countPositionalArguments(args);
    }
  }
  if (node->type != FUNCTION_EXPRESSION && node->type != METHOD_EXPRESSION) {
    return;
  }
  if (!func) {
    return;
  }
  this->validatePositionalArgumentCount(nPos, func, node);
}

void TypeAnalyzer::guessSetVariable(std::vector<std::shared_ptr<Node>> args,
                                    FunctionExpression *node) {
  auto guessed = ::guessSetVariable(node, this->options);
  std::set<std::string> const asSet(guessed.begin(), guessed.end());
  LOG.info(std::format("Guessed values for set_variable: {} at {}:{}",
                       joinStrings(asSet, '|'), node->file->file.native(),
                       node->location.format()));
  for (const auto &varname : asSet) {
    const auto &types = args[1]->types;
    this->modifiedVariableType(varname, types);
    this->scope.variables[varname] = types;
    this->applyToStack(varname, types);
  }
}

void TypeAnalyzer::checkSetVariable(FunctionExpression *node,
                                    const ArgumentList *al) {
  auto args = al->args;
  if (args.empty()) {
    return;
  }
  auto firstArg = args[0];
  const auto *variableName = dynamic_cast<StringLiteral *>(firstArg.get());
  if (!variableName) {
    this->guessSetVariable(args, node);
  } else if (args.size() > 1) {
    auto varname = variableName->id;
    auto types = args[1]->types;
    this->modifiedVariableType(varname, types);
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
  std::vector<std::string> asSet;
  for (const auto &dir : guessed) {
    if (std::ranges::find(asSet, dir) != asSet.end()) {
      continue;
    }
    asSet.emplace_back(dir);
  }
  if (asSet.empty()) {
    const auto &msg =
        std::format("Found no dirs at subdircall at {}:{}",
                    node->file->file.native(), node->location.format());
    LOG.warn(msg);
  }
  this->metadata->registerSubdirCall(node, asSet);
  const auto &parentPath = node->file->file.parent_path();
  for (const auto &dir : asSet) {
    const auto &dirpath = parentPath / dir;
    if (!std::filesystem::exists(dirpath)) {
      if (asSet.size() == 1) {
        this->metadata->registerDiagnostic(
            node, Diagnostic(Severity::ERROR, node,
                             std::format("Directory does not exist: {}", dir)));
      }
      continue;
    }
    const auto &mesonpath = dirpath / "meson.build";
    if (!std::filesystem::exists(mesonpath)) {
      if (asSet.size() == 1) {
        this->metadata->registerDiagnostic(
            node, Diagnostic(
                      Severity::ERROR, node,
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
        node, Diagnostic(Severity::ERROR, node,
                         std::format("Unknown function `{}`", funcName)));
    return;
  }
  auto functionOpt = this->ns.lookupFunction(funcName);
  if (!functionOpt.has_value()) {
    this->metadata->registerDiagnostic(
        node, Diagnostic(Severity::ERROR, node,
                         std::format("Unknown function `{}`", funcName)));
    return;
  }
  auto func = functionOpt.value();
  node->types = func->returnTypes;
  this->setFunctionCallTypes(node, func);
  node->function = func;
  if (node->function->deprecationState.deprecated) {
    this->createDeprecationWarning(node->function->deprecationState, node,
                                   "function");
  }
  const auto &version = this->matchingVersion();
  if (func->since.after(version)) {
    this->metadata->registerDiagnostic(
        node, Diagnostic(Severity::WARNING, node,
                         std::format("Meson version {} is requested, but {}() "
                                     "is only available since {}",
                                     version.versionString, func->id(),
                                     func->since.versionString)));
  }
  const auto &args = node->args;
  if (!args || args->type != ARGUMENT_LIST) {
    if (func->minPosArgs > 0) {
      this->metadata->registerDiagnostic(
          node,
          Diagnostic(
              Severity::ERROR, node,
              std::format("Expected {} positional arguments, but got none!",
                          func->minPosArgs)));
    }
  } else {
    this->checkCall(node);
    if (args->type != ARGUMENT_LIST) {
      goto cont;
    }
    auto *asArgumentList = static_cast<ArgumentList *>(args.get());
    for (const auto &arg : asArgumentList->args) {
      if (arg->type != KEYWORD_ITEM) {
        continue;
      }
      auto *asKwi = static_cast<KeywordItem *>(arg.get());
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

std::vector<std::shared_ptr<Type>>
TypeAnalyzer::evalStack(const std::string &name) {
  std::vector<std::shared_ptr<Type>> ret;
  for (const auto &overridden : this->overriddenVariables) {
    auto iter = overridden.find(name);
    if (iter == overridden.end()) {
      continue;
    }
    ret.insert(ret.end(), iter->second.begin(), iter->second.end());
  }
  return ret;
}

bool TypeAnalyzer::ignoreIdExpression(IdExpression *node) {
  auto *parent = node->parent;
  if (!parent) [[unlikely]] {
    return false;
  }

  if (parent->type == METHOD_EXPRESSION) {
    const auto *me = static_cast<MethodExpression *>(parent);
    if (me->id->equals(node)) {
      return true;
    }
    goto end;
  }
  {
    if (parent->type == KEYWORD_ITEM) {
      const auto *kwi = static_cast<KeywordItem *>(parent);
      if (kwi->key->equals(node)) {
        return true;
      }
      goto end;
    }
    if (parent->type == ASSIGNMENT_STATEMENT) {
      const auto *ass = static_cast<AssignmentStatement *>(parent);
      if (ass->lhs->equals(node)) {
        return true;
      }
      goto end;
    }
    // The only children of FunctionExpression are <ID>(<ARGS>)
    if (parent->type == FUNCTION_EXPRESSION) {
      return true;
    }
    if (parent->type == ITERATION_STATEMENT) {
      return !static_cast<const IterationStatement *>(parent)
                  ->expression->equals(node);
    }
  }
end:
  return std::ranges::find(this->ignoreUnknownIdentifier, node->id) !=
         this->ignoreUnknownIdentifier.end();
}

bool TypeAnalyzer::isKnownId(IdExpression *idExpr) const {
  auto *parent = idExpr->parent;
  if (!parent) {
    return true;
  }
  if (parent->type == METHOD_EXPRESSION) {
    const auto *me = static_cast<MethodExpression *>(parent);
    if (me->id->type != ID_EXPRESSION) {
      goto err;
    }
    const auto *idexpr = static_cast<IdExpression *>(me->id.get());
    if (idexpr->hash == idExpr->hash && idexpr->id == idExpr->id) {
      return true;
    }
  }
err:
  if (parent->type == KEYWORD_ITEM) {
    const auto *kwi = static_cast<KeywordItem *>(parent);
    if (kwi->key->type != ID_EXPRESSION) {
      goto err2;
    }
    const auto *key = static_cast<IdExpression *>(kwi->key.get());
    if (key->hash == idExpr->hash && key->id == idExpr->id) {
      return true;
    }
  }
err2:
  if (parent->type == ASSIGNMENT_STATEMENT) {
    const auto *ass = static_cast<AssignmentStatement *>(parent);
    if (ass->lhs->type != ID_EXPRESSION) {
      goto err3;
    }
    const auto *lhsIdExpr = static_cast<IdExpression *>(ass->lhs.get());
    if (lhsIdExpr->hash == idExpr->hash && lhsIdExpr->id == idExpr->id &&
        ass->op == AssignmentOperator::EQUALS) {
      return true;
    }
  }
err3:
  return this->scope.variables.contains(idExpr->id);
}

void TypeAnalyzer::checkUsage(const IdExpression *node) {
  const auto *parent = node->parent;
  if (!parent) {
    this->registerUsed(node);
    return;
  }
  if (parent->type == ASSIGNMENT_STATEMENT) {
    const auto *ass = static_cast<const AssignmentStatement *>(parent);
    if (ass->op != AssignmentOperator::EQUALS || ass->rhs->equals(node)) {
      this->registerUsed(node);
    }
    return;
  }

  if (parent->type == KEYWORD_ITEM &&
      static_cast<const KeywordItem *>(parent)->value->equals(node)) {
    this->registerUsed(node);
    return;
  }
  if (parent->type == KEY_VALUE_ITEM &&
      static_cast<const KeyValueItem *>(parent)->value->equals(node)) {
    this->registerUsed(node);
    return;
  }
  if (parent->type == FUNCTION_EXPRESSION) {
    return; // Do nothing
  }
  if (parent->type == ITERATION_STATEMENT &&
      static_cast<const IterationStatement *>(parent)->expression->equals(
          node)) {
    this->registerUsed(node);
    return;
  }
  if (parent->type == METHOD_EXPRESSION &&
      static_cast<const MethodExpression *>(parent)->obj->equals(node)) {
    this->registerUsed(node);
    return;
  }
  if (parent->type == BINARY_EXPRESSION || parent->type == UNARY_EXPRESSION ||
      parent->type == ARGUMENT_LIST || parent->type == ARRAY_LITERAL ||
      parent->type == CONDITIONAL_EXPRESSION ||
      parent->type == SUBSCRIPT_EXPRESSION ||
      parent->type == SELECTION_STATEMENT) {
    this->registerUsed(node);
  }
}

void TypeAnalyzer::visitIdExpression(IdExpression *node) {
  auto types = this->evalStack(node->id);
  auto iter = this->scope.variables.find(node->id);
  if (iter != this->scope.variables.end()) {
    const auto &scopeVariables = iter->second;
    types.insert(types.end(), scopeVariables.begin(), scopeVariables.end());
  }
  node->types = dedup(this->ns, types);
  node->visitChildren(this);
  this->checkUsage(node);
  if (this->ignoreIdExpression(node)) {
    return;
  }
  if (!this->isKnownId(node)) {
    this->metadata->registerDiagnostic(
        node, Diagnostic(Severity::ERROR, node,
                         std::format("Unknown identifier `{}`", node->id)));
  }
  this->metadata->registerIdentifier(node);
}

void TypeAnalyzer::registerUsed(const std::string &varname) {
  this->registerUsed(varname, djb2(varname));
}

void TypeAnalyzer::registerUsed(const IdExpression *idExpr) {
  this->registerUsed(idExpr->id, idExpr->hash);
}

void TypeAnalyzer::registerUsed(const std::string &varname, uint32_t hashed) {
  for (auto &arr : this->variablesNeedingUse) {
    std::erase_if(arr, [&varname, hashed](const auto &idExpr) {
      return idExpr->hash == hashed && idExpr->id == varname;
    });
  }
}

void TypeAnalyzer::visitIntegerLiteral(IntegerLiteral *node) {
  node->visitChildren(this);
  node->types.emplace_back(this->ns.intType);
}

void TypeAnalyzer::analyseIterationStatementSingleIdentifier(
    IterationStatement *node) {
  const auto &iterTypes = node->expression->types;
  std::vector<std::shared_ptr<Type>> res;
  auto errs = 0UL;
  auto foundDict = false;
  for (const auto &iterT : iterTypes) {
    if (iterT->tag == RANGE) {
      res.emplace_back(this->ns.intType);
      continue;
    }
    if (iterT->tag == LIST) {
      auto *asList = static_cast<List *>(iterT.get());
      res.insert(res.end(), asList->types.begin(), asList->types.end());
      continue;
    }
    if (iterT->tag == DICT) {
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
        Diagnostic(Severity::ERROR, node->expression.get(),
                   foundDict ? "Iterating over a dict requires two identifiers"
                             : "Expression yields no iterable result"));
  }
  auto *id0Expr = dynamic_cast<IdExpression *>(node->ids[0].get());
  if (!id0Expr) [[unlikely]] {
    return;
  }
  this->metadata->encounteredIds.push_back(id0Expr);
  this->modifiedVariableType(id0Expr->id, node->ids[0]->types);
  this->applyToStack(id0Expr->id, node->ids[0]->types);
  this->scope.variables[id0Expr->id] = node->ids[0]->types;
  this->checkIdentifier(id0Expr);
}

void TypeAnalyzer::analyseIterationStatementTwoIdentifiers(
    IterationStatement *node) {
  const auto &iterTypes = node->expression->types;
  node->ids[0]->types = {this->ns.strType};
  auto found = false;
  auto foundBad = false;
  for (const auto &iterT : iterTypes) {
    if (iterT->tag != DICT) {
      foundBad |= iterT->tag == LIST || iterT->tag == RANGE;
      continue;
    }
    const auto *dict = static_cast<Dict *>(iterT.get());
    node->ids[1]->types = dict->types;
    found = true;
    break;
  }
  if (!found) {
    this->metadata->registerDiagnostic(
        node->expression.get(),
        Diagnostic(Severity::ERROR, node->expression.get(),
                   foundBad
                       ? "Iterating over a list/range requires one identifier"
                       : "Expression yields no iterable result"));
  }
  auto *id0Expr = dynamic_cast<IdExpression *>(node->ids[0].get());
  if (id0Expr) [[likely]] {
    this->metadata->encounteredIds.push_back(id0Expr);
    this->modifiedVariableType(id0Expr->id, node->ids[0]->types);
    this->applyToStack(id0Expr->id, node->ids[0]->types);
    this->scope.variables[id0Expr->id] = node->ids[0]->types;
    this->checkIdentifier(id0Expr);
  }
  auto *id1Expr = dynamic_cast<IdExpression *>(node->ids[1].get());
  if (id1Expr) [[likely]] {
    this->metadata->encounteredIds.push_back(id1Expr);
    this->modifiedVariableType(id1Expr->id, node->ids[1]->types);
    this->applyToStack(id1Expr->id, node->ids[1]->types);
    this->scope.variables[id1Expr->id] = node->ids[1]->types;
    this->checkIdentifier(id1Expr);
  }
}

void TypeAnalyzer::visitIterationStatement(IterationStatement *node) {
  node->expression->visit(this);
  for (const auto &itsId : node->ids) {
    itsId->visit(this);
    auto *itsIdExpr = dynamic_cast<IdExpression *>(itsId.get());
    if (itsIdExpr) [[likely]] {
      this->metadata->registerIdentifier(itsIdExpr);
    }
  }
  auto count = node->ids.size();
  if (count == 1) {
    analyseIterationStatementSingleIdentifier(node);
  } else if (count == 2) {
    analyseIterationStatementTwoIdentifiers(node);
  } else [[unlikely]] {
    const auto *fNode = node->ids[0].get();
    const auto *eNode = node->ids[1].get();
    this->metadata->registerDiagnostic(
        fNode,
        Diagnostic(Severity::ERROR, fNode, eNode,
                   "Iteration statement expects only one or two identifiers"));
  }
  this->visitChildren(node->stmts);
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
    if (type->tag == ANY) {
      *nAny = *nAny + 1;
      *bits = (*bits) | (1 << 0);
      continue;
    }
    auto hasDict = false;
    auto hasList = false;
    if (type->tag == LIST) {
      hasList = true;
      auto *listtype = static_cast<List *>(type.get());
      if (listtype->types.size() == 1 && listtype->types[0]->tag == ANY) {
        *nAny = *nAny + 1;
        *bits = (*bits) | (1 << 1);
      }
    }
    if (type->tag == DICT) {
      hasDict = true;
      auto *dicttype = static_cast<Dict *>(type.get());
      if (dicttype->types.size() == 1 && dicttype->types[0]->tag == ANY) {
        *nAny = *nAny + 1;
        *bits = (*bits) | (1 << 2);
      }
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
      auto hasAny = type->tag == ANY;
      for (const auto &argType : firstArg->types) {
        if ((argType->tag == INT && (hasList || hasAny)) ||
            (argType->tag == STR && (hasDict || hasAny)) ||
            (argType->tag == STR && (hasAny || type->tag == CFG_DATA))) {
          LOG.info("Found cont " + node->location.format());
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
    if (al && (al->args.size() == 1 || al->args.size() == 2) &&
        methodName == "get") {
      auto defaultArg = al->getPositionalArg(1);
      if (defaultArg.has_value()) {
        const auto &defaultTypes = defaultArg.value()->types;
        ownResultTypes.insert(ownResultTypes.end(), defaultTypes.begin(),
                              defaultTypes.end());
        if (defaultTypes.size() == 1) {
          switch (defaultTypes[0]->tag) {
          case TypeName::DICT:
            for (const auto &parentType : node->obj->types) {
              if (parentType->tag == LIST) {
                for (const auto &parentType2 :
                     static_cast<const List *>(parentType.get())->types) {
                  if (parentType2->tag == DICT) {
                    ownResultTypes.push_back(parentType2);
                    break;
                  }
                }
              }
              if (parentType->tag == DICT) {
                for (const auto &parentType2 :
                     static_cast<const Dict *>(parentType.get())->types) {
                  if (parentType2->tag == DICT) {
                    ownResultTypes.push_back(parentType2);
                    break;
                  }
                }
              }
            }
            break;
          case TypeName::LIST:
            for (const auto &parentType : node->obj->types) {
              if (parentType->tag == LIST) {
                for (const auto &parentType2 :
                     static_cast<const List *>(parentType.get())->types) {
                  if (parentType2->tag == LIST) {
                    ownResultTypes.push_back(parentType2);
                    break;
                  }
                }
              }
              if (parentType->tag == DICT) {
                for (const auto &parentType2 :
                     static_cast<const Dict *>(parentType.get())->types) {
                  if (parentType2->tag == LIST) {
                    ownResultTypes.push_back(parentType2);
                    break;
                  }
                }
              }
            }
            break;
          default:
            break;
          }
        }
      }
    }
    node->method = method;
    found = true;
  }
  if (*nAny == 3 && *bits == ALL_TYPES_FOUND) {
    return found;
  }
  if (!found && methodName == "get") {
    auto al2 = node->args;
    if (al2 && al2->type == ARGUMENT_LIST) {
      auto *asAL = static_cast<ArgumentList *>(al2.get());
      if (asAL->args.empty()) {
        goto cc2;
      }
      auto resultType = asAL->args[0]->types;
      if (resultType.empty()) {
        goto cc2;
      }
      if (resultType[0]->tag == INT) {
        auto method = this->ns.lookupMethod("get", this->ns.types.at("list"));
        node->method = method.value();
        ownResultTypes.insert(ownResultTypes.end(),
                              method.value()->returnTypes.begin(),
                              method.value()->returnTypes.end());
        auto defaultArg = asAL->getPositionalArg(1);
        if (defaultArg.has_value()) {
          const auto &defaultTypes = defaultArg.value()->types;
          ownResultTypes.insert(ownResultTypes.end(), defaultTypes.begin(),
                                defaultTypes.end());
        }
        found = true;
        return found;
      }
      if (resultType[0]->tag == STR) {
        auto method = this->ns.lookupMethod("get", this->ns.types.at("dict"));
        node->method = method.value();
        ownResultTypes.insert(ownResultTypes.end(),
                              method.value()->returnTypes.begin(),
                              method.value()->returnTypes.end());
        auto defaultArg = asAL->getPositionalArg(1);
        if (defaultArg.has_value()) {
          const auto &defaultTypes = defaultArg.value()->types;
          ownResultTypes.insert(ownResultTypes.end(), defaultTypes.begin(),
                                defaultTypes.end());
        }
        found = true;
        return found;
      }
    }
  cc2:
    for (const auto &type : types) {
      if (type->tag == DICT || type->tag == LIST || type->tag == CFG_DATA) {
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
            const auto &defaultTypes = defaultArg.value()->types;
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
  if (methodName == "get") {
    if (node->args->type != ARGUMENT_LIST) {
      goto regular;
    }
    const auto *al = static_cast<ArgumentList *>(node->args.get());
    auto firstArg = al->getPositionalArg(0);
    if (!firstArg.has_value()) {
      goto regular;
    }
    auto firstArgTypes = firstArg.value()->types;
    if (firstArgTypes.empty()) {
      goto regular;
    }
    if (firstArgTypes[0]->tag == INT) {
      auto guessedMethod =
          this->ns.lookupMethod("get", this->ns.types.at("list"));
      auto method = guessedMethod.value();
      ownResultTypes.insert(ownResultTypes.end(), method->returnTypes.begin(),
                            method->returnTypes.end());
      node->method = method;
      node->types = dedup(this->ns, ownResultTypes);
      return true;
    }
    if (firstArgTypes[0]->tag == STR) {
      auto guessedMethod =
          this->ns.lookupMethod("get", this->ns.types.at("dict"));
      auto method = guessedMethod.value();
      ownResultTypes.insert(ownResultTypes.end(), method->returnTypes.begin(),
                            method->returnTypes.end());
      node->method = method;
      node->types = dedup(this->ns, ownResultTypes);
      return true;
    }
  }

regular:
  auto guessedMethod = this->ns.lookupMethod(methodName);
  if (!guessedMethod.has_value()) {
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
  if (node->id->type != ID_EXPRESSION) {
    return;
  }
  const auto *methodNameId = static_cast<IdExpression *>(node->id.get());
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
  auto onlyDisabler = types.size() == 1 && types[0]->tag == DISABLER;
  if (!found && !onlyDisabler) {
    const auto &typeStr = joinTypes(types);
    this->metadata->registerDiagnostic(
        node, Diagnostic(Severity::ERROR, node,
                         std::format("No method `{}` found for types `{}`",
                                     methodName, typeStr)));
    return;
  }
  if (!found && onlyDisabler) {
    LOG.warn("Ignoring invalid method for disabler");
    return;
  }
  if (node->method->deprecationState.deprecated) {
    this->createDeprecationWarning(node->method->deprecationState, node,
                                   "method");
  }
  const auto &currVersion = this->matchingVersion();
  if (node->method->since.after(currVersion)) {
    this->metadata->registerDiagnostic(
        node,
        Diagnostic(Severity::WARNING, node,
                   std::format("Meson version {} is requested, but {}() "
                               "is only available since {}",
                               currVersion.versionString, node->method->id(),
                               node->method->since.versionString)));
  }
  if (node->args && node->args->type == ARGUMENT_LIST) {
    const auto &asArgumentList = static_cast<ArgumentList *>(node->args.get());
    for (const auto &arg : asArgumentList->args) {
      if (arg->type != KEYWORD_ITEM) {
        continue;
      }
      auto *asKwi = static_cast<KeywordItem *>(arg.get());
      this->metadata->registerKwarg(asKwi, node->method);
    }
  }
  if (node->method->id() == "subproject.get_variable" &&
      this->tree->state.used) {
    std::vector<std::shared_ptr<Type>> newTypes;
    newTypes.insert(newTypes.end(), node->method->returnTypes.begin(),
                    node->method->returnTypes.end());
    const auto &values = ::guessGetVariableMethod(node, this->options);
    std::set<std::string> const asSet{values.begin(), values.end()};
    for (const auto &objType : node->obj->types) {
      auto *subprojType = dynamic_cast<Subproject *>(objType.get());
      if (!subprojType) {
        continue;
      }
      for (const auto &subprojName : subprojType->names) {
        const auto &subproj =
            this->tree->state.hasSubproject(subprojName)
                ? this->tree->state.findSubproject(subprojName)
                : (this->tree->parent
                       ? this->tree->parent->state.findSubproject(subprojName)
                       : nullptr);
        if (!subproj) {
          LOG.warn(std::format("Unable to find subproject {}", subprojName));
          continue;
        }
        const auto &variables = subproj->tree->scope;
        if (!subproj->tree) {
          LOG.warn(std::format(
              "Subproject {} wasn't parsed yet... (Known limitation)",
              subprojName));
          continue;
        }
        for (const auto &varname : asSet) {
          if (variables.variables.contains(varname)) {
            const auto &varTypes = variables.variables.at(varname);
            newTypes.insert(newTypes.end(), varTypes.begin(), varTypes.end());
            continue;
          }
          LOG.warn(std::format("Unable to find variable {} in subproject {}",
                               varname, subprojName));
          if (asSet.size() == 1 && subprojType->names.size() == 1) {
            this->metadata->registerDiagnostic(
                node,
                Diagnostic(
                    Severity::ERROR, node,
                    std::format("Unable to find variable {} in subproject {}",
                                varname, subprojName)));
          }
        }
      }
    }
    node->types = dedup(this->ns, newTypes);
  }
  this->checkCall(node);
  if (node->obj->type != STRING_LITERAL || !node->args ||
      node->args->type != ARGUMENT_LIST) {
    return;
  }
  const auto *sl = static_cast<StringLiteral *>(node->obj.get());
  const auto *al = static_cast<ArgumentList *>(node->args.get());
  if (sl && node->method->id() == "str.format") {
    if (al) {
      this->checkFormat(sl, al->args);
    } else {
      this->checkFormat(sl);
    }
  }
}

static const auto EMPTY_SET = std::set<uint64_t>();

void TypeAnalyzer::checkFormat(const StringLiteral *sl) const {
  std::vector<std::string> oobIntegers;
  auto foundIntegers =
      sl->hasEnoughAts ? extractIntegersBetweenAtSymbols(sl->id) : EMPTY_SET;
  oobIntegers.reserve(foundIntegers.size());
  for (auto integer : foundIntegers) {
    oobIntegers.push_back(std::format("@{}@", integer));
  }
  if (oobIntegers.empty()) {
    this->metadata->registerDiagnostic(
        sl->parent, Diagnostic(Severity::WARNING, sl->parent,
                               "Pointless str.format() call"));
    return;
  }
  this->metadata->registerDiagnostic(
      sl,
      Diagnostic(Severity::ERROR, sl,
                 "Parameters out of bounds: " + joinStrings(oobIntegers, ',')));
}

void TypeAnalyzer::checkFormat(
    const StringLiteral *sl,
    const std::vector<std::shared_ptr<Node>> &args) const {
  auto foundIntegers =
      sl->hasEnoughAts ? extractIntegersBetweenAtSymbols(sl->id) : EMPTY_SET;
  for (size_t i = 0; i < args.size(); i++) {
    if (!foundIntegers.contains(i)) {
      this->metadata->registerDiagnostic(
          args[i].get(), Diagnostic(Severity::WARNING, args[i].get(),
                                    "Unused parameter in format() call"));
    }
  }
  if (foundIntegers.empty()) {
    this->metadata->registerDiagnostic(
        sl->parent, Diagnostic(Severity::WARNING, sl->parent,
                               "Pointless str.format() call"));
    return;
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
      Diagnostic(Severity::ERROR, sl,
                 "Parameters out of bounds: " + joinStrings(oobIntegers, ',')));
}

bool TypeAnalyzer::checkCondition(Node *condition) {
  auto appended = false;
  if (condition->type == FUNCTION_EXPRESSION) {
    const auto *fe = static_cast<FunctionExpression *>(condition);
    if (fe->functionName() == "is_variable" && fe->args &&
        fe->args->type == ARGUMENT_LIST) {
      const auto *al = static_cast<ArgumentList *>(fe->args.get());
      if (!al->args.empty() && al->args[0]->type == STRING_LITERAL) {
        auto *testedIdentifier =
            static_cast<StringLiteral *>(al->args[0].get());
        if (testedIdentifier) {
          this->ignoreUnknownIdentifier.emplace_back(testedIdentifier->id);
          appended = true;
        }
      }
    }
  }
  auto foundBoolOrAny = false;
  for (const auto &type : condition->types) {
    if (type->tag == ANY || type->tag == BOOL || type->tag == DISABLER) {
      foundBoolOrAny = true;
      break;
    }
  }
  if (!foundBoolOrAny && !condition->types.empty()) {
    auto joined = joinTypes(condition->types);
    this->metadata->registerDiagnostic(
        condition, Diagnostic(Severity::ERROR, condition,
                              "Condition is not bool: " + joined));
  }
  return appended;
}

void TypeAnalyzer::visitChildren(
    const std::vector<std::shared_ptr<Node>> &stmts) {
  std::shared_ptr<Node> lastAlive = nullptr;
  std::shared_ptr<Node> firstDead = nullptr;
  std::shared_ptr<Node> lastDead = nullptr;
  for (const auto &stmt : stmts) {
    stmt->visit(this);
    this->checkNoEffect(stmt.get());
    if (!lastAlive) {
      if (TypeAnalyzer::isDead(stmt)) {
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

void TypeAnalyzer::pushVersion(const std::string &version) {
  auto subStr = 0;
  for (const auto chr : version) {
    if (chr == '>' || chr == '=' || chr == '<' || chr == ' ') {
      subStr++;
      continue;
    }
    break;
  }
  this->versionStack.emplace_back(version.substr(subStr));
}

bool TypeAnalyzer::checkConditionForVersionComparison(const Node *condition) {
  if (condition->type == METHOD_EXPRESSION) {
    const auto *me = static_cast<const MethodExpression *>(condition);
    if (me->method && me->method->id() == "str.version_compare" && me->args) {
      if (me->args->type != ARGUMENT_LIST) {
        return false;
      }
      const auto *al = static_cast<const ArgumentList *>(me->args.get());
      if (al->args.empty() || al->args[0]->type != STRING_LITERAL) {
        return false;
      }
      const auto *sl = static_cast<const StringLiteral *>(al->args[0].get());
      const auto *methodObj = me->obj.get();
      if (methodObj->type == ID_EXPRESSION) {
        const auto *idExpr = static_cast<const IdExpression *>(methodObj);
        if (this->mesonVersionVars.contains(idExpr->id)) {
          this->pushVersion(sl->id);
          return true;
        }
      }
      if (methodObj->type != METHOD_EXPRESSION) {
        return false;
      }
      const auto *me2 = static_cast<const MethodExpression *>(methodObj);
      if (me2->method && me2->method->id() == "meson.version") {
        this->pushVersion(sl->id);
        return true;
      }
    }
    return false;
  }
  if (condition->type != BINARY_EXPRESSION) {
    return false;
  }
  const auto *be = static_cast<const BinaryExpression *>(condition);
  if (this->checkConditionForVersionComparison(be->lhs.get())) {
    return true;
  }
  return this->checkConditionForVersionComparison(be->rhs.get());
}

const Version &TypeAnalyzer::matchingVersion() const {
  if (this->versionStack.empty()) [[likely]] {
    return this->tree->version;
  }
  return this->versionStack.back();
}

void TypeAnalyzer::visitSelectionStatement(SelectionStatement *node) {
  this->stack.emplace_back();
  this->overriddenVariables.emplace_back();
  this->selectionStatementStack.emplace_back();
  auto idx = 0UL;
  std::vector<IdExpression *> allLeft;
  for (const auto &block : node->blocks) {
    auto appended = false;
    auto appendedVersion = false;
    if (idx < node->conditions.size()) {
      const auto &cond = node->conditions[idx];
      cond->visit(this);
      appended = this->checkCondition(cond.get());
      appendedVersion = this->checkConditionForVersionComparison(cond.get());
    }
    this->variablesNeedingUse.emplace_back();
    this->visitChildren(block);
    if (appended) {
      this->ignoreUnknownIdentifier.pop_back();
    }
    if (appendedVersion) {
      this->versionStack.pop_back();
    }
    const auto &lastNeedingUse = this->variablesNeedingUse.back();
    allLeft.insert(allLeft.end(), lastNeedingUse.begin(), lastNeedingUse.end());
    this->variablesNeedingUse.pop_back();
    idx++;
  }
  std::set<std::string> dedupedUnusedAssignments;
  auto toInsert = this->variablesNeedingUse.back();
  for (auto *idExpr : allLeft) {
    if (dedupedUnusedAssignments.contains(idExpr->id)) {
      continue;
    }
    dedupedUnusedAssignments.insert(idExpr->id);
    toInsert.push_back(idExpr);
  }
  this->variablesNeedingUse.back() = toInsert;
  const auto &types = this->stack.back();
  const auto changed = this->selectionStatementStack.back();
  this->selectionStatementStack.pop_back();
  // If: 1 c, 1 b
  // If,else if: 2c, 2b
  // if, else if, else, 2c, 3b
  for (const auto &[key, keyTypes] : types) {
    // This leaks some overwritten types. This can't be solved
    // without costly static analysis
    // x = 'Foo'
    // if bar
    //   x = 2
    // else
    //   x = true
    // endif
    // x is now str|int|bool instead of int|bool
    auto arr = this->scope.variables.contains(key)
                   ? this->scope.variables[key]
                   : std::vector<std::shared_ptr<Type>>{};
    arr.insert(arr.end(), keyTypes.begin(), keyTypes.end());
    if (changed.contains(key)) {
      const auto &oldTypes = changed.at(key);
      arr.insert(arr.end(), oldTypes.begin(), oldTypes.end());
    }
    const auto &deduped = dedup(this->ns, arr);
    this->modifiedVariableType(key, deduped);
    this->scope.variables[key] = deduped;
  }
  this->stack.pop_back();
  this->overriddenVariables.pop_back();
}

void TypeAnalyzer::visitStringLiteral(StringLiteral *node) {
  node->visitChildren(this);
  node->types = {this->ns.strType};
  this->metadata->registerStringLiteral(node);
  if (!node->hasEnoughAts) {
    return;
  }
  const auto &str = node->id;
  const auto &matches = extractTextBetweenAtSymbols(str);
  if (!node->isFormat && !matches.empty()) {
    auto reallyFound = true;
    for (const auto &match : matches) {
      if (match.starts_with("OUTPUT") || match.starts_with("INPUT") ||
          match == "BASENAME" || match.starts_with("OUTDIR") ||
          match == "BUILD_ROOT" || match == "BUILD_DIR" ||
          match == "PLAINNAME" || match == "EXTRA_ARGS" ||
          match == "CURRENT_SOURCE_DIR" || match == "DEPFILE" ||
          match == "SOURCE_ROOT" || match == "PRIVATE_DIR" ||
          match == "SOURCE_DIR" || match == "VCS_TAG") {
        reallyFound = false;
        break;
      }
    }
    if (reallyFound) {
      this->metadata->registerDiagnostic(
          node, Diagnostic(Severity::WARNING, node,
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
    if (type->tag == DICT) {
      const auto *asDict = static_cast<Dict *>(type.get());
      const auto &dTypes = asDict->types;
      newTypes.insert(newTypes.begin(), dTypes.begin(), dTypes.end());
      continue;
    }
    if (type->tag == LIST) {
      const auto *asList = static_cast<List *>(type.get());
      const auto &lTypes = asList->types;
      newTypes.insert(newTypes.begin(), lTypes.begin(), lTypes.end());
      continue;
    }
    if (type->tag == STR) {
      newTypes.emplace_back(this->ns.strType);
      continue;
    }
    if (type->tag == CUSTOM_TGT) {
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
    using enum UnaryOperator;
  case NOT:
  case EXCLAMATION_MARK:
    node->types.push_back(this->ns.boolType);
    break;
  case UNARY_MINUS:
    node->types.push_back(this->ns.intType);
    break;
  default:
    this->metadata->registerDiagnostic(
        node, Diagnostic(Severity::ERROR, node, "Bad unary operator"));
    break;
  }
}

void TypeAnalyzer::visitErrorNode(ErrorNode *node) {
  node->visitChildren(this);
  this->metadata->registerDiagnostic(
      node, Diagnostic(Severity::ERROR, node, node->message));
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
          Severity::ERROR, node,
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
  std::map<TypeName, std::shared_ptr<Type>> objs;
  auto gotList = false;
  auto gotDict = false;
  auto gotSubproject = false;
  for (const auto &type : types) {
    auto *asRaw = type.get();
    if (asRaw->tag == STR) {
      hasStr = true;
      continue;
    }
    if (asRaw->tag == LIST) {
      auto *asList = static_cast<List *>(asRaw);
      listtypes.insert(listtypes.end(), asList->types.begin(),
                       asList->types.end());
      gotList = true;
      continue;
    }
    if (asRaw->tag == DICT) {
      auto *asDict = static_cast<Dict *>(asRaw);
      dicttypes.insert(dicttypes.end(), asDict->types.begin(),
                       asDict->types.end());
      gotDict = true;
      continue;
    }
    if (asRaw->tag == BOOL) {
      hasBool = true;
      continue;
    }
    if (asRaw->tag == ANY) {
      hasAny = true;
      continue;
    }
    if (asRaw->tag == INT) {
      hasInt = true;
      continue;
    }
    if (asRaw->tag != SUBPROJECT) {
      objs[type->tag] = type;
      continue;
    }
    auto *asSubproject = static_cast<Subproject *>(asRaw);
    if (asSubproject != nullptr) {
      subprojectNames.insert(asSubproject->names.begin(),
                             asSubproject->names.end());
      gotSubproject = true;
      continue;
    }
  }
  std::vector<std::shared_ptr<Type>> ret;
  if ((!listtypes.empty()) || gotList) {
    ret.emplace_back(std::make_shared<List>(dedup(ns, std::move(listtypes))));
  }
  if ((!dicttypes.empty()) || gotDict) {
    ret.emplace_back(std::make_shared<Dict>(dedup(ns, std::move(dicttypes))));
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
  for (const auto &[_, typeRef] : objs) {
    ret.emplace_back(typeRef);
  }
  return ret;
}

std::string joinTypes(const std::vector<std::shared_ptr<Type>> &types) {
  std::vector<std::string> vector;
  vector.reserve(types.size());
  for (const auto &type : types) {
    vector.push_back(type->toString());
  }
  std::ranges::sort(vector);
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

static bool isType(const std::shared_ptr<Type> &type, const TypeName tag) {
  return type->tag == tag || type->tag == ANY;
}

static bool sameType(const std::shared_ptr<Type> &first,
                     const std::shared_ptr<Type> &second, const TypeName tag) {
  return isType(first, tag) && isType(second, tag);
}
