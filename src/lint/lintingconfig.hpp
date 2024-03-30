#include "analysisoptions.hpp"

#include <filesystem>
#include <string>

struct MuonConfig {
  int max_line_len = 80;
  std::string indent_by = "    ";
  bool space_array = false;
  bool kwargs_force_multiline = false;
  bool wide_colon = false;
  bool no_single_comma_function = false;
};

struct LintingConfig {
  bool werror = false;
  AnalysisOptions options;
};

struct MesonLintConfig {
  MuonConfig formatting;
  LintingConfig linting;

  void load(const std::filesystem::path &path);
};
