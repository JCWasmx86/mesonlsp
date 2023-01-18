import MesonAST

public class MesonGetCrossPropertyCheck: MesonChecker {
  public func check(node: Node, metadata: MesonMetadata) {
    metadata.registerDiagnostic(
      node: node,
      diag: MesonDiagnostic(
        sev: .warning, node: node, message: "Deprecated. Replaced by `meson.get_external_property`")
    )
  }
}
