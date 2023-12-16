#include "utils.hpp"

#include "log.hpp"

#include <archive.h>
#include <archive_entry.h>
#include <cctype>
#include <cerrno>
#include <cstddef>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <curl/curl.h>
#include <curl/easy.h>
#include <exception>
#include <filesystem>
#include <format>
#include <iostream>
#include <optional>
#include <ostream>
#include <pwd.h>
#include <string>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#include <uuid/uuid.h>
#include <vector>

#define HTTP_OK 200

static Logger LOG("utils"); // NOLINT

bool downloadFile(std::string url, std::filesystem::path output) {
  LOG.info(std::format("Downloading URL {} to {}", url, output.c_str()));
  auto curl = curl_easy_init();
  if (curl == nullptr) {
    LOG.error("Unable to create CURL* using curl_easy_init");
    return false;
  }
  FILE *filep = fopen(output.c_str(), "wb");
  curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
  curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, NULL);
  curl_easy_setopt(curl, CURLOPT_WRITEDATA, filep);
  curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1);
  auto res = curl_easy_perform(curl);
  long httpCode = 0;
  curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &httpCode);
  LOG.info(std::format("curl_easy_perform: {} {}", curl_easy_strerror(res),
                       httpCode));
  auto successful = res != CURLE_ABORTED_BY_CALLBACK && httpCode == HTTP_OK;
  curl_easy_cleanup(curl);
  (void)fclose(filep);
  if (!successful) {
    (void)std::remove(output.c_str());
  }
  return successful;
}

static int copyData(struct archive *ar, struct archive *aw) {
  const void *buff;
  size_t size;
  la_int64_t offset;

  for (;;) {
    auto r = archive_read_data_block(ar, &buff, &size, &offset);
    if (r == ARCHIVE_EOF) {
      return ARCHIVE_OK;
    }
    if (r < ARCHIVE_OK) {
      return r;
    }
    r = (int)archive_write_data_block(aw, buff, size, offset);
    if (r < ARCHIVE_OK) {
      std::cerr << archive_error_string(aw) << std::endl;
      return r;
    }
  }
}

bool extractFile(std::filesystem::path archivePath,
                 std::filesystem::path outputDirectory) {
  LOG.info(std::format("Extracting {} to {}", archivePath.c_str(),
                       outputDirectory.c_str()));
  auto archive = archive_read_new();
  archive_read_support_format_all(archive);
  archive_read_support_filter_all(archive);
  auto ext = archive_write_disk_new();
  archive_write_disk_set_options(
      ext, ARCHIVE_EXTRACT_TIME | ARCHIVE_EXTRACT_PERM | ARCHIVE_EXTRACT_ACL |
               ARCHIVE_EXTRACT_FFLAGS);
  archive_write_disk_set_standard_lookup(ext);

  const char *filename = archivePath.c_str();

  if (auto r = archive_read_open_filename(archive, filename, 10240)) {
    LOG.error(std::format("Unable to open archive: {}",
                          archive_error_string(archive)));
    return false;
  }

  for (;;) {
    auto entry = static_cast<struct archive_entry *>(nullptr);
    auto res = archive_read_next_header(archive, &entry);
    if (res == ARCHIVE_EOF) {
      break;
    }
    if (res < ARCHIVE_OK) {
      LOG.error(std::format("Error during reading archive: {}",
                            archive_error_string(archive)));
      return false;
    }
    auto entryPath =
        outputDirectory / std::filesystem::path(archive_entry_pathname(entry));
    archive_entry_set_pathname(entry, entryPath.string().c_str());

    if (auto res = archive_write_header(ext, entry); res < ARCHIVE_OK) {
      LOG.error(
          std::format("Failed writing header: {}", archive_error_string(ext)));
      return false;
    }
    if (archive_entry_size(entry) > 0) {
      auto copyResult = copyData(archive, ext);
      if (copyResult != ARCHIVE_OK && copyResult != ARCHIVE_EOF) {
        LOG.error(std::format("Failed writing result: {}",
                              archive_error_string(ext)));
        return false;
      }
    }

    if (auto res = archive_write_finish_entry(ext); res < ARCHIVE_OK) {
      LOG.error(
          std::format("Failed finishing entry: {}", archive_error_string(ext)));
      return false;
    }
  }

  archive_read_close(archive);
  archive_read_free(archive);
  archive_write_close(ext);
  archive_write_free(ext);
  return true;
}

bool launchProcess(const std::string &executable,
                   const std::vector<std::string> &args) {
  std::vector<const char *> cArgs;
  LOG.info(std::format("Launching {} with args {}", executable,
                       vectorToString(args)));
  cArgs.push_back(executable.c_str());

  for (const auto &arg : args) {
    cArgs.push_back(arg.c_str());
  }
  cArgs.push_back(nullptr);

  pid_t pid = fork();
  if (pid == -1) {
    LOG.error(std::format("Failed to fork(): {}", errno2string()));
    return false;
  }
  if (pid == 0) { // Child process
    if (execvp(executable.c_str(), const_cast<char *const *>(cArgs.data())) ==
        -1) {
      LOG.error(std::format("Failed to execvp(): {}", errno2string()));
      return false;
    }
    return false;
  }
  // Parent process
  int status;
  waitpid(pid, &status, 0);
  if (WIFEXITED(status)) {          // NOLINT
    if (WEXITSTATUS(status) == 0) { // NOLINT
      return true;
    }
    LOG.warn(std::format("Child process exited with status: {}",
                         WEXITSTATUS(status))); // NOLINT
    return false;
  }
  LOG.info("Child process terminated abnormally");
  return false;
}

std::string errno2string() {
  char buf[256] = {0};
  strerror_r(errno, buf, sizeof(buf) - 1); // NOLINT
  return std::string(buf);
}

std::string randomFile() {
  auto tmpdir = getenv("TMPDIR");
  if (tmpdir == nullptr) {
    tmpdir = (char *)"/tmp";
  }
  uuid_t filename;
  uuid_generate(filename);
  char out[UUID_STR_LEN + 1] = {0};
  uuid_unparse(filename, out);
  return std::format("{}/{}", tmpdir, out);
}

void mergeDirectories(std::filesystem::path sourcePath,
                      std::filesystem::path destinationPath) {
  try {
    for (const auto &entry :
         std::filesystem::recursive_directory_iterator(sourcePath)) {
      auto relativePath = std::filesystem::relative(entry.path(), sourcePath);
      auto destination = destinationPath / relativePath;

      if (std::filesystem::is_directory(entry.status())) {
        std::filesystem::create_directories(destination);
      } else if (std::filesystem::is_regular_file(entry.status())) {
        std::filesystem::copy_file(
            entry.path(), destination,
            std::filesystem::copy_options::overwrite_existing);
      }
    }
  } catch (const std::exception &ex) {
    std::cerr << "Error: " << ex.what() << std::endl;
  }
}

static std::filesystem::path cacheDir() {
  auto suffix = "c++-mesonlsp";
  auto xdgCacheHome = getenv("XDG_CACHE_HOME"); // NOLINT
  if (xdgCacheHome != nullptr && strcmp(xdgCacheHome, "") != 0) {
    auto full = std::filesystem::path{xdgCacheHome} / suffix;
    std::filesystem::create_directories(full);
    return full;
  }
  auto home = getenv("HOME"); // NOLINT
  if (home == nullptr || strcmp(home, "") == 0) {
    home = getpwuid(getuid())->pw_dir; // NOLINT
  }
  auto full = std::filesystem::path{home} / ".cache" / suffix;
  std::filesystem::create_directories(full);
  return full;
}

std::optional<std::filesystem::path> cachedDownload(std::string url) {
  auto downloadsPath = cacheDir() / "downloadCache";
  if (!std::filesystem::exists(downloadsPath)) {
    std::filesystem::create_directories(downloadsPath);
  }
  auto key = hash(url) + ".cached";
  auto cachedFile = downloadsPath / key;
  if (std::filesystem::exists(cachedFile)) {
    return cachedFile;
  }
  if (downloadFile(url, cachedFile)) {
    return cachedFile;
  }
  return std::nullopt;
}

bool validateHash(std::filesystem::path path, std::string expected) {
  auto real = hash(path);
  if (real.size() != expected.size()) {
    LOG.warn(std::format("Expected hash '{}' does not match real hash '{}'",
                         expected, real));
    return false;
  }
  for (size_t i = 0; i < real.size(); i++) {
    if (std::tolower(real[i]) != std::tolower(expected[i])) {
      LOG.warn(std::format("Expected hash '{}' does not match real hash '{}'",
                           expected, real));
      return false;
    }
  }
  LOG.info(std::format("{} matches the expected hash", path.c_str()));
  return true;
}

std::optional<std::filesystem::path>
downloadWithFallback(std::string url, std::string hash,
                     std::optional<std::string> fallbackUrl) {
  auto mainUrlDownload = cachedDownload(url);
  if (mainUrlDownload.has_value()) {
    if (validateHash(mainUrlDownload.value(), hash)) {
      return mainUrlDownload;
    }
  }
  if (!fallbackUrl.has_value()) {
    LOG.warn(std::format("No fallback URL for {} listed", url));
    return std::nullopt;
  }
  LOG.info(std::format("Attempting fallback URL {} for {}", fallbackUrl.value(),
                       url));
  auto fallbackUrlDownload = cachedDownload(fallbackUrl.value());
  if (fallbackUrlDownload.has_value()) {
    if (validateHash(fallbackUrlDownload.value(), hash)) {
      return fallbackUrlDownload;
    }
  }
  LOG.warn("Unable to find any matching URL!");
  return std::nullopt;
}
