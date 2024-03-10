#include "hover.hpp"

#include "argument.hpp"
#include "lsptypes.hpp"
#include "mesonoption.hpp"
#include "node.hpp"
#include "optionstate.hpp"
#include "polyfill.hpp"
#include "typeanalyzer.hpp"
#include "typenamespace.hpp"
#include "utils.hpp"

#include <format>
#include <string>

static std::string formatArgument(const Argument *arg);

Hover makeHoverForFunctionExpression(
    FunctionExpression *fe, const OptionState &options,
    const std::map<std::string, std::string> &descriptions) {
  if (!fe->function) {
    return Hover{
        MarkupContent("Unable to find information about this function!")};
  }
  auto func = fe->function;
  if (func->name == "get_option") {
    auto *args = dynamic_cast<ArgumentList *>(fe->args.get());
    if (!args || args->args.empty()) {
      goto cont;
    }
    auto *firstArg = args->args[0].get();
    auto *optionSL = dynamic_cast<StringLiteral *>(firstArg);
    if (!optionSL) {
      goto cont;
    }
    const auto &option = optionSL->id;
    auto corrOption = options.findOption(option);
    if (!corrOption) {
      goto cont;
    }
    auto ret = std::format("## Option {}\nType: `{}`\n\n", corrOption->name,
                           corrOption->type);
    if (corrOption->deprecated) {
      ret += "\n**Deprecated**\n";
    }
    if (corrOption->description.has_value()) {
      ret += /*NOLINT*/ corrOption->description.value() + "\n";
    }
    if (auto *arrayOption = dynamic_cast<ArrayOption *>(corrOption.get())) {
      ret +=
          std::format("\nChoices: {}", joinStrings(arrayOption->choices, '|'));
    } else if (auto *comboOption =
                   dynamic_cast<ComboOption *>(corrOption.get())) {
      ret += std::format("\nValues: {}", joinStrings(comboOption->values, '|'));
    }
    return Hover{MarkupContent(ret)};
  }
cont:
  auto header = std::format("## {}\n\n", func->name);
  auto returns = std::format("-> `{}`\n", func->returnTypes.empty()
                                              ? "void"
                                              : joinTypes(func->returnTypes));
  auto docs = std::format("{}\n", func->doc);
  std::string signature;
  if (func->args.empty()) {
    signature = std::format("{}()\n", func->name);
  } else if (func->args.size() == 1) {
    signature = std::format("{}({})\n", func->name,
                            formatArgument(func->args[0].get()));
  } else {
    signature = std::format("{}(\n", func->name);
    for (const auto &arg : func->args) {
      signature += std::format("  {},\n", formatArgument(arg.get()));
    }
    signature += ")\n";
  }

  if (func->name == "dependency" && fe->args &&
      fe->args->type == NodeType::ARGUMENT_LIST) {
    const auto *firstArg = static_cast<const ArgumentList *>(fe->args.get());
    if (!firstArg->args.empty() &&
        firstArg->args[0]->type == NodeType::STRING_LITERAL) {
      const auto *asSL =
          static_cast<const StringLiteral *>(firstArg->args[0].get());
      if (descriptions.contains(asSL->id)) {
        docs = std::format("{}\n\n{}", descriptions.at(asSL->id), docs);
      }
    }
  }

  return Hover{MarkupContent(std::format("{}{}\n{}\n\n```meson\n{}```\n",
                                         header, returns, docs, signature))};
}

Hover makeHoverForMethodExpression(MethodExpression *me) {
  if (!me->method) {
    return Hover{
        MarkupContent("Unable to find information about this method!")};
  }
  auto method = me->method;
  auto header = std::format("## {}\n\n", method->id());
  auto returns = std::format("-> `{}`\n", method->returnTypes.empty()
                                              ? "void"
                                              : joinTypes(method->returnTypes));
  auto docs = std::format("{}\n", method->doc);
  std::string signature;
  if (method->args.empty()) {
    signature = std::format("{}()\n", method->id());
  } else if (method->args.size() == 1) {
    signature = std::format("{}({})\n", method->id(),
                            formatArgument(method->args[0].get()));
  } else {
    signature = std::format("{}(\n", method->id());
    for (const auto &arg : method->args) {
      signature += std::format("  {},\n", formatArgument(arg.get()));
    }
    signature += ")\n";
  }
  return Hover{MarkupContent(std::format("{}{}\n{}\n```meson\n{}```\n", header,
                                         returns, docs, signature))};
}

Hover makeHoverForId(const TypeNamespace &ns, IdExpression *idExpr) {
  auto header = std::format("## variable `{}`\n\n", idExpr->id);
  auto types = idExpr->types;
  if (types.empty()) {
    return Hover{MarkupContent(header)};
  }
  auto joined = joinTypes(types);
  if (types.size() > 1) {
    return Hover{MarkupContent(std::format("{}Types: `{}`", header, joined))};
  }
  auto onlyType = types[0];
  return Hover{MarkupContent(std::format("{}Type: `{}`\n\n{}\n", header, joined,
                                         ns.objectDocs.at(onlyType->name)))};
}

static std::string formatArgument(const Argument *arg) {
  std::string ret;
  const auto *asKwarg = dynamic_cast<const Kwarg *>(arg);
  if (asKwarg) {
    ret = std::format("{}: {}", arg->name, joinTypes(arg->types));
  } else {
    const auto *posArg = dynamic_cast<const PositionalArgument *>(arg);
    const auto *varArgStr = posArg->varargs ? "‎..." : "";
    ret = std::format("{} {}{}", posArg->name, joinTypes(posArg->types),
                      varArgStr);
  }
  if (arg->optional) {
    return std::format("[ {} ]", ret);
  }
  return ret;
}
