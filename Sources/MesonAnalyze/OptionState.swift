public class OptionState {
  public var opts: [String: MesonOption] = [:]
  init(options: [MesonOption]) {
    self.append(option: StringOption("prefix", nil))
    self.append(option: StringOption("bindir", nil))
    self.append(option: StringOption("datadir", nil))
    self.append(option: StringOption("includedir", nil))
    self.append(option: StringOption("infodir", nil))
    self.append(option: StringOption("libdir", nil))
    self.append(option: StringOption("licensedir", nil))
    self.append(option: StringOption("libexecdir", nil))
    self.append(option: StringOption("localedir", nil))
    self.append(option: StringOption("localstatedir", nil))
    self.append(option: StringOption("mandir", nil))
    self.append(option: StringOption("sbindir", nil))
    self.append(option: StringOption("sharedstatedir", nil))
    self.append(option: StringOption("sysconfdir", nil))
    self.append(option: FeatureOption("auto_features", nil))
    self.append(option: ComboOption("backend", nil))
    self.append(option: ComboOption("buildtype", nil))
    self.append(option: BoolOption("debug", nil))
    self.append(option: ComboOption("default_library", nil))
    self.append(option: BoolOption("errorlogs", nil))
    self.append(option: IntOption("install_umask", nil))
    self.append(option: ComboOption("layout", nil))
    self.append(option: ComboOption("optimization", nil))
    self.append(option: ArrayOption("pkg_config_path", nil))
    self.append(option: BoolOption("prefer_static", nil))
    self.append(option: ArrayOption("cmake_prefix_path", nil))
    self.append(option: BoolOption("stdsplit", nil))
    self.append(option: BoolOption("strip", nil))
    self.append(option: ComboOption("unity", nil))
    self.append(option: IntOption("unity_size", nil))
    self.append(option: ComboOption("warning_level", nil))
    self.append(option: BoolOption("werror", nil))
    self.append(option: ComboOption("wrap_mode", nil))
    self.append(option: ArrayOption("force_fallback_for", nil))
    // TODO: Some are still missing
    for o in options { self.append(option: o) }
  }

  func append(option: MesonOption) { self.opts[option.name] = option }
}
