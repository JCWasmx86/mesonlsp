public class OptionState {
  public var opts: [String: MesonOption] = [:]

  init(options: [MesonOption]) {
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
    self.append(option: ComboOption("backend", "Backend to use (Default: `ninja`)"))
    self.append(option: ComboOption("buildtype", "Build type to use (Default: `debug`)"))
    self.append(
      option: BoolOption("debug", "Enable debug symbols and other information (Default: `true`)")
    )
    self.append(option: ComboOption("default_library", "Default library type (Default: `shared`)"))
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
    self.append(option: ComboOption("layout", "Build directory layout (Default: `mirror`)"))
    self.append(option: ComboOption("optimization", "Optimization level (Default: `0`)"))
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
    self.append(option: ComboOption("unity", "Unity build (Default: `off`)"))
    self.append(option: IntOption("unity_size", "Unity file block size (Default: `4`)"))
    self.append(
      option: ComboOption(
        "warning_level",
        "Set the warning level. From 0 = none to everything = highest (Default: `1`)"
      )
    )
    self.append(option: BoolOption("werror", "Treat warnings as errors (Default: `false`)"))
    self.append(option: ComboOption("wrap_mode", "Wrap mode to use (Default: `default`)"))
    self.append(
      option: ArrayOption(
        "force_fallback_for",
        "Force fallback for those dependencies (Default: Empty array)"
      )
    )
    self.append(
      option: BoolOption("vsenv", "Activate Visual Studio environment (Default: `false`)")
    )
    self.append(option: BoolOption("b_asneeded", nil))
    self.append(option: BoolOption("b_bitcode", nil))
    self.append(option: ComboOption("b_colorout", nil))
    self.append(option: BoolOption("b_coverage", nil))
    self.append(option: BoolOption("b_lundef", nil))
    self.append(option: BoolOption("b_lto", nil))
    self.append(option: IntOption("b_lto_threads", nil))
    self.append(option: ComboOption("b_lto_mode", nil))
    self.append(option: BoolOption("b_thinlto_cache", nil))
    self.append(option: StringOption("b_thinlto_cache_dir", nil))
    self.append(option: ComboOption("b_ndebug", nil))
    self.append(option: BoolOption("b_pch", nil))
    self.append(option: BoolOption("b_pgo", nil))
    self.append(option: ComboOption("b_sanitize", nil))
    self.append(option: BoolOption("b_staticpic", nil))
    self.append(option: BoolOption("b_pie", nil))
    self.append(option: ComboOption("b_vscrt", nil))
    self.append(option: ArrayOption("c_args", nil))
    self.append(option: ArrayOption("c_link_args", nil))
    self.append(option: ComboOption("c_std", nil))
    self.append(option: StringOption("c_winlibs", nil))
    self.append(option: IntOption("c_thread_count", nil))
    self.append(option: ArrayOption("cpp_args", nil))
    self.append(option: ArrayOption("cpp_link_args", nil))
    self.append(option: ComboOption("cpp_std", nil))
    self.append(option: BoolOption("cpp_debugstl", nil))
    self.append(option: ComboOption("cpp_eh", nil))
    self.append(option: BoolOption("cpp_rtti", nil))
    self.append(option: IntOption("cpp_thread_count", nil))
    self.append(option: StringOption("cpp_winlibs", nil))
    self.append(option: ComboOption("fortran_std", nil))
    self.append(option: StringOption("cuda_ccbindir", nil))
    self.append(option: ArrayOption("objc_args", nil))
    self.append(option: ComboOption("python.install_env", nil))
    self.append(option: StringOption("python.platlibdir", nil))
    self.append(option: StringOption("python.purelibdir", nil))
    self.append(option: BoolOption("pkgconfig.relocatable", nil))
    for o in options { self.append(option: o) }
  }

  private func append(option: MesonOption) { self.opts[option.name] = option }
}
