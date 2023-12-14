#include "utils.hpp"
#include <archive.h>
#include <archive_entry.h>
#include <cstdio>
#include <cstring>
#include <curl/curl.h>
#include <curl/easy.h>
#include <format>
#include <iostream>
#include <ostream>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#include <uuid/uuid.h>

#define HTTP_OK 200

bool downloadFile(std::string url, std::filesystem::path output) {
  auto curl = curl_easy_init();
  if (curl == nullptr) {
    return false;
  }
  FILE *filep = fopen(output.c_str(), "wb");
  curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
  curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, NULL);
  curl_easy_setopt(curl, CURLOPT_WRITEDATA, filep);
  curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1);
  auto res = curl_easy_perform(curl);
  long http_code = 0;
  curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &http_code);
  auto successful = res != CURLE_ABORTED_BY_CALLBACK && http_code == HTTP_OK;
  curl_easy_cleanup(curl);
  (void)fclose(filep);
  if (!successful) {
    (void)remove(output.c_str());
  }
  return successful;
}
static int copy_data(struct archive *ar, struct archive *aw) {
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

bool extractFile(std::filesystem::path archive_path,
                 std::filesystem::path output_directory) {
  auto a = archive_read_new();
  archive_read_support_format_all(a);
  archive_read_support_filter_all(a);
  auto ext = archive_write_disk_new();
  archive_write_disk_set_options(
      ext, ARCHIVE_EXTRACT_TIME | ARCHIVE_EXTRACT_PERM | ARCHIVE_EXTRACT_ACL |
               ARCHIVE_EXTRACT_FFLAGS);
  archive_write_disk_set_standard_lookup(ext);

  const char *filename = archive_path.c_str();

  if (auto r = archive_read_open_filename(a, filename, 10240)) {
    std::cerr << archive_error_string(a) << r << std::endl;
    return false;
  }

  for (;;) {
    auto entry = static_cast<struct archive_entry *>(nullptr);
    auto r = archive_read_next_header(a, &entry);
    if (r == ARCHIVE_EOF) {
      break;
    }
    if (r < ARCHIVE_OK) {
      std::cerr << archive_error_string(a) << std::endl;
      return false;
    }

    auto entry_path =
        output_directory / std::filesystem::path(archive_entry_pathname(entry));
    archive_entry_set_pathname(entry, entry_path.string().c_str());

    if (auto r = archive_write_header(ext, entry); r < ARCHIVE_OK) {
      std::cerr << archive_error_string(ext) << std::endl;
      return false;
    } else if (archive_entry_size(entry) > 0) {
      auto copy_result = copy_data(a, ext);
      if (copy_result != ARCHIVE_OK && copy_result != ARCHIVE_EOF) {
        std::cerr << archive_error_string(ext) << std::endl;
        return false;
      }
    }

    if (auto r = archive_write_finish_entry(ext); r < ARCHIVE_OK) {
      std::cerr << archive_error_string(ext) << std::endl;
      return false;
    }
  }

  archive_read_close(a);
  archive_read_free(a);
  archive_write_close(ext);
  archive_write_free(ext);
  return true;
}

bool launchProcess(const std::string &executable,
                   const std::vector<std::string> &args) {
  std::vector<const char *> cArgs;
  cArgs.push_back(executable.c_str());

  for (const auto &arg : args) {
    cArgs.push_back(arg.c_str());
  }
  cArgs.push_back(nullptr);

  pid_t pid = fork();
  if (pid == -1) {
    perror("fork");
    return false;
  }
  if (pid == 0) { // Child process
    if (execvp(executable.c_str(), const_cast<char *const *>(cArgs.data())) ==
        -1) {
      perror("execvp");
      return false;
    }
    return false;
  }
  // Parent process
  int status;
  waitpid(pid, &status, 0);
  if (WIFEXITED(status)) {
    if (WEXITSTATUS(status) == 0) {
      return true;
    }
    std::cerr << "Child process exited with status: " << WEXITSTATUS(status)
              << std::endl;
    return false;
  }
  std::cerr << "Child process terminated abnormally" << std::endl;
  return false;
}

std::string errno2string() {
  char buf[256] = {0};
  strerror_r(errno, buf, sizeof(buf) - 1);
  return std::string(buf);
}

std::string randomFile() {
  auto tmpdir = getenv("TMPDIR");
  if (tmpdir == nullptr) {
    tmpdir = (char *)"/tmp";
  }
  uuid_t filename;
  uuid_generate(filename);
  char out[37] = {0};
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
