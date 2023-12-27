#pragma once

#include "lsptypes.hpp"
#include "node.hpp"
#include "optionstate.hpp"

Hover makeHoverForFunctionExpression(FunctionExpression *fe,
                                     const OptionState &options);
Hover makeHoverForMethodExpression(MethodExpression *me);
Hover makeHoverForId(IdExpression *idExpr);
