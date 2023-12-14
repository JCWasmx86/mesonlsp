#include "ini.hpp"
#include "log.hpp"
#include "utils.hpp"
#include "wrap.hpp"
#include <cctype>
#include <charconv>
#include <format>
#include <fstream>
#include <string>
#include <vector>

static Logger LOG("wrap::GitWrap"); // NOLINT

GitWrap::GitWrap(ast::ini::Section *section) : VcsWrap(section) {
  if (auto pushUrl = section->find_string_value("push-url")) {
    this->pushUrl = pushUrl;
  }
  if (auto depthString = section->find_string_value("depth")) {
    int number;
    auto res = std::from_chars(
        depthString->data(), depthString->data() + depthString->size(), number);
    if (res.ec == std::errc{}) {
      this->depth = number;
    }
  }
  if (auto val = section->find_string_value("clone-recursive")) {
    this->cloneRecursive = val == "true";
  }
}

static bool isValidCommitId(std::string rev) {
  if (rev.size() != 40 && rev.size() != 64) {
    return false;
  }
  for (auto chr : rev) {
    if (std::isxdigit(chr) == 0) {
      return false;
    }
  }
  return true;
}

static bool isHead(std::string rev) {
  return rev.size() == 4 &&
         (std::tolower(rev[0]) == 'h' && std::tolower(rev[1]) == 'e' &&
          std::tolower(rev[2]) == 'a' && std::tolower(rev[3]) == 'd');
}

void GitWrap::setupDirectory(std::filesystem::path path,
                             std::filesystem::path packageFilesPath) {
  auto url = this->url;
  if (url.empty()) {
    LOG.warn("URL is empty");
    return;
  }
  if (this->revision.empty()) {
    LOG.warn("Revision is empty");
    return;
  }
  if (!this->directory.has_value()) {
    LOG.warn("Directory is empty");
    return;
  }
  auto rev = this->revision;
  auto targetDirectory = this->directory.value();
  std::string fullPath = std::format("{}/{}", path.c_str(), targetDirectory);
  auto isShallow = this->depth != 0;
  auto depthOptions =
      isShallow
          ? std::vector<std::string>{"--depth", std::to_string(this->depth)}
          : std::vector<std::string>{};
  if (isShallow && isValidCommitId(rev)) {
    auto result = launchProcess(
        "git", std::vector<std::string>{
                   "-c", "init.defaultBranch=mesonlsp-dummy-branch", "init",
                   fullPath});
    result = launchProcess(
        "git", std::vector<std::string>{"-C", fullPath, "remote", "add",
                                        "origin", this->url});
    auto fetchOptions = std::vector<std::string>{"-C", fullPath, "fetch"};
    fetchOptions.insert(fetchOptions.end(), depthOptions.begin(),
                        depthOptions.end());
    fetchOptions.push_back("origin");
    fetchOptions.push_back(rev);
    result = launchProcess("git", fetchOptions);
    result = launchProcess("git",
                           std::vector<std::string>{"-C", fullPath, "-c",
                                                    "advice.detachedHead=false",
                                                    "checkout", rev, "--"});
  } else {
    if (!isShallow) {
      auto result = launchProcess(
          "git", std::vector<std::string>{"clone", this->url, fullPath});
      if (!isHead(rev)) {
        result = launchProcess(
            "git", std::vector<std::string>{"-C", fullPath, "-c",
                                            "advice.detachedHead=false",
                                            "checkout", rev, "--"});
        if (!result) {
          result = launchProcess(
              "git", std::vector<std::string>{"-C", fullPath, "fetch",
                                              this->url, rev});
          result = launchProcess(
              "git", std::vector<std::string>{"-C", fullPath, "-c",
                                              "advice.detachedHead=false",
                                              "checkout", rev, "--"});
        }
      }
    } else {
      std::vector<std::string> args{"-c", "advice.detachedHead=false", "clone"};
      args.insert(args.end(), depthOptions.begin(), depthOptions.end());
      if (!isHead(rev)) {
        args.push_back("--branch");
        args.push_back(rev);
      }
      args.push_back(this->url);
      args.push_back(fullPath);
      auto result = launchProcess("git", args);
    }
  }
  if (this->cloneRecursive) {
    auto cloneOptions =
        std::vector<std::string>{"-C",     fullPath,     "submodule",  "update",
                                 "--init", "--checkout", "--recursive"};
    cloneOptions.insert(cloneOptions.end(), depthOptions.begin(),
                        depthOptions.end());
    auto result = launchProcess("git", cloneOptions);
  }
  if (auto pushUrl = this->pushUrl) {
    auto result = launchProcess(
        "git", std::vector<std::string>{"-C", fullPath, "remote", "set-url",
                                        "--push", "origin", pushUrl.value()});
  }
  this->postSetup(fullPath, packageFilesPath);
  if (!isValidCommitId(rev)) {
    return;
  }
  auto result = launchProcess(
      "git", std::vector<std::string>{"-C", fullPath, "pull", "origin"});
  if (result) {
    auto pullableFile = std::filesystem::path{fullPath} / ".git_pullable";
    std::ofstream{pullableFile}.put('\n');
  }
}
