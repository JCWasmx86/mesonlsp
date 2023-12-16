public class OptionState {
  public var opts: [String: MesonOption] = [:]

  public init(options: [MesonOption]) {
    self.append(
      option: StringOption("prefix", "Installation prefix (`C:\\` or `/usr/local` by default)")
    )
    self.append(option: StringOption("bindir", "Executable directory (Default: `bin`)"))
    self.append(option: StringOption("datadir", "Data file directory (Default: `share`)"))
    self.append(option: StringOption("includedir", "Header file directory (Default: `include`)"))
    self.append(option: StringOption("infodir", "Info page directory (Default: `share/info`)"))
    self.append(option: StringOption("libdir", "Library directory"))
    self.append(option: StringOption("licensedir", "Licenses directory (Empty by default)"))
    self.append(
      option: StringOption("libexecdir", "Library executable directory (Default: `libexec`)")
    )
    self.append(
      option: StringOption("localedir", "Locale data directory (Default: `share/locale`)")
    )
    self.append(option: StringOption("localstatedir", "Localstate data directory (Default: `var`)"))
    self.append(option: StringOption("mandir", "Manual page directory (Default: `share/man`)"))
    self.append(option: StringOption("sbindir", "System executable directory (Default: `sbin`)"))
    self.append(
      option: StringOption(
        "sharedstatedir",
        "Architecture-independent data directory (Default: `com`)"
      )
    )
    self.append(option: StringOption("sysconfdir", "Sysconf data directory (Default: `etc`)"))
    self.append(
      option: FeatureOption(
        "auto_features",
        "Override value of all `auto` features (Default: `auto`)"
      )
    )
    self.append(
      option: ComboOption(
        "backend",
        "Backend to use (Default: `ninja`)",
        ["ninja", "vs", "vs2010", "vs2012", "vs2013", "vs2015", "vs2017", "v2022", "xcode", "none"]
      )
    )
    self.append(
      option: ComboOption(
        "buildtype",
        "Build type to use (Default: `debug`)",
        ["plain", "debug", "debugoptimized", "release", "minsize", "custom"]
      )
    )
    self.append(
      option: BoolOption("debug", "Enable debug symbols and other information (Default: `true`)")
    )
    self.append(
      option: ComboOption(
        "default_library",
        "Default library type (Default: `shared`)",
        ["shared", "static", "both"]
      )
    )
    self.append(
      option: BoolOption(
        "errorlogs",
        "Whether to print the logs from failing tests (Default: `true`)"
      )
    )
    self.append(
      option: IntOption(
        "install_umask",
        "Default umask to apply on permissions of installed files. (Default: `022`)"
      )
    )
    self.append(
      option: ComboOption(
        "layout",
        "Build directory layout (Default: `mirror`)",
        ["mirror", "flat"]
      )
    )
    self.append(
      option: ComboOption(
        "optimization",
        "Optimization level (Default: `0`)",
        ["plain", "0", "g", "1", "2", "3", "s"]
      )
    )
    self.append(
      option: ArrayOption(
        "pkg_config_path",
        "Additional paths for pkg-config to search before builtin paths (Default: Empty string)"
      )
    )
    self.append(
      option: BoolOption(
        "prefer_static",
        "Whether to try static linking before shared linking (Default: `false`)"
      )
    )
    self.append(
      option: ArrayOption(
        "cmake_prefix_path",
        "Additional prefixes for cmake to search before builtin paths (Default: Empty array)"
      )
    )
    self.append(
      option: BoolOption("stdsplit", "Split stdout and stderr in test logs (Default: `true`)")
    )
    self.append(option: BoolOption("strip", "Strip targets on install (Default: `false`"))
    self.append(
      option: ComboOption("unity", "Unity build (Default: `off`)", ["on", "off", "subprojects"])
    )
    self.append(option: IntOption("unity_size", "Unity file block size (Default: `4`)"))
    self.append(
      option: ComboOption(
        "warning_level",
        "Set the warning level. From 0 = none to everything = highest (Default: `1`)",
        ["0", "1", "2", "3", "everything"]
      )
    )
    self.append(option: BoolOption("werror", "Treat warnings as errors (Default: `false`)"))
    self.append(
      option: ComboOption(
        "wrap_mode",
        "Wrap mode to use (Default: `default`)",
        ["default", "nofallback", "nodownload", "forcefallback", "nopromote"]
      )
    )
    self.append(
      option: ArrayOption(
        "force_fallback_for",
        "Force fallback for those dependencies (Default: Empty array)"
      )
    )
    self.append(
      option: BoolOption("vsenv", "Activate Visual Studio environment (Default: `false`)")
    )
    self.append(
      option: BoolOption("b_asneeded", "Use -Wl,--as-needed when linking (Default: `true`)")
    )
    self.append(option: BoolOption("b_bitcode", "Embed Apple bitcode (Default: `false`)"))
    self.append(option: ComboOption("b_colorout", "Use colored output (Default: `always`)"))
    self.append(option: BoolOption("b_coverage", "Enable coverage tracking (Default: `false`)"))
    self.append(
      option: BoolOption("b_lundef", "Don't allow undefined symbols when linking (Default: `true`)")
    )
    self.append(option: BoolOption("b_lto", "Use link time optimization (Default: `false`)"))
    self.append(option: IntOption("b_lto_threads", "Use multiple threads for lto (Default: `0`)"))
    self.append(option: ComboOption("b_lto_mode", "Select between lto modes (Default: `default`)"))
    self.append(
      option: BoolOption(
        "b_thinlto_cache",
        "Enable LLVM's ThinLTO cache for faster incremental builds (Default: `false`)"
      )
    )
    self.append(
      option: StringOption("b_thinlto_cache_dir", "Specify where to store ThinLTO cache objects")
    )
    self.append(
      option: ComboOption(
        "b_ndebug",
        "Disabler asserts (Default: `false`)",
        ["true", "false", "if-release"]
      )
    )
    self.append(option: BoolOption("b_pch", "Use precompiled headers (Default: `true`)"))
    self.append(
      option: ComboOption(
        "b_pgo",
        "Use profile guided optimization (Default: `off`)",
        ["off", "generate", "use"]
      )
    )
    self.append(
      option: ComboOption(
        "b_sanitize",
        "Code sanitizer to use",
        ["none", "address", "thread", "undefined", "memory", "leak", "address,undefined"]
      )
    )
    self.append(
      option: BoolOption(
        "b_staticpic",
        "Build static libraries as position independent (Default: `true`)"
      )
    )
    self.append(
      option: BoolOption("b_pie", "Build position independent executables (Default: `false`)")
    )
    self.append(
      option: ComboOption(
        "b_vscrt",
        "VS runtime library to use (Default: `from_buildtype`)",
        ["none", "md", "mdd", "mt", "mtd", "from_buildtype", "static_from_buildtype"]
      )
    )
    self.append(option: ArrayOption("c_args", "C compile arguments to use"))
    self.append(option: ArrayOption("cuda_args", "Cuda compile arguments to use"))
    self.append(option: ArrayOption("c_link_args", "C link arguments to use"))
    self.append(
      option: ComboOption(
        "c_std",
        "C language standard to use",
        [
          "none", "c89", "c99", "c11", "c17", "c18", "c2x", "gnu89", "gnu99", "gnu11", "gnu17",
          "gnu18", "gnu2x",
        ]
      )
    )
    self.append(option: StringOption("c_winlibs", "Standard Windows libs to link against"))
    self.append(
      option: IntOption(
        "c_thread_count",
        "Number of threads to use with emcc when using threads (Default: `4`)"
      )
    )
    self.append(option: ArrayOption("cpp_args", "C++ compile arguments to use"))
    self.append(option: ArrayOption("cpp_link_args", "C++ link arguments to use"))
    self.append(
      option: ComboOption(
        "cpp_std",
        "C++ language standard to use",
        [
          "none", "c++98", "c++03", "c++11", "c++14", "c++17", "c++20", "c++2a", "c++1z", "gnu++03",
          "gnu++11", "gnu++14", "gnu++17", "gnu++1z", "gnu++2a", "gnu++20", "vc++14", "vc++17",
          "vc++latest",
        ]
      )
    )
    self.append(option: BoolOption("cpp_debugstl", "C++ STL debug mode (Default: `false`)"))
    self.append(
      option: ComboOption(
        "cpp_eh",
        "C++ exception handling type (Default: `default`)",
        ["none", "default", "a", "s", "sc"]
      )
    )
    self.append(
      option: BoolOption("cpp_rtti", "Whether to enable RTTI (Runtime type identification")
    )
    self.append(
      option: IntOption(
        "cpp_thread_count",
        "Number of threads to use with emcc when using threads (Default: `4`)"
      )
    )
    self.append(option: StringOption("cpp_winlibs", "Standard Windows libs to link against"))
    self.append(
      option: ComboOption(
        "fortran_std",
        "Fortran language standard to use",
        ["none", "legacy", "f95", "f2003", "f2008", "f2018"]
      )
    )
    self.append(
      option: StringOption("cuda_ccbindir", "CUDA non-default toolchain directory to use")
    )
    self.append(option: ArrayOption("objc_args", "Objective-C compile arguments to use"))
    self.append(
      option: ComboOption(
        "python.install_env",
        "Which python environment to install to (Default: `prefix`)",
        ["auto", "prefix", "system", "venv"]
      )
    )
    self.append(
      option: StringOption(
        "python.platlibdir",
        "Directory for site-specific, platform-specific files"
      )
    )
    self.append(
      option: StringOption(
        "python.purelibdir",
        "Directory for site-specific, non-platform-specific files"
      )
    )
    self.append(
      option: BoolOption(
        "pkgconfig.relocatable",
        "Generate the pkgconfig files as relocatable (Default: `false`)"
      )
    )
    for o in options { self.append(option: o) }
  }

  private func append(option: MesonOption) { self.opts[option.name] = option }
}
