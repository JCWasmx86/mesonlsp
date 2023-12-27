#include "hover.hpp"

#include "argument.hpp"
#include "lsptypes.hpp"
#include "typeanalyzer.hpp"

#include <format>

static std::string formatArgument(const Argument *arg);

Hover makeHoverForFunctionExpression(FunctionExpression *fe) {
  if (!fe->function) {
    return {MarkupContent("Unable to find information about this function!")};
  }
  auto fn = fe->function;
  auto header = std::format("## {}\n\n", fn->name);
  auto returns = std::format("-> `{}`\n", fn->returnTypes.empty()
                                              ? "void"
                                              : joinTypes(fn->returnTypes));
  auto docs = std::format("{}\n", fn->doc);
  std::string signature;
  if (fn->args.empty()) {
    signature = std::format("{}()\n", fn->name);
  } else if (fn->args.size() == 1) {
    signature =
        std::format("{}({})\n", fn->name, formatArgument(fn->args[0].get()));
  } else {
    signature = std::format("{}(\n", fn->name);
    for (const auto &arg : fn->args) {
      signature += std::format("  {},\n", formatArgument(arg.get()));
    }
    signature += ")\n";
  }

  return {MarkupContent(std::format("{}{}\n{}\n\n```meson\n{}```\n", header,
                                    returns, docs, signature))};
}

Hover makeHoverForMethodExpression(MethodExpression *me) {
  if (!me->method) {
    return {MarkupContent("Unable to find information about this method!")};
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
  return {MarkupContent(std::format("{}{}\n{}\n```meson\n{}```\n", header,
                                    returns, docs, signature))};
}

Hover makeHoverForId(IdExpression *idExpr) {
  auto header = std::format("## variable `{}`\n\n", idExpr->id);
  auto types = idExpr->types;
  if (types.empty()) {
    return {MarkupContent(header)};
  }
  auto joined = joinTypes(types);
  if (types.size() > 1) {
    return {MarkupContent(std::format("{}Types: `{}`", header, joined))};
  }
  auto onlyType = types[0];
  return {MarkupContent(
      std::format("{}Type: `{}`\n\n{}\n", header, joined, onlyType->docs))};
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
