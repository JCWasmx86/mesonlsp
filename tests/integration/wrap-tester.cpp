#include <iostream>
#ifdef NDEBUG
#undef NDEBUG
#endif

#include "utils.hpp"
#include "wrap.hpp"

#include <cassert>
#include <filesystem>

std::shared_ptr<WrapFile> parseWrapWrapper(const std::filesystem::path &path) {
  auto wrap = parseWrap(path);
  assert(wrap);
  assert(wrap->serializedWrap);
  return wrap;
}

void checkLibswiftDemangle(const std::filesystem::path &path) {
  const auto gitRefPath = path / "libswiftdemangle/.git/refs/heads/main";
  std::cerr << "Checking if " << gitRefPath.generic_string() << " exists "
            << std::endl;
  assert(!std::filesystem::exists(gitRefPath));
  assert(std::filesystem::exists(gitRefPath.parent_path()));
}

void checkLibswiftDemangle2(const std::filesystem::path &path) {
  const auto gitRefPath = path / "libswiftdemangle2/.git/refs/heads/main";
  assert(std::filesystem::exists(gitRefPath));
  const auto contents = readFile(gitRefPath);
  assert(contents.contains("e96565e27f95865830626f5d8a081b69cfe5ea11"));
}

void checkMiniz(const std::filesystem::path &path) {
  const auto basePath = path / "miniz-3.0.1";
  assert(std::filesystem::exists(basePath));
  assert(std::filesystem::exists(basePath / "miniz.c"));
  assert(std::filesystem::exists(basePath / "meson.build"));
}

void checkTurtle(const std::filesystem::path &path) {
  const auto basePath = path / "turtle-1.3.2";
  assert(std::filesystem::exists(basePath));
  assert(std::filesystem::exists(basePath / "doc"));
  assert(std::filesystem::exists(basePath / "meson.build"));
}

void checkSqlite(const std::filesystem::path &path) {
  const auto basePath = path / "sqlite-amalgamation-3080802";
  assert(std::filesystem::exists(basePath));
  assert(std::filesystem::exists(basePath / "meson.build"));
}

void checkPango(const std::filesystem::path &path) {
  const auto basePath = path / "pango-1.50.12";
  assert(std::filesystem::exists(basePath));
  assert(std::filesystem::exists(basePath / "meson.build"));
  const auto contents = readFile(basePath / "meson.build");
  assert(contents.contains("FOOBARBAZ"));
}

void checkTurtle2(const std::filesystem::path &path) {
  const auto basePath = path / "turtle-21.3.2";
  assert(std::filesystem::exists(basePath));
  assert(std::filesystem::exists(basePath / "doc"));
  assert(std::filesystem::exists(basePath / "meson.build"));
}

void checkTurtle3(const std::filesystem::path &path) {
  const auto basePath = path / "turtle-31.3.2";
  assert(std::filesystem::exists(basePath));
  assert(std::filesystem::exists(basePath / "doc"));
  assert(std::filesystem::exists(basePath / "meson.build"));
}

void checkPidgin(const std::filesystem::path &path) {
  const auto basePath = path / "pidgin";
  assert(std::filesystem::exists(basePath));
  assert(std::filesystem::exists(basePath / "meson.build"));
}

void checkVorbis(const std::filesystem::path &path) {
  const auto basePath = path / "vorbis";
  assert(std::filesystem::exists(basePath));
  assert(std::filesystem::exists(basePath / "vorbis.m4"));
}

void checkRubberband(const std::filesystem::path &path) {
  const auto basePath = path / "rubberband-2.0.2";
  assert(std::filesystem::exists(basePath));
  assert(std::filesystem::exists(basePath / "meson.build"));
}

int main(int /*argc*/, char **argv) {
  std::filesystem::path first{argv[1]};
  auto wrapDir = first.parent_path();
  auto packagefilesPath = wrapDir / "packagefiles";
  std::filesystem::path outputPath =
      std::filesystem::current_path() / "wrap-tester-out/";
  if (std::filesystem::exists(outputPath)) {
    std::filesystem::remove_all(outputPath);
  }
  std::filesystem::create_directory(outputPath);
  auto wrap = parseWrapWrapper(wrapDir / "libswiftdemangle.wrap");
  auto outputDir = outputPath / "libswiftdemangle.wrap";
  auto res = wrap->serializedWrap->setupDirectory(outputDir, packagefilesPath);
  assert(res);
  checkLibswiftDemangle(outputDir);
  wrap = parseWrapWrapper(wrapDir / "libswiftdemangle2.wrap");
  outputDir = outputPath / "libswiftdemangle2.wrap";
  res = wrap->serializedWrap->setupDirectory(outputDir, packagefilesPath);
  assert(res);
  checkLibswiftDemangle2(outputDir);
  wrap = parseWrapWrapper(wrapDir / "rustc-demangle.wrap");
  outputDir = outputPath / "rustc-demangle.wrap";
  res = wrap->serializedWrap->setupDirectory(outputDir, packagefilesPath);
  assert(res);
  wrap = parseWrapWrapper(wrapDir / "miniz.wrap");
  outputDir = outputPath / "miniz.wrap";
  res = wrap->serializedWrap->setupDirectory(outputDir, packagefilesPath);
  assert(res);
  checkMiniz(outputDir);
  wrap = parseWrapWrapper(wrapDir / "turtle.wrap");
  outputDir = outputPath / "turtle.wrap";
  res = wrap->serializedWrap->setupDirectory(outputDir, packagefilesPath);
  assert(res);
  checkTurtle(outputDir);
  wrap = parseWrapWrapper(wrapDir / "sqlite.wrap");
  outputDir = outputPath / "sqlite.wrap";
  res = wrap->serializedWrap->setupDirectory(outputDir, packagefilesPath);
  assert(res);
  checkSqlite(outputDir);
  wrap = parseWrapWrapper(wrapDir / "pango.wrap");
  outputDir = outputPath / "pango.wrap";
  res = wrap->serializedWrap->setupDirectory(outputDir, packagefilesPath);
  assert(res);
  checkPango(outputDir);
  wrap = parseWrapWrapper(wrapDir / "turtle2.wrap");
  outputDir = outputPath / "turtle2.wrap";
  res = wrap->serializedWrap->setupDirectory(outputDir, packagefilesPath);
  assert(res);
  checkTurtle2(outputDir);
  wrap = parseWrapWrapper(wrapDir / "turtle3.wrap");
  outputDir = outputPath / "turtle3.wrap";
  res = wrap->serializedWrap->setupDirectory(outputDir, packagefilesPath);
  assert(res);
  checkTurtle3(outputDir);
  wrap = parseWrapWrapper(wrapDir / "pidgin.wrap");
  outputDir = outputPath / "pidgin.wrap";
  res = wrap->serializedWrap->setupDirectory(outputDir, packagefilesPath);
  if (res) {
    checkPidgin(outputDir);
  }
  wrap = parseWrapWrapper(wrapDir / "vorbis.wrap");
  outputDir = outputPath / "vorbis.wrap";
  res = wrap->serializedWrap->setupDirectory(outputDir, packagefilesPath);
  if (res) {
    checkVorbis(outputDir);
  }
  wrap = parseWrapWrapper(wrapDir / "rubberband.wrap");
  outputDir = outputPath / "rubberband.wrap";
  res = wrap->serializedWrap->setupDirectory(outputDir, packagefilesPath);
  assert(res);
  checkRubberband(outputDir);
}
