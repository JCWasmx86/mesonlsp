#include "langserveroptions.hpp"
#include "langserverutils.hpp"
#include "log.hpp"
#include "lsptypes.hpp"
#include "nlohmann/json.hpp"
#include "typenamespace.hpp"
#include "workspace.hpp"

#include <cassert>
#include <filesystem>
#include <string>

int main(int argc, char **argv) {
  Logger const logger("workspace-tester");
  std::filesystem::path const toParse = argv[1];
  const auto url = pathToUrl(toParse.parent_path());
  LanguageServerOptions options;
  nlohmann::json json;
  json["uri"] = url;
  json["name"] = "root";
  TypeNamespace const ns;
  WorkspaceFolder const wspf{json};
  Workspace workspace{wspf, options};
  const auto diags = workspace.parse(ns);
  assert(diags.size() == 1);
  const auto &firstDiags = diags.begin()->second;
  assert(firstDiags.size() == 1);
  const auto &diag = firstDiags[0];
  assert(diag.severity == DiagnosticSeverity::LSP_WARNING);
  assert(diag.message ==
         "Meson version 0.21.0 is requested, but meson.project_build_root() is "
         "only available since 0.56.0");
  auto gotoDefinition = workspace.jumpTo(diags.begin()->first, {9, 8});
  assert(gotoDefinition.size() == 1);
  assert(gotoDefinition[0].range.start.line == 4);
  assert(gotoDefinition[0].range.start.character == 0);
  gotoDefinition = workspace.jumpTo(diags.begin()->first, {10, 8});
  assert(gotoDefinition.size() == 1);
  assert(gotoDefinition[0].range.start.line == 0);
  assert(gotoDefinition[0].range.start.character == 7);
  gotoDefinition = workspace.jumpTo(diags.begin()->first, {0, 2});
  assert(gotoDefinition.empty());
  assert(workspace.owns(diags.begin()->first));
  gotoDefinition = workspace.jumpTo(diags.begin()->first, {11, 8});
  assert(gotoDefinition.size() == 1);
  assert(gotoDefinition[0].uri.ends_with("subdir/meson.build"));
  assert(gotoDefinition[0].range.start.line == 0);
  assert(gotoDefinition[0].range.start.character == 0);
  nlohmann::json renameJsonParams;
  renameJsonParams["textDocument"] = {{"uri", diags.begin()->first}};
  renameJsonParams["newName"] = "foo123";
  renameJsonParams["position"] = {{"line", 0}, {"character", 0}};
  auto renameEdit =
      workspace.rename(diags.begin()->first, RenameParams(renameJsonParams));
  assert(!renameEdit.has_value());
  renameJsonParams["textDocument"] = {{"uri", diags.begin()->first}};
  renameJsonParams["newName"] = "foo123";
  renameJsonParams["position"] = {{"line", 9}, {"character", 8}};
  renameEdit =
      workspace.rename(diags.begin()->first, RenameParams(renameJsonParams));
  assert(renameEdit.has_value());
  // Root + Subdir file
  assert(renameEdit->changes.size() == 2);
  auto &renameChanges = renameEdit->changes.begin()->second;
  assert(renameChanges.size() == 3);
  logger.info("Success");
}
