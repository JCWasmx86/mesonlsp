#include "ini.hpp"
#include "log.hpp"
#include "polyfill.hpp"
#include "utils.hpp"
#include "wrap.hpp"

#include <algorithm>
#include <cctype>
#include <charconv>
#include <filesystem>
#include <fstream>
#include <string>
#include <system_error>
#include <vector>

const static Logger LOG("wrap::GitWrap"); // NOLINT

GitWrap::GitWrap(ast::ini::Section *node) : VcsWrap(node) {
  if (auto optPushUrl = node->findStringValue("push-url")) {
    this->pushUrl = optPushUrl;
  }
  if (auto depthString = node->findStringValue("depth")) {
    int number;
    auto res = std::from_chars(
        depthString->data(), depthString->data() + depthString->size(), number);
    if (res.ec == std::errc{}) {
      this->depth = number;
    }
  }
  if (auto val = node->findStringValue("clone-recursive")) {
    this->cloneRecursive = val == "true";
  }
}

static bool isValidCommitId(std::string rev) {
  if (rev.size() != 40 && rev.size() != 64) {
    return false;
  }
  return std::ranges::all_of(rev, [](char chr) { return std::isxdigit(chr); });
}

static bool isHead(std::string rev) {
  return rev.size() == 4 &&
         (std::tolower(rev[0]) == 'h' && std::tolower(rev[1]) == 'e' &&
          std::tolower(rev[2]) == 'a' && std::tolower(rev[3]) == 'd');
}

bool GitWrap::setupDirectory(const std::filesystem::path &path,
                             const std::filesystem::path &packageFilesPath) {
  auto url = this->url;
  if (url.empty()) {
    LOG.warn("URL is empty");
    this->errors.emplace_back("Missing url");
    return false;
  }
  if (this->revision.empty()) {
    LOG.warn("Revision is empty");
    this->errors.emplace_back("Missing revision");
    return false;
  }
  if (!this->directory.has_value()) {
    LOG.warn("Directory is empty");
    this->errors.emplace_back("Missing directory");
    return false;
  }
  auto rev = this->revision;
  auto targetDirectory = this->directory.value();
  std::filesystem::path const fullPath =
      std::format("{}/{}", path.generic_string(), targetDirectory);
  auto isShallow = this->depth != 0;
  auto depthOptions =
      isShallow
          ? std::vector<std::string>{"--depth", std::to_string(this->depth)}
          : std::vector<std::string>{};
  if (isShallow && isValidCommitId(rev)) {
    auto result = launchProcess(
        "git", std::vector<std::string>{
                   "-c", "init.defaultBranch=mesonlsp-dummy-branch", "init",
                   fullPath.generic_string()});
    if (!result) {
      this->errors.emplace_back("Failed to do git init");
      return false;
    }
    result = launchProcess(
        "git", std::vector<std::string>{"-C", fullPath.generic_string(),
                                        "remote", "add", "origin", this->url});
    if (!result) {
      this->errors.emplace_back("Failed to do remote add origin");
      return false;
    }
    auto fetchOptions =
        std::vector<std::string>{"-C", fullPath.generic_string(), "fetch"};
    fetchOptions.insert(fetchOptions.end(), depthOptions.begin(),
                        depthOptions.end());
    fetchOptions.emplace_back("origin");
    fetchOptions.push_back(rev);
    result = launchProcess("git", fetchOptions);
    if (!result) {
      this->errors.emplace_back("Failed to do git fetch origin");
      return false;
    }
    result = launchProcess(
        "git", std::vector<std::string>{"-C", fullPath.generic_string(), "-c",
                                        "advice.detachedHead=false", "checkout",
                                        rev, "--"});
    if (!result) {
      this->errors.emplace_back("Failed to do git checkout");
      return false;
    }
  } else {
    if (!isShallow) {
      auto result = launchProcess(
          "git", std::vector<std::string>{"clone", this->url,
                                          fullPath.generic_string()});
      if (!result) {
        this->errors.emplace_back("Failed to do git clone");
        return false;
      }
      if (!isHead(rev)) {
        result = launchProcess(
            "git", std::vector<std::string>{"-C", fullPath.generic_string(),
                                            "-c", "advice.detachedHead=false",
                                            "checkout", rev, "--"});
        if (!result) {
          result = launchProcess(
              "git", std::vector<std::string>{"-C", fullPath.generic_string(),
                                              "fetch", this->url, rev});
          if (!result) {
            this->errors.emplace_back("Failed to do git checkout/fetch");
            return false;
          }
          result = launchProcess(
              "git", std::vector<std::string>{"-C", fullPath.generic_string(),
                                              "-c", "advice.detachedHead=false",
                                              "checkout", rev, "--"});
          if (!result) {
            this->errors.emplace_back("Failed to do git checkout/checkout");
            return false;
          }
        }
      }
    } else {
      std::vector<std::string> args{"-c", "advice.detachedHead=false", "clone"};
      args.insert(args.end(), depthOptions.begin(), depthOptions.end());
      if (!isHead(rev)) {
        args.emplace_back("--branch");
        args.push_back(rev);
      }
      args.push_back(this->url);
      args.push_back(fullPath.generic_string());
      auto result = launchProcess("git", args);
      if (!result) {
        this->errors.emplace_back("Failed to do git clone with a branch");
        return false;
      }
    }
  }
  if (this->cloneRecursive) {
    auto cloneOptions =
        std::vector<std::string>{"-C",         fullPath.generic_string(),
                                 "submodule",  "update",
                                 "--init",     "--checkout",
                                 "--recursive"};
    cloneOptions.insert(cloneOptions.end(), depthOptions.begin(),
                        depthOptions.end());
    auto result = launchProcess("git", cloneOptions);
    if (!result) {
      this->errors.emplace_back("Failed to update git submodules");
      return false;
    }
  }
  if (auto optPushUrl = this->pushUrl) {
    auto result = launchProcess(
        "git", std::vector<std::string>{"-C", fullPath.generic_string(),
                                        "remote", "set-url", "--push", "origin",
                                        optPushUrl.value()});
    if (!result) {
      this->errors.emplace_back("Failed to set push url");
      return false;
    }
  }
  if (!this->postSetup(fullPath, packageFilesPath)) {
    return false;
  }
  if (isValidCommitId(rev)) {
    return true;
  }
  auto result = launchProcess(
      "git", std::vector<std::string>{"-C", fullPath.generic_string(), "pull",
                                      "origin"});
  if (result) {
    auto pullableFile = fullPath / ".git_pullable";
    std::ofstream{pullableFile}.put('\n');
  }
  // If it fails, it was a tag, not a branch
  return true;
}
