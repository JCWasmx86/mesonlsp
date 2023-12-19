#include "subproject.hpp"

#include "mesontree.hpp"

#include <memory>

void MesonSubproject::parse(AnalysisOptions &options, int depth) {
  this->tree = std::make_shared<MesonTree>(this->realpath);
  this->tree->depth = depth;
  this->tree->fullParse(options);
}
