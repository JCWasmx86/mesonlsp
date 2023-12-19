#include "subproject.hpp"

#include "mesontree.hpp"

#include <memory>

void MesonSubproject::parse(AnalysisOptions &options) {
  this->tree = std::make_shared<MesonTree>(this->realpath);
  this->tree->fullParse(options);
}
