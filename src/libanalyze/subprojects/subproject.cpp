#include "subproject.hpp"

#include "mesontree.hpp"

#include <memory>

void MesonSubproject::parse(AnalysisOptions &options, int depth,
                            const std::string &parentIdentifier,
                            const TypeNamespace &ns) {
  this->tree = std::make_shared<MesonTree>(this->realpath, ns);
  this->tree->depth = depth;
  this->tree->identifier = parentIdentifier + ">" + this->name;
  this->tree->fullParse(options);
}
