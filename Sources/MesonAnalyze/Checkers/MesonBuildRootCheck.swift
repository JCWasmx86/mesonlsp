import MesonAST

public class MesonBuildRootCheck: MesonChecker {
  public func check(node: Node, metadata: MesonMetadata) {
    metadata.registerDiagnostic(
      node: node,
      diag: MesonDiagnostic(
        sev: .warning, node: node,
        message:
          "Deprecated. Try one of: `meson.current_build_dir`, `meson.project_build_root` or `meson.global_build_root`"
      ))
  }
}
