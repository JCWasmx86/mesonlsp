#pragma once

#include "polyfill.hpp"
#include "utils.hpp"

#include <algorithm>
#include <cstdint>
#include <memory>
#include <optional>
#include <string>
#include <utility>
#include <vector>

#define MAKE_TYPE_WITH_PARENT(className, internalId, parentClass, tag)         \
  class className : public AbstractObject {                                    \
  public:                                                                      \
    className()                                                                \
        : AbstractObject(internalId, TypeName::tag,                            \
                         std::make_shared<parentClass>()) {}                   \
  }; // NOLINT

#define MAKE_TYPE(className, internalId, tag)                                  \
  class className : public AbstractObject {                                    \
  public:                                                                      \
    className() : AbstractObject(internalId, TypeName::tag) {}                 \
  }; // NOLINT

#define MAKE_BASIC_TYPE(className, internalId, tag)                            \
  class className : public Type {                                              \
  public:                                                                      \
    className() : Type(internalId, TypeName::tag) {}                           \
  }; // NOLINT

enum class TypeName : uint32_t {
  DICT,
  LIST,
  SUBPROJECT,
  ANY,
  BOOL,
  INT,
  STR,
  MESON,
  BUILD_MACHINE,
  HOST_MACHINE,
  TARGET_MACHINE,
  TGT,
  ALIAS_TGT,
  BUILD_TGT,
  CUSTOM_TGT,
  EXE,
  JAR,
  LIB,
  BOTH_LIBS,
  RUN_TGT,
  CFG_DATA,
  COMPILER,
  CUSTOM_IDX,
  DEP,
  DISABLER,
  ENV,
  EXTERNAL_PROGRAM,
  EXTRACTED_OBJ,
  FEATURE,
  FFILE,
  GENERATED_LIST,
  GENERATOR,
  INC,
  MODULE,
  RANGE,
  RUN_RESULT,
  STRUCTURED_SRC,
  CMAKE_MODULE,
  CMAKE_SUBPROJECT,
  CMAKE_TGT,
  CMAKE_SUBPROJECT_OPTIONS,
  CUDA_MODULE,
  DLANG_MODULE,
  EXTERNAL_PROJECT_MODULE,
  EXTERNAL_PROJECT,
  FS_MODULE,
  GNOME_MODULE,
  HOTDOC_MODULE,
  HOTDOC_TARGET,
  I18N_MODULE,
  ICESTORM_MODULE,
  JAVA_MODULE,
  KEYVAL_MODULE,
  PKGCONFIG_MODULE,
  PYTHON_MODULE,
  PYTHON_INSTALLATION,
  PYTHON3_MODULE,
  QT4_MODULE,
  QT5_MODULE,
  QT6_MODULE,
  RUST_MODULE,
  SIMD_MODULE,
  SOURCE_SET_MODULE,
  SOURCE_SET,
  SOURCE_CONFIGURATION,
  WAYLAND_MODULE,
  WINDOWS_MODULE,
};

class Type {
public:
  const TypeName tag;
  bool simple = true;
  bool complexObject = false;
  const std::string name;

  virtual const std::string &toString() { return this->name; }

  virtual ~Type() = default;

  Type(Type const &) = delete;
  void operator=(Type const &) = delete;
  Type(Type &&) = delete;

protected:
  explicit Type(std::string name, TypeName tag)
      : tag(tag), name(std::move(name)) {}
};

class AbstractObject : public Type {
public:
  std::optional<std::shared_ptr<AbstractObject>> parent;

protected:
  explicit AbstractObject(
      std::string name, TypeName tag,
      std::optional<std::shared_ptr<AbstractObject>> parent = std::nullopt)
      : Type(std::move(name), tag), parent(std::move(parent)) {
    this->complexObject = true;
  }
};

class Dict : public Type {
public:
  std::vector<std::shared_ptr<Type>> types;

  explicit Dict(const std::vector<std::shared_ptr<Type>> &types)
      : Type("dict", TypeName::DICT), types(types) {
    const auto len = types.size();
    this->simple = false;
    if (len == 0) {
      this->cached = true;
      this->cache = "dict()";
    } else if (len == 1) [[likely]] {
      this->cached = true;
      this->cache = std::format("dict({})", types[0]->toString());
    }
  }

  Dict() : Type("dict", TypeName::DICT), cache("dict()"), cached(true) {
    this->simple = false;
  }

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
      : Type("list", TypeName::LIST), types(types) {
    const auto len = types.size();
    this->simple = false;
    if (len == 0) {
      this->cached = true;
      this->cache = "list()";
    } else if (len == 1) [[likely]] {
      this->cached = true;
      this->cache = std::format("list({})", types[0]->toString());
    }
  }

  List() : Type("list", TypeName::LIST), cache("list()"), cached(true) {
    this->simple = false;
  }

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
    this->cache = std::format("list({})", joinStrings(names, '|'));
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
      : AbstractObject("subproject", TypeName::SUBPROJECT),
        names(std::move(names)) {
    std::ranges::sort(this->names);
    this->simple = false;
    this->cache = "subproject(" + joinStrings(this->names, '|') + ")";
  }

  const std::string &toString() override { return this->cache; }

private:
  std::string cache;
};

// Builtin stuff
MAKE_BASIC_TYPE(Any, "any", ANY)
MAKE_BASIC_TYPE(BoolType, "bool", BOOL)
MAKE_BASIC_TYPE(IntType, "int", INT)
MAKE_BASIC_TYPE(Str, "str", STR)
MAKE_TYPE(Meson, "meson", MESON)
MAKE_TYPE(BuildMachine, "build_machine", BUILD_MACHINE)
MAKE_TYPE_WITH_PARENT(HostMachine, "host_machine", BuildMachine, HOST_MACHINE)
MAKE_TYPE_WITH_PARENT(TargetMachine, "target_machine", BuildMachine,
                      TARGET_MACHINE)
MAKE_TYPE(Tgt, "tgt", TGT)
MAKE_TYPE_WITH_PARENT(AliasTgt, "alias_tgt", Tgt, ALIAS_TGT)
MAKE_TYPE_WITH_PARENT(BuildTgt, "build_tgt", Tgt, BUILD_TGT)
MAKE_TYPE_WITH_PARENT(CustomTgt, "custom_tgt", Tgt, CUSTOM_TGT)
MAKE_TYPE_WITH_PARENT(Exe, "exe", BuildTgt, EXE)
MAKE_TYPE_WITH_PARENT(Jar, "jar", BuildTgt, JAR)
MAKE_TYPE_WITH_PARENT(Lib, "lib", BuildTgt, LIB)
MAKE_TYPE_WITH_PARENT(BothLibs, "both_libs", Lib, BOTH_LIBS)
MAKE_TYPE_WITH_PARENT(RunTgt, "run_tgt", Tgt, RUN_TGT)
MAKE_TYPE(CfgData, "cfg_data", CFG_DATA)
MAKE_TYPE(Compiler, "compiler", COMPILER)
MAKE_TYPE(CustomIdx, "custom_idx", CUSTOM_IDX)
MAKE_TYPE(Dep, "dep", DEP)
MAKE_TYPE(Disabler, "disabler", DISABLER)
MAKE_TYPE(Env, "env", ENV)
MAKE_TYPE(ExternalProgram, "external_program", EXTERNAL_PROGRAM)
MAKE_TYPE(ExtractedObj, "extracted_obj", EXTRACTED_OBJ)
MAKE_TYPE(Feature, "feature", FEATURE)
MAKE_TYPE(File, "file", FFILE)
MAKE_TYPE(GeneratedList, "generated_list", GENERATED_LIST)
MAKE_TYPE(Generator, "generator", GENERATOR)
MAKE_TYPE(Inc, "inc", INC)
MAKE_TYPE(Module, "module", MODULE)
MAKE_TYPE(Range, "range", RANGE)
MAKE_TYPE(RunResult, "runresult", RUN_RESULT)
MAKE_TYPE(StructuredSrc, "structured_src", STRUCTURED_SRC)
// CMake Module
MAKE_TYPE_WITH_PARENT(CMakeModule, "cmake_module", Module, MODULE)
MAKE_TYPE(CMakeSubproject, "cmake_subproject", CMAKE_SUBPROJECT)
MAKE_TYPE(CMakeTarget, "cmake_tgt", CMAKE_TGT)
MAKE_TYPE(CMakeSubprojectOptions, "cmake_subprojectoptions",
          CMAKE_SUBPROJECT_OPTIONS)
// CUDA Module
MAKE_TYPE_WITH_PARENT(CudaModule, "cuda_module", Module, CUDA_MODULE)
// Dlang Module
MAKE_TYPE_WITH_PARENT(DlangModule, "dlang_module", Module, DLANG_MODULE)
// External Project Module
MAKE_TYPE_WITH_PARENT(ExternalProjectModule, "external_project_module", Module,
                      EXTERNAL_PROJECT_MODULE)
MAKE_TYPE(ExternalProject, "external_project", EXTERNAL_PROJECT)
// FS module
MAKE_TYPE_WITH_PARENT(FSModule, "fs_module", Module, FS_MODULE)
// GNOME Module
MAKE_TYPE_WITH_PARENT(GNOMEModule, "gnome_module", Module, GNOME_MODULE)
// Hotdoc Module
MAKE_TYPE_WITH_PARENT(HotdocModule, "hotdoc_module", Module, HOTDOC_MODULE)
MAKE_TYPE_WITH_PARENT(HotdocTarget, "hotdoc_target", CustomTgt, HOTDOC_TARGET)
// I18n Module
MAKE_TYPE_WITH_PARENT(I18nModule, "i18n_module", Module, I18N_MODULE)
// Icestorm Module
MAKE_TYPE_WITH_PARENT(IcestormModule, "icestorm_module", Module,
                      ICESTORM_MODULE)
// Java Module
MAKE_TYPE_WITH_PARENT(JavaModule, "java_module", Module, JAVA_MODULE)
// Keyval Module
MAKE_TYPE_WITH_PARENT(KeyvalModule, "keyval_module", Module, KEYVAL_MODULE)
// Pkgconfig Module
MAKE_TYPE_WITH_PARENT(PkgconfigModule, "pkgconfig_module", Module,
                      PKGCONFIG_MODULE)
// Python Module
MAKE_TYPE_WITH_PARENT(PythonModule, "python_module", Module, PYTHON_MODULE)
MAKE_TYPE_WITH_PARENT(PythonInstallation, "python_installation",
                      ExternalProgram, PYTHON_INSTALLATION)
// Python3 Module
MAKE_TYPE_WITH_PARENT(Python3Module, "python3_module", Module, PYTHON3_MODULE)
// Qt* Modules
MAKE_TYPE_WITH_PARENT(Qt4Module, "qt4_module", Module, QT4_MODULE)
MAKE_TYPE_WITH_PARENT(Qt5Module, "qt5_module", Module, QT5_MODULE)
MAKE_TYPE_WITH_PARENT(Qt6Module, "qt6_module", Module, QT6_MODULE)
// Rust Module
MAKE_TYPE_WITH_PARENT(RustModule, "rust_module", Module, RUST_MODULE)
// SIMD Module
MAKE_TYPE_WITH_PARENT(SIMDModule, "simd_module", Module, SIMD_MODULE)
// SourceSet Module
MAKE_TYPE_WITH_PARENT(SourceSetModule, "sourceset_module", Module,
                      SOURCE_SET_MODULE)
MAKE_TYPE(SourceSet, "sourceset", SOURCE_SET)
MAKE_TYPE(SourceConfiguration, "source_configuration", SOURCE_CONFIGURATION)
// Wayland Module
MAKE_TYPE_WITH_PARENT(WaylandModule, "wayland_module", Module, WAYLAND_MODULE)
// Windows Module
MAKE_TYPE_WITH_PARENT(WindowsModule, "windows_module", Module, WINDOWS_MODULE)
