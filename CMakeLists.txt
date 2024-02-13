cmake_minimum_required(VERSION 3.10)
project(MesonLSP VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Include directories
include_directories(include)

# Find required packages
find_package(CURL REQUIRED)
find_package(LibArchive REQUIRED)
find_package(tree-sitter REQUIRED)
find_package(OpenSSL REQUIRED)
find_package(UUID REQUIRED)

# Add executable target
add_executable(meson_lsp
    src/main.cpp
    src/lsp.cpp
    src/linting.cpp
    src/testing.cpp
    src/wrap_handling.cpp
)

# Link libraries
target_link_libraries(meson_lsp
    PRIVATE
        CURL::libcurl
        LibArchive::LibArchive
        tree-sitter::tree-sitter
        OpenSSL::Crypto
        UUID::UUID
)

# Define build targets for functionalities
target_compile_definitions(meson_lsp PRIVATE
    MESON_LSP_LINTING
    MESON_LSP_TESTING
    MESON_LSP_WRAP_HANDLING
)
