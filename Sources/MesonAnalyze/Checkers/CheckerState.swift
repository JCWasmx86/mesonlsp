import MesonAST

public class CheckerState {
  let state: [String: MesonChecker]
  public init() {
    self.state = [
      "custom_target": BuildAlwaysKwargCheck(), "build_tgt.path": BuildTgtPathCheck(),
      "dep.get_configtool_variable": DepGetConfigToolVariableCheck(),
      "dep.get_pkgconfig_variable": DepGetPkgConfigToolVariableCheck(),
      "external_program.path": ExternalProgramPathCheck(), "install_subdir": InstallSubdirCheck(),
      "meson.build_root": MesonBuildRootCheck(),
      "meson.get_cross_property": MesonGetCrossPropertyCheck(),
      "meson.has_exe_wrapper": MesonHasExeWrapperCheck(),
      "meson.source_root": MesonSourceRootCheck(), "build_target": GuiAppKwargCheck(),
      "executable": GuiAppKwargCheck(), "jar": GuiAppKwargCheck(), "library": GuiAppKwargCheck(),
      "shared_library": GuiAppKwargCheck(), "shared_module": GuiAppKwargCheck(),
      "static_library": GuiAppKwargCheck(), "both_libraries": GuiAppKwargCheck(),
    ]
  }
  public func apply(node: Node, metadata: MesonMetadata, f: Function) {
    if let c = self.state[f.id()] { c.check(node: node, metadata: metadata) }
  }
}
