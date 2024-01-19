#pragma once

#include "utils.hpp"

#include <algorithm>
#include <cstddef>
#include <memory>
#include <optional>
#include <string>
#include <utility>
#include <vector>

#define MAKE_TYPE_WITH_PARENT(className, internalId, parentClass)              \
  class className : public AbstractObject {                                    \
  public:                                                                      \
    className()                                                                \
        : AbstractObject(internalId, std::make_shared<parentClass>()) {}       \
  }; // NOLINT(misc-macro-parentheses);

#define MAKE_TYPE(className, internalId)                                       \
  class className : public AbstractObject {                                    \
  public:                                                                      \
    className() : AbstractObject(internalId) {}                                \
  }; // NOLINT(misc-macro-parentheses);

#define MAKE_BASIC_TYPE(className, internalId)                                 \
  class className : public Type {                                              \
  public:                                                                      \
    className() : Type(internalId) {}                                          \
  }; // NOLINT(misc-macro-parentheses);

class Type {
public:
  const std::string name;
  std::string docs;

  virtual const std::string &toString() { return this->name; }

  virtual ~Type() = default;

  Type(Type const &) = delete;
  void operator=(Type const &) = delete;
  Type(Type &&) = delete;

protected:
  explicit Type(std::string name) : name(std::move(name)) {}
};

class AbstractObject : public Type {
public:
  std::optional<std::shared_ptr<AbstractObject>> parent;

protected:
  explicit AbstractObject(
      std::string name,
      std::optional<std::shared_ptr<AbstractObject>> parent = std::nullopt)
      : Type(std::move(name)), parent(std::move(parent)) {}
};

class Dict : public Type {
public:
  std::vector<std::shared_ptr<Type>> types;

  explicit Dict(const std::vector<std::shared_ptr<Type>> &types)
      : Type("dict"), types(types) {}

  Dict() : Type("dict") {}

  const std::string &toString() override {
    if (this->cached) {
      return this->cache;
    }
    std::vector<std::string> names;
    names.reserve(types.size());
    for (const auto &element : types) {
      names.push_back(element->toString());
    }

    std::ranges::sort(names);
    this->cache = "dict(" + joinStrings(names, '|') + ")";
    this->cached = true;
    return this->cache;
  }

private:
  std::string cache;
  bool cached{false};
};

class List : public Type {
public:
  std::vector<std::shared_ptr<Type>> types;

  explicit List(const std::vector<std::shared_ptr<Type>> &types)
      : Type("list"), types(types) {}

  List() : Type("list") {}

  const std::string &toString() override {
    if (this->cached) {
      return this->cache;
    }
    std::vector<std::string> names;
    names.reserve(types.size());
    for (const auto &element : types) {
      names.push_back(element->toString());
    }

    std::ranges::sort(names);
    this->cache = "list(" + joinStrings(names, '|') + ")";
    this->cached = true;
    return this->cache;
  }

private:
  std::string cache;
  bool cached{false};
};

class Subproject : public AbstractObject {
public:
  std::vector<std::string> names;

  explicit Subproject(std::vector<std::string> names)
      : AbstractObject("subproject"), names(std::move(names)) {
    std::ranges::sort(this->names);
    std::string cached;
    for (size_t i = 0; i < this->names.size(); i++) {
      cached += this->names[i];
      if (i != this->names.size() - 1) {
        cached += "|";
      }
    }
    this->cache = "subproject(" + cached + ")";
  }

  const std::string &toString() override { return this->cache; }

private:
  std::string cache;
};

// Builtin stuff
MAKE_BASIC_TYPE(Any, "any")
MAKE_BASIC_TYPE(BoolType, "bool")
MAKE_BASIC_TYPE(IntType, "int")
MAKE_BASIC_TYPE(Str, "str")
MAKE_TYPE(Meson, "meson")
MAKE_TYPE(BuildMachine, "build_machine")
MAKE_TYPE_WITH_PARENT(HostMachine, "host_machine", BuildMachine)
MAKE_TYPE_WITH_PARENT(TargetMachine, "target_machine", BuildMachine)
MAKE_TYPE(Tgt, "tgt")
MAKE_TYPE_WITH_PARENT(AliasTgt, "alias_tgt", Tgt)
MAKE_TYPE_WITH_PARENT(BuildTgt, "build_tgt", Tgt)
MAKE_TYPE_WITH_PARENT(CustomTgt, "custom_tgt", Tgt)
MAKE_TYPE_WITH_PARENT(Exe, "exe", BuildTgt)
MAKE_TYPE_WITH_PARENT(Jar, "jar", BuildTgt)
MAKE_TYPE_WITH_PARENT(Lib, "lib", BuildTgt)
MAKE_TYPE_WITH_PARENT(BothLibs, "both_libs", Lib)
MAKE_TYPE_WITH_PARENT(RunTgt, "run_tgt", Tgt)
MAKE_TYPE(CfgData, "cfg_data")
MAKE_TYPE(Compiler, "compiler")
MAKE_TYPE(CustomIdx, "custom_idx")
MAKE_TYPE(Dep, "dep")
MAKE_TYPE(Disabler, "disabler")
MAKE_TYPE(Env, "env")
MAKE_TYPE(ExternalProgram, "external_program")
MAKE_TYPE(ExtractedObj, "extracted_obj")
MAKE_TYPE(Feature, "feature")
MAKE_TYPE(File, "file")
MAKE_TYPE(GeneratedList, "generated_list")
MAKE_TYPE(Generator, "generator")
MAKE_TYPE(Inc, "inc")
MAKE_TYPE(Module, "module")
MAKE_TYPE(Range, "range")
MAKE_TYPE(RunResult, "runresult")
MAKE_TYPE(StructuredSrc, "structured_src")
// CMake Module
MAKE_TYPE_WITH_PARENT(CMakeModule, "cmake_module", Module)
MAKE_TYPE(CMakeSubproject, "cmake_subproject")
MAKE_TYPE(CMakeTarget, "cmake_tgt")
MAKE_TYPE(CMakeSubprojectOptions, "cmake_subprojectoptions")
// CUDA Module
MAKE_TYPE_WITH_PARENT(CudaModule, "cuda_module", Module)
// Dlang Module
MAKE_TYPE_WITH_PARENT(DlangModule, "dlang_module", Module)
// External Project Module
MAKE_TYPE_WITH_PARENT(ExternalProjectModule, "external_project_module", Module)
MAKE_TYPE(ExternalProject, "external_project")
// FS module
MAKE_TYPE_WITH_PARENT(FSModule, "fs_module", Module)
// GNOME Module
MAKE_TYPE_WITH_PARENT(GNOMEModule, "gnome_module", Module)
// Hotdoc Module
MAKE_TYPE_WITH_PARENT(HotdocModule, "hotdoc_module", Module)
MAKE_TYPE_WITH_PARENT(HotdocTarget, "hotdoc_target", CustomTgt)
// I18n Module
MAKE_TYPE_WITH_PARENT(I18nModule, "i18n_module", Module)
// Icestorm Module
MAKE_TYPE_WITH_PARENT(IcestormModule, "icestorm_module", Module)
// Java Module
MAKE_TYPE_WITH_PARENT(JavaModule, "java_module", Module)
// Keyval Module
MAKE_TYPE_WITH_PARENT(KeyvalModule, "keyval_module", Module)
// Pkgconfig Module
MAKE_TYPE_WITH_PARENT(PkgconfigModule, "pkgconfig_module", Module)
// Python Module
MAKE_TYPE_WITH_PARENT(PythonModule, "python_module", Module)
MAKE_TYPE_WITH_PARENT(PythonInstallation, "python_installation",
                      ExternalProgram)
// Python3 Module
MAKE_TYPE_WITH_PARENT(Python3Module, "python3_module", Module)
// Qt* Modules
MAKE_TYPE_WITH_PARENT(Qt4Module, "qt4_module", Module)
MAKE_TYPE_WITH_PARENT(Qt5Module, "qt5_module", Module)
MAKE_TYPE_WITH_PARENT(Qt6Module, "qt6_module", Module)
// Rust Module
MAKE_TYPE_WITH_PARENT(RustModule, "rust_module", Module)
// SIMD Module
MAKE_TYPE_WITH_PARENT(SIMDModule, "simd_module", Module)
// SourceSet Module
MAKE_TYPE_WITH_PARENT(SourceSetModule, "sourceset_module", Module)
MAKE_TYPE(SourceSet, "sourceset")
MAKE_TYPE(SourceConfiguration, "source_configuration")
// Wayland Module
MAKE_TYPE_WITH_PARENT(WaylandModule, "wayland_module", Module)
// Windows Module
MAKE_TYPE_WITH_PARENT(WindowsModule, "windows_module", Module)
