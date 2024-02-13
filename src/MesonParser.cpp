#include "tree_sitter/api.h"
#include "tree_sitter_meson.h"
#include <fstream>
#include <sstream>
#include <iostream>
#include <stdexcept>

class MesonParser {
private:
    TSParser *parser;
    TSTree *tree;

    void readAndParseFile(const std::string &filePath) {
        std::ifstream fileStream(filePath);
        if (!fileStream.is_open()) {
            throw std::runtime_error("Failed to open file: " + filePath);
        }
        std::stringstream buffer;
        buffer << fileStream.rdbuf();
        std::string fileContent = buffer.str();
        tree = ts_parser_parse_string(parser, nullptr, fileContent.c_str(), fileContent.length());
    }

public:
    MesonParser() {
        parser = ts_parser_new();
        TSLanguage *language = tree_sitter_meson();
        ts_parser_set_language(parser, language);
    }

    ~MesonParser() {
        ts_tree_delete(tree);
        ts_parser_delete(parser);
    }

    void parseFile(const std::string &filePath) {
        readAndParseFile(filePath);
    }

    std::string extractProjectName() {
        TSNode rootNode = ts_tree_root_node(tree);
        // Traversal and extraction logic for project name
        // Placeholder for actual implementation
        return "Extracted Project Name";
    }

    std::vector<std::string> extractDependencies() {
        std::vector<std::string> dependencies;
        // Traversal and extraction logic for dependencies
        // Placeholder for actual implementation
        return dependencies;
    }

    std::vector<std::string> extractSourceFiles() {
        std::vector<std::string> sourceFiles;
        // Traversal and extraction logic for source files
        // Placeholder for actual implementation
        return sourceFiles;
    }
};
