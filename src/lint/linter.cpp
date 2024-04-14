#include "linter.hpp"

#include "formatting.hpp"
#include "lintingconfig.hpp"
#include "log.hpp"
#include "mesonmetadata.hpp"
#include "mesontree.hpp"
#include "utils.hpp"

#include <cstdint>
#include <filesystem>
#include <format>
#include <ranges>
#include <stdexcept>

const static Logger LOG("linter"); // NOLINT

void Linter::writeMuonConfigFile() {
  const auto &name =
      std::format("muonlint-fmt-{}", hash(this->root.generic_string()));
  const auto &fullPath = cacheDir() / name;
  if (std::filesystem::exists(fullPath)) {
    std::filesystem::remove(fullPath);
  }
  std::ofstream fileStream(fullPath);
  assert(fileStream.is_open());
  const auto &cfg = this->config.formatting;
  fileStream << std::boolalpha << "max_line_len = " << cfg.max_line_len
             << std::endl;
  fileStream << "indent_by = "
             << "'" << cfg.indent_by << "'" << std::endl;
  fileStream << "space_array = " << cfg.space_array << std::endl;
  fileStream << "kwargs_force_multiline = " << cfg.kwargs_force_multiline
             << std::endl;
  fileStream << "wide_colon = " << cfg.wide_colon << std::endl;
  fileStream << "no_single_comma_function = " << cfg.no_single_comma_function
             << std::endl;
  fileStream.close();
  this->muonConfigFile = fullPath;
}

void Linter::printDiagnostics() const {
  const auto &metadata = tree.metadata;
  const auto &keyview = std::views::keys(metadata.diagnostics);
  std::vector<std::filesystem::path> keys{keyview.begin(), keyview.end()};
  std::ranges::sort(keys);
  uint32_t numErrors = 0;
  for (const auto &file : keys) {
    const auto &relative =
        std::filesystem::relative(file, tree.root).generic_string();
    const auto &diags = metadata.diagnostics.at(file);
    std::vector<Diagnostic> diagsSorted{diags.begin(), diags.end()};
    std::ranges::sort(diagsSorted,
                      [](const Diagnostic &lhs, const Diagnostic &rhs) {
                        if (lhs.startLine != rhs.endLine) {
                          return lhs.startLine < rhs.startLine;
                        }
                        return lhs.startColumn < rhs.startColumn;
                      });
    for (const auto &diag : diagsSorted) {
      const auto isError =
          diag.severity == Severity::ERROR || this->config.linting.werror;
      if (isError) {
        numErrors++;
      }
      const auto *icon = isError ? "🔴" : "⚠️";
      std::cerr << relative << "[" << diag.startLine + 1 << ":"
                << diag.startColumn << "] " << icon << "  " << diag.message
                << std::endl;
    }
  }
  if (numErrors == 0) {
    std::cout << "No linting errors found ✨ 🍰 ✨" << std::endl;
  }
  for (const auto &path : std::views::keys(this->unformattedFiles)) {
    const auto &relative = std::filesystem::relative(path, this->root);
    std::cerr << std::format("File {} is unformatted",
                             relative.generic_string())
              << std::endl;
  }
  if (this->unformattedFiles.empty()) {
    std::cout << "Everything is formatted ✨ 🍰 ✨" << std::endl;
  }
}

bool Linter::lintFormatting() {
  this->writeMuonConfigFile();
  if (this->config.formatting.mode == FileFinderMode::TRACKED) {
    this->lintFormattingTracked();
  } else {
    throw std::runtime_error("Unimplemented!!");
  }
  return this->unformattedFiles.empty();
}

void Linter::lintFormatting(const std::filesystem::path &path) {
  LOG.info(
      std::format("Checking formatting of file {}", path.generic_string()));
  const auto &contents = readFile(path);
  const auto formatted = formatFile(std::filesystem::absolute(path), contents,
                                    this->muonConfigFile);
  if (contents != formatted) {
    this->unformattedFiles[path] = formatted;
  }
}

void Linter::lintFormattingTracked() {
  for (const auto &file : this->tree.ownedFiles) {
    this->lintFormatting(file);
  }
  const auto &pkgFiles = this->root / "subprojects" / "packagefiles";
  if (!std::filesystem::exists(pkgFiles)) {
    return;
  }
  for (auto const &dirEntry :
       std::filesystem::recursive_directory_iterator(pkgFiles)) {
    const auto &name = dirEntry.path().filename().generic_string();
    const auto matching = name == "meson.build" || name == "meson.options" ||
                          name == "meson_options.txt";
    if (!matching) {
      continue;
    }
    this->lintFormatting(dirEntry.path());
  }
}

bool Linter::lintCode() {
  this->tree.useCustomParser = true;
  tree.partialParse(this->config.linting.options);
  const auto &metadata = tree.metadata;
  const auto &keyview = std::views::keys(metadata.diagnostics);
  uint32_t numErrors = 0;
  for (const auto &file : keyview) {
    const auto &relative =
        std::filesystem::relative(file, tree.root).generic_string();
    for (const auto &diag : metadata.diagnostics.at(file)) {
      const auto isError =
          diag.severity == Severity::ERROR || this->config.linting.werror;
      if (isError) {
        numErrors++;
      }
    }
  }
  return numErrors == 0;
}
