#include "optionstate.hpp"

#include "mesonoption.hpp"

#include <memory>
#include <string>
#include <vector>

OptionState::OptionState() {
  this->options.push_back(std::make_shared<ComboOption>(
      "wrap_mode",
      std::vector<std::string>{"default", "nofallback", "nodownload",
                               "forcefallback", "nopromote"},
      "Wrap mode to use (Default: `default`)", false));
  this->options.push_back(std::make_shared<ComboOption>(
      "b_vscrt",
      std::vector<std::string>{"none", "md", "mdd", "mt", "mtd",
                               "from_buildtype", "static_from_buildtype"},
      "VS runtime library to use (Default: `from_buildtype`)", false));
  this->options.push_back(std::make_shared<ComboOption>(
      "layout", std::vector<std::string>{"mirror", "flat"},
      "Build directory layout (Default: `mirror`)", false));
  this->options.push_back(std::make_shared<BoolOption>(
      "b_lto", "Use link time optimization (Default: `false`)", false));
  this->options.push_back(std::make_shared<StringOption>(
      "infodir", "Info page directory (Default: `share/info`)", false));
  this->options.push_back(
      std::make_shared<StringOption>("libdir", "Library directory", false));
  this->options.push_back(std::make_shared<StringOption>(
      "sbindir", "System executable directory (Default: `sbin`)", false));
  this->options.push_back(std::make_shared<IntOption>(
      "cpp_thread_count",
      "Number of threads to use with emcc when using threads (Default: `4`)",
      false));
  this->options.push_back(std::make_shared<StringOption>(
      "cuda_ccbindir", "CUDA non-default toolchain directory to use", false));
  this->options.push_back(std::make_shared<BoolOption>(
      "vsenv", "Activate Visual Studio environment (Default: `false`)", false));
  this->options.push_back(std::make_shared<ArrayOption>(
      "pkg_config_path", std::vector<std::string>{},
      "Additional paths for pkg-config to search before builtin paths "
      "(Default: Empty string)",
      false));
  this->options.push_back(std::make_shared<StringOption>(
      "mandir", "Manual page directory (Default: `share/man`)", false));
  this->options.push_back(std::make_shared<StringOption>(
      "localstatedir", "Localstate data directory (Default: `var`)", false));
  this->options.push_back(
      std::make_shared<ArrayOption>("cpp_link_args", std::vector<std::string>{},
                                    "C++ link arguments to use", false));
  this->options.push_back(std::make_shared<StringOption>(
      "c_winlibs", "Standard Windows libs to link against", false));
  this->options.push_back(std::make_shared<ComboOption>(
      "c_std",
      std::vector<std::string>{"none", "c89", "c99", "c11", "c17", "c18", "c2x",
                               "gnu89", "gnu99", "gnu11", "gnu17", "gnu18",
                               "gnu2x", "gnu23"},
      "C language standard to use", false));
  this->options.push_back(std::make_shared<ComboOption>(
      "b_lto_mode", std::vector<std::string>{},
      "Select between lto modes (Default: `default`)", false));
  this->options.push_back(std::make_shared<ComboOption>(
      "backend",
      std::vector<std::string>{"ninja", "vs", "vs2010", "vs2012", "vs2013",
                               "vs2015", "vs2017", "v2022", "xcode", "none"},
      "Backend to use (Default: `ninja`)", false));
  this->options.push_back(std::make_shared<FeatureOption>(
      "auto_features",
      "Override value of all `auto` features (Default: `auto`)", false));
  this->options.push_back(std::make_shared<BoolOption>(
      "b_pie", "Build position independent executables (Default: `false`)",
      false));
  this->options.push_back(std::make_shared<BoolOption>(
      "b_coverage", "Enable coverage tracking (Default: `false`)", false));
  this->options.push_back(std::make_shared<BoolOption>(
      "prefer_static",
      "Whether to try static linking before shared linking (Default: `false`)",
      false));
  this->options.push_back(std::make_shared<ComboOption>(
      "buildtype",
      std::vector<std::string>{"plain", "debug", "debugoptimized", "release",
                               "minsize", "custom"},
      "Build type to use (Default: `debug`)", false));
  this->options.push_back(std::make_shared<BoolOption>(
      "werror", "Treat warnings as errors (Default: `false`)", false));
  this->options.push_back(std::make_shared<ComboOption>(
      "warning_level",
      std::vector<std::string>{"0", "1", "2", "3", "everything"},
      "Set the warning level. From 0 = none to everything = highest (Default: "
      "`1`)",
      false));
  this->options.push_back(std::make_shared<StringOption>(
      "python.platlibdir",
      "Directory for site-specific, platform-specific files", false));
  this->options.push_back(std::make_shared<StringOption>(
      "prefix", "Installation prefix (`C:\\` or `/usr/local` by default)",
      false));
  this->options.push_back(std::make_shared<StringOption>(
      "bindir", "Executable directory (Default: `bin`)", false));
  this->options.push_back(std::make_shared<IntOption>(
      "c_thread_count",
      "Number of threads to use with emcc when using threads (Default: `4`)",
      false));
  this->options.push_back(std::make_shared<ArrayOption>(
      "cmake_prefix_path", std::vector<std::string>{},
      "Additional prefixes for cmake to search before builtin paths (Default: "
      "Empty array)",
      false));
  this->options.push_back(
      std::make_shared<ArrayOption>("c_link_args", std::vector<std::string>{},
                                    "C link arguments to use", false));
  this->options.push_back(std::make_shared<ComboOption>(
      "fortran_std",
      std::vector<std::string>{"none", "legacy", "f95", "f2003", "f2008",
                               "f2018"},
      "Fortran language standard to use", false));
  this->options.push_back(std::make_shared<StringOption>(
      "python.purelibdir",
      "Directory for site-specific, non-platform-specific files", false));
  this->options.push_back(std::make_shared<IntOption>(
      "b_lto_threads", "Use multiple threads for lto (Default: `0`)", false));
  this->options.push_back(std::make_shared<StringOption>(
      "sysconfdir", "Sysconf data directory (Default: `etc`)", false));
  this->options.push_back(std::make_shared<BoolOption>(
      "stdsplit", "Split stdout and stderr in test logs (Default: `true`)",
      false));
  this->options.push_back(std::make_shared<BoolOption>(
      "errorlogs",
      "Whether to print the logs from failing tests (Default: `true`)", false));
  this->options.push_back(std::make_shared<ComboOption>(
      "optimization",
      std::vector<std::string>{"plain", "0", "g", "1", "2", "3", "s"},
      "Optimization level (Default: `0`)", false));
  this->options.push_back(std::make_shared<BoolOption>(
      "b_pch", "Use precompiled headers (Default: `true`)", false));
  this->options.push_back(std::make_shared<StringOption>(
      "localedir", "Locale data directory (Default: `share/locale`)", false));
  this->options.push_back(
      std::make_shared<BoolOption>("b_thinlto_cache",
                                   "Enable LLVM's ThinLTO cache for faster "
                                   "incremental builds (Default: `false`)",
                                   false));
  this->options.push_back(std::make_shared<ArrayOption>(
      "force_fallback_for", std::vector<std::string>{},
      "Force fallback for those dependencies (Default: Empty array)", false));
  this->options.push_back(std::make_shared<ComboOption>(
      "unity", std::vector<std::string>{"on", "off", "subprojects"},
      "Unity build (Default: `off`)", false));
  this->options.push_back(std::make_shared<ComboOption>(
      "b_colorout", std::vector<std::string>{},
      "Use colored output (Default: `always`)", false));
  this->options.push_back(
      std::make_shared<ArrayOption>("cpp_args", std::vector<std::string>{},
                                    "C++ compile arguments to use", false));
  this->options.push_back(std::make_shared<ComboOption>(
      "b_pgo", std::vector<std::string>{"off", "generate", "use"},
      "Use profile guided optimization (Default: `off`)", false));
  this->options.push_back(std::make_shared<ComboOption>(
      "python.install_env",
      std::vector<std::string>{"auto", "prefix", "system", "venv"},
      "Which python environment to install to (Default: `prefix`)", false));
  this->options.push_back(std::make_shared<BoolOption>(
      "b_staticpic",
      "Build static libraries as position independent (Default: `true`)",
      false));
  this->options.push_back(std::make_shared<BoolOption>(
      "strip", "Strip targets on install (Default: `false`", false));
  this->options.push_back(std::make_shared<ComboOption>(
      "cpp_std",
      std::vector<std::string>{
          "none",    "c++98",   "c++03",   "c++11",     "c++14",   "c++17",
          "c++20",   "c++2a",   "c++1z",   "gnu++03",   "gnu++11", "gnu++14",
          "gnu++17", "gnu++1z", "gnu++2a", "gnu++20",   "gnu++23", "c++26",
          "gnu++26", "vc++14",  "vc++17",  "vc++latest"},
      "C++ language standard to use", false));
  this->options.push_back(std::make_shared<ComboOption>(
      "b_ndebug", std::vector<std::string>{"true", "false", "if-release"},
      "Disabler asserts (Default: `false`)", false));
  this->options.push_back(std::make_shared<BoolOption>(
      "b_asneeded", "Use -Wl,--as-needed when linking (Default: `true`)",
      false));
  this->options.push_back(
      std::make_shared<ArrayOption>("c_args", std::vector<std::string>{},
                                    "C compile arguments to use", false));
  this->options.push_back(std::make_shared<StringOption>(
      "b_thinlto_cache_dir", "Specify where to store ThinLTO cache objects",
      false));
  this->options.push_back(std::make_shared<StringOption>(
      "datadir", "Data file directory (Default: `share`)", false));
  this->options.push_back(std::make_shared<StringOption>(
      "includedir", "Header file directory (Default: `include`)", false));
  this->options.push_back(std::make_shared<BoolOption>(
      "cpp_debugstl", "C++ STL debug mode (Default: `false`)", false));
  this->options.push_back(std::make_shared<BoolOption>(
      "cpp_rtti", "Whether to enable RTTI (Runtime type identification",
      false));
  this->options.push_back(std::make_shared<BoolOption>(
      "b_lundef",
      "Don't allow undefined symbols when linking (Default: `true`)", false));
  this->options.push_back(std::make_shared<BoolOption>(
      "debug", "Enable debug symbols and other information (Default: `true`)",
      false));
  this->options.push_back(
      std::make_shared<ArrayOption>("cuda_args", std::vector<std::string>{},
                                    "Cuda compile arguments to use", false));
  this->options.push_back(std::make_shared<StringOption>(
      "licensedir", "Licenses directory (Empty by default)", false));
  this->options.push_back(std::make_shared<ComboOption>(
      "cpp_eh", std::vector<std::string>{"none", "default", "a", "s", "sc"},
      "C++ exception handling type (Default: `default`)", false));
  this->options.push_back(std::make_shared<ComboOption>(
      "default_library", std::vector<std::string>{"shared", "static", "both"},
      "Default library type (Default: `shared`)", false));
  this->options.push_back(std::make_shared<ComboOption>(
      "default_both_libraries", std::vector<std::string>{"shared", "static", "both"},
      "Default library type for both_libraries (Default: `shared`)", false));
  this->options.push_back(
      std::make_shared<IntOption>("install_umask",
                                  "Default umask to apply on permissions of "
                                  "installed files. (Default: `022`)",
                                  false));
  this->options.push_back(std::make_shared<ComboOption>(
      "b_sanitize",
      std::vector<std::string>{"none", "address", "thread", "undefined",
                               "memory", "leak", "address,undefined"},
      "Code sanitizer to use", false));
  this->options.push_back(std::make_shared<ArrayOption>(
      "objc_args", std::vector<std::string>{},
      "Objective-C compile arguments to use", false));
  this->options.push_back(std::make_shared<IntOption>(
      "unity_size", "Unity file block size (Default: `4`)", false));
  this->options.push_back(std::make_shared<BoolOption>(
      "pkgconfig.relocatable",
      "Generate the pkgconfig files as relocatable (Default: `false`)", false));
  this->options.push_back(std::make_shared<StringOption>(
      "libexecdir", "Library executable directory (Default: `libexec`)",
      false));
  this->options.push_back(std::make_shared<StringOption>(
      "sharedstatedir",
      "Architecture-independent data directory (Default: `com`)", false));
  this->options.push_back(std::make_shared<BoolOption>(
      "b_bitcode", "Embed Apple bitcode (Default: `false`)", false));
  this->options.push_back(std::make_shared<StringOption>(
      "cpp_winlibs", "Standard Windows libs to link against", false));
}
