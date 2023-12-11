#include "utils.hpp"
#include <archive.h>
#include <archive_entry.h>
#include <cstdio>
#include <curl/curl.h>
#include <curl/easy.h>
#include <iostream>
#include <ostream>

bool download_file(std::string url, std::filesystem::path output) {
  auto curl = curl_easy_init();
  if (!curl)
    return false;
  FILE *fp = fopen(output.c_str(), "wb");
  curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
  curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, NULL);
  curl_easy_setopt(curl, CURLOPT_WRITEDATA, fp);
  curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1);
  auto res = curl_easy_perform(curl);
  long http_code = 0;
  curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &http_code);
  auto successful = res != CURLE_ABORTED_BY_CALLBACK && http_code == 200;
  curl_easy_cleanup(curl);
  fclose(fp);
  if (!successful)
    (void)remove(output.c_str());
  return successful;
}
static int copy_data(struct archive *ar, struct archive *aw) {
  const void *buff;
  size_t size;
  la_int64_t offset;

  for (;;) {
    auto r = archive_read_data_block(ar, &buff, &size, &offset);
    if (r == ARCHIVE_EOF)
      return ARCHIVE_OK;
    if (r < ARCHIVE_OK)
      return r;
    r = (int)archive_write_data_block(aw, buff, size, offset);
    if (r < ARCHIVE_OK) {
      std::cerr << archive_error_string(aw) << std::endl;
      return r;
    }
  }
}

bool extract_file(std::filesystem::path archive_path,
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
      if (copy_data(a, ext) == 0) {
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
