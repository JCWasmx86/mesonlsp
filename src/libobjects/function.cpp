#include "function.hpp"

#include <string>

const std::string &Function::id() const { return this->name; }

const std::string &Method::id() const { return this->privateId; }
