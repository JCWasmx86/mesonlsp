import MesonAST

public class MesonSourceRootCheck: MesonChecker {
  public func check(node: Node, metadata: MesonMetadata) {
    metadata.registerDiagnostic(
      node: node,
      diag: MesonDiagnostic(
        sev: .warning, node: node,
        message:
          "Deprecated. Try one of: `meson.current_source_dir`, `meson.project_source_root` or `meson.global_source_root`"
      ))
  }
}
