#include <curl/curl.h>
#include <archive.h>
#include <archive_entry.h>
#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <filesystem>

class WrapHandler {
public:
    WrapHandler() {
        curl_global_init(CURL_GLOBAL_ALL);
    }

    ~WrapHandler() {
        curl_global_cleanup();
    }

    void SetupDirectories(const std::string& outputDir, const std::string& packageFilesDir) {
        std::filesystem::create_directories(outputDir);
        std::filesystem::create_directories(packageFilesDir);
    }

    void DownloadWrapFile(const std::string& url, const std::string& outputPath) {
        CURL* curl = curl_easy_init();
        if(curl) {
            std::ofstream file(outputPath, std::ios::binary);
            curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
            curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, +[](char* ptr, size_t size, size_t nmemb, void* userdata) -> size_t {
                std::ofstream* file = static_cast<std::ofstream*>(userdata);
                file->write(ptr, size * nmemb);
                return size * nmemb;
            });
            curl_easy_setopt(curl, CURLOPT_WRITEDATA, &file);
            CURLcode res = curl_easy_perform(curl);
            if(res != CURLE_OK) {
                std::cerr << "curl_easy_perform() failed: " << curl_easy_strerror(res) << std::endl;
            }
            curl_easy_cleanup(curl);
        }
    }

    void ExtractWrapFile(const std::string& filePath, const std::string& extractTo) {
        struct archive* a;
        struct archive_entry* entry;
        int r;
        a = archive_read_new();
        archive_read_support_format_all(a);
        archive_read_support_compression_all(a);
        r = archive_read_open_filename(a, filePath.c_str(), 10240);
        if (r != ARCHIVE_OK) {
            std::cerr << "Error opening archive: " << archive_error_string(a) << std::endl;
            return;
        }
        while (archive_read_next_header(a, &entry) == ARCHIVE_OK) {
            std::string fullPath = extractTo + "/" + archive_entry_pathname(entry);
            archive_entry_set_pathname(entry, fullPath.c_str());
            r = archive_read_extract(a, entry, ARCHIVE_EXTRACT_TIME);
            if (r != ARCHIVE_OK) {
                std::cerr << "Error extracting file: " << archive_error_string(a) << std::endl;
            }
        }
        archive_read_free(a);
    }

    void ProcessWrapFiles(const std::vector<std::string>& urls, const std::string& outputDir, const std::string& packageFilesDir) {
        SetupDirectories(outputDir, packageFilesDir);
        for (const auto& url : urls) {
            std::string filename = std::filesystem::path(url).filename();
            std::string outputPath = packageFilesDir + "/" + filename;
            DownloadWrapFile(url, outputPath);
            ExtractWrapFile(outputPath, outputDir);
        }
    }
};
