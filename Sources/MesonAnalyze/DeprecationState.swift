public class DeprecationState {
  public static let map = [
    "meson.build_root": DeprecationData(
      since: "0.56.0",
      alternatives: [
        "meson.current_build_dir", "meson.project_build_root", "meson.global_build_root",
      ]
    ),
    "meson.get_cross_property": DeprecationData(
      since: "0.58.0",
      alternatives: ["meson.get_external_property"]
    ),
    "meson.has_exe_wrapper": DeprecationData(
      since: "0.55.0",
      alternatives: ["meson.can_run_host_binaries"]
    ),
    "meson.source_root": DeprecationData(
      since: "0.56.0",
      alternatives: [
        "meson.current_source_dir", "meson.project_source_root", "meson.global_source_root",
      ]
    ), "<gui_app>": DeprecationData(since: "0.56.0", alternatives: ["win_subsystem"]),
    "<build_always>": DeprecationData(
      since: "0.47.0",
      alternatives: ["build_always_stale", "build_by_default"]
    ), "build_tgt.path": DeprecationData(since: "0.59.0", alternatives: ["build_tgt.full_path"]),
    "dep.get_configtool_variable": DeprecationData(
      since: "0.56.0",
      alternatives: ["dep.get_variable"]
    ),
    "dep.get_pkgconfig_variable": DeprecationData(
      since: "0.56.0",
      alternatives: ["dep.get_variable"]
    ),
    "external_program.path": DeprecationData(
      since: "0.55.0",
      alternatives: ["external_program.full_path"]
    ),
  ]

  public static func check(name: String, version: Version) -> [String]? {
    guard let data = Self.map[name] else { return nil }
    let deprecated_since = data.since
    if deprecated_since.before(version) { return data.alternatives }
    return nil
  }
}

public class DeprecationData {
  public let since: Version
  public let alternatives: [String]

  public init(since: String, alternatives: [String]) {
    self.since = Version.parseVersion(s: since)
    self.alternatives = alternatives
  }
}
