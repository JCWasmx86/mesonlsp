#pragma once

#include "lsptypes.hpp"
#include "node.hpp"

Hover makeHoverForFunctionExpression(FunctionExpression *fe);
Hover makeHoverForMethodExpression(MethodExpression *me);
Hover makeHoverForId(IdExpression *idExpr);
