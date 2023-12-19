#include "subproject.hpp"

#include "mesontree.hpp"

#include <memory>

void MesonSubproject::parse(AnalysisOptions &options, int depth,
                            const std::string &parentIdentifier) {
  this->tree = std::make_shared<MesonTree>(this->realpath);
  this->tree->depth = depth;
  this->tree->identifier = parentIdentifier + ">" + this->name;
  this->tree->fullParse(options);
}
