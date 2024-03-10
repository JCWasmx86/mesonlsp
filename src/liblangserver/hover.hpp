#pragma once

#include "lsptypes.hpp"
#include "node.hpp"
#include "optionstate.hpp"
#include "typenamespace.hpp"

Hover makeHoverForFunctionExpression(
    FunctionExpression *fe, const OptionState &options,
    const std::map<std::string, std::string> &descriptions);
Hover makeHoverForMethodExpression(MethodExpression *me);
Hover makeHoverForId(const TypeNamespace &ns, IdExpression *idExpr);
