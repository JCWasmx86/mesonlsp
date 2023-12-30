#pragma once

#include "lsptypes.hpp"
#include "mesontree.hpp"
#include "node.hpp"

#include <filesystem>
#include <memory>
#include <vector>

std::vector<CompletionItem> complete(const std::filesystem::path &path,
                                     const std::shared_ptr<MesonTree> &tree,
                                     const std::shared_ptr<Node> &ast,
                                     const LSPPosition &position);
