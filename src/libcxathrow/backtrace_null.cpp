#include "log.hpp"
#include "polyfill.hpp"
#include "shared.hpp"

#include <cxxabi.h>

const static Logger LOG("cxathrow"); // NOLINT

void doBacktrace() { LOG.debug("No backtrace possible...."); }
