#include "subproject.hpp"

#include "analysisoptions.hpp"
#include "mesontree.hpp"
#include "typenamespace.hpp"

#include <memory>
#include <string>

void MesonSubproject::parse(AnalysisOptions &options, int depth,
                            const std::string &parentIdentifier,
                            const TypeNamespace &ns) {
  this->tree = std::make_shared<MesonTree>(this->realpath, ns);
  this->tree->depth = depth;
  this->tree->identifier = parentIdentifier + ">" + this->name;
  this->tree->fullParse(options);
}
