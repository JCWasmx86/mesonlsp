#pragma once

#include "analysisoptions.hpp"
#include "nlohmann/json.hpp"

#include <filesystem>
#include <optional>
#include <string>
#include <vector>

class LanguageServerOptions {
public:
  AnalysisOptions analysisOptions;
  bool neverDownloadAutomatically = false;
  std::optional<std::vector<std::string>> ignoreDiagnosticsFromSubprojects =
      std::nullopt;
  std::optional<std::filesystem::path> defaultFormattingConfig;
  bool disableInlayHints = false;
  bool removeDefaultTypesInInlayHints = false;

  // No need for muon path anymore

  void update(const nlohmann::json &options) {
    if (options.contains("others")) {
      const auto &others = options["others"];
      updateOthers(others);
    }
    if (options.contains("linting") && options["linting"].is_object()) {
      const auto &linting = options["linting"];
      updateLinting(linting);
    }
  }

  void update(const std::optional<nlohmann::json> &options) {
    if (options.has_value()) {
      this->update(options.value());
    }
  }

private:
  void updateLinting(const nlohmann::json &linting) {
    if (linting.contains("disableNameLinting")) {
      this->analysisOptions.disableNameLinting =
          linting.value("disableNameLinting", false);
    }
    if (linting.contains("disableUnusedVariableCheck")) {
      this->analysisOptions.disableUnusedVariableCheck =
          linting.value("disableUnusedVariableCheck", false);
    }
    if (linting.contains("disableAllIdLinting")) {
      this->analysisOptions.disableAllIdLinting =
          linting.value("disableAllIdLinting", false);
    }
    if (linting.contains("disableCompilerIdLinting")) {
      this->analysisOptions.disableCompilerIdLinting =
          linting.value("disableCompilerIdLinting", false);
    }
    if (linting.contains("disableCompilerArgumentIdLinting")) {
      this->analysisOptions.disableCompilerArgumentIdLinting =
          linting.value("disableCompilerArgumentIdLinting", false);
    }
    if (linting.contains("disableLinkerIdLinting")) {
      this->analysisOptions.disableLinkerIdLinting =
          linting.value("disableLinkerIdLinting", false);
    }
    if (linting.contains("disableCpuFamilyLinting")) {
      this->analysisOptions.disableCpuFamilyLinting =
          linting.value("disableCpuFamilyLinting", false);
    }
    if (linting.contains("disableOsFamilyLinting")) {
      this->analysisOptions.disableOsFamilyLinting =
          linting.value("disableOsFamilyLinting", false);
    }
  }

  void updateOthers(const nlohmann::json &others) {
    if (others.contains("neverDownloadAutomatically")) {
      this->neverDownloadAutomatically =
          others.value("neverDownloadAutomatically", false);
    }
    if (others.contains("removeDefaultTypesInInlayHints")) {
      this->removeDefaultTypesInInlayHints =
          others.value("removeDefaultTypesInInlayHints", false);
    }
    if (others.contains("disableInlayHints")) {
      this->disableInlayHints = others.value("disableInlayHints", false);
    }
    if (others.contains("defaultFormattingConfig")) {
      const auto &config = others["defaultFormattingConfig"];
      if (config.is_string()) {
        const auto &path = std::filesystem::path{config};
        if (path.is_absolute() && std::filesystem::exists(path)) {
          this->defaultFormattingConfig = path;
        } else {
          this->defaultFormattingConfig = std::nullopt;
        }
      } else {
        this->defaultFormattingConfig = std::nullopt;
      }
    }
    if (others.contains("ignoreDiagnosticsFromSubprojects")) {
      const auto &ignore = others.at("ignoreDiagnosticsFromSubprojects");
      if (ignore.is_boolean()) {
        if (ignore.get<bool>()) {
          this->ignoreDiagnosticsFromSubprojects = std::vector<std::string>{};
        } else {
          this->ignoreDiagnosticsFromSubprojects = std::nullopt;
        }
        return;
      }
      if (!ignore.is_array()) {
        return;
      }
      this->ignoreDiagnosticsFromSubprojects = std::vector<std::string>{};
      for (const auto &element : ignore.get<std::vector<nlohmann::json>>()) {
        if (element.is_string()) {
          this->ignoreDiagnosticsFromSubprojects->push_back(
              element.get<std::string>());
        }
      }
    }
  }
};
