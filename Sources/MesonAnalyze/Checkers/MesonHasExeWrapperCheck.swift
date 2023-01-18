import MesonAST

public class MesonHasExeWrapperCheck: MesonChecker {
  public func check(node: Node, metadata: MesonMetadata) {
    metadata.registerDiagnostic(
      node: node,
      diag: MesonDiagnostic(
        sev: .warning, node: node, message: "Deprecated. Replaced by `meson.can_run_host_binaries`")
    )
  }
}
