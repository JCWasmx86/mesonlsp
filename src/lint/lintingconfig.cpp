#include "lintingconfig.hpp"

#include "toml++/impl/forward_declarations.hpp"

#include <toml++/toml.hpp>

void MesonLintConfig::load(const std::filesystem::path &path) {
  auto result = toml::parse_file(path.generic_string());
  if (result.contains("formatting") &&
      result.get("formatting")->type() == toml::v3::node_type::table) {
    const auto *formatting = result["formatting"].as_table();
    if (formatting->contains("max_line_len") &&
        formatting->get("max_line_len")->type() ==
            toml::v3::node_type::integer) {
      this->formatting.max_line_len =
          (int)formatting->get("max_line_len")->as_integer()->get();
    }
    if (formatting->contains("indent_by") &&
        formatting->get("indent_by")->type() == toml::v3::node_type::string) {
      this->formatting.indent_by =
          formatting->get("indent_by")->as_string()->get();
    }
    if (formatting->contains("space_array") &&
        formatting->get("space_array")->type() ==
            toml::v3::node_type::boolean) {
      this->formatting.space_array =
          formatting->get("space_array")->as_boolean()->get();
    }
    if (formatting->contains("kwargs_force_multiline") &&
        formatting->get("kwargs_force_multiline")->type() ==
            toml::v3::node_type::boolean) {
      this->formatting.kwargs_force_multiline =
          formatting->get("kwargs_force_multiline")->as_boolean()->get();
    }
    if (formatting->contains("wide_colon") &&
        formatting->get("wide_colon")->type() == toml::v3::node_type::boolean) {
      this->formatting.wide_colon =
          formatting->get("wide_colon")->as_boolean()->get();
    }
    if (formatting->contains("no_single_comma_function") &&
        formatting->get("no_single_comma_function")->type() ==
            toml::v3::node_type::boolean) {
      this->formatting.no_single_comma_function =
          formatting->get("no_single_comma_function")->as_boolean()->get();
    }
  }
  if (result.contains("linting") &&
      result.get("linting")->type() == toml::v3::node_type::table) {
    const auto *linting = result.get("linting")->as_table();
#define STRINGIFY(x) #x
#define TOSTRING(x) STRINGIFY(x)
#define DESERIALIZE_ANALYSIS_OPTION(key)                                       \
  if (linting->contains(TOSTRING(key)) &&                                      \
      linting->get(TOSTRING(key))->type() == toml::v3::node_type::boolean) {   \
    this->linting.options.key =                                                \
        linting->get(TOSTRING(key))->as_boolean()->get();                      \
  }
    DESERIALIZE_ANALYSIS_OPTION(disableNameLinting)
    DESERIALIZE_ANALYSIS_OPTION(disableAllIdLinting)
    DESERIALIZE_ANALYSIS_OPTION(disableCompilerIdLinting)
    DESERIALIZE_ANALYSIS_OPTION(disableCompilerArgumentIdLinting)
    DESERIALIZE_ANALYSIS_OPTION(disableLinkerIdLinting)
    DESERIALIZE_ANALYSIS_OPTION(disableCpuFamilyLinting)
    DESERIALIZE_ANALYSIS_OPTION(disableOsFamilyLinting)
    DESERIALIZE_ANALYSIS_OPTION(disableUnusedVariableCheck)
    DESERIALIZE_ANALYSIS_OPTION(disableArgTypeChecking)
  }
}
