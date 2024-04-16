#pragma once
#include "analysisoptions.hpp"

#include <filesystem>
#include <optional>
#include <string>

enum class FileFinderMode { TRACKED, ALL };

struct MuonConfig {
  FileFinderMode mode = FileFinderMode::TRACKED;
  int max_line_len = 80;
  std::optional<std::string> indent_by;
  bool space_array = false;
  bool kwargs_force_multiline = false;
  bool wide_colon = false;
  bool no_single_comma_function = false;
  std::string indent_style = "space";
  int indent_size = 4;
  bool insert_final_newline = true;
  bool sort_files = true;
  bool group_arg_value = true;
  bool simplify_string_literals = false;
  std::string indent_before_comments = " ";
  std::optional<std::string> end_of_line = std::nullopt;
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
