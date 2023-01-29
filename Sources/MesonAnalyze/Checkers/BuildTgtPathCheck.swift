import MesonAST

public class BuildTgtPathCheck: MesonChecker {
  public func check(node: Node, metadata: MesonMetadata) {
    metadata.registerDiagnostic(
      node: node,
      diag: MesonDiagnostic(
        sev: .warning,
        node: node,
        message: "Deprecated. Use `build_tgt.full_path` instead"
      )
    )
  }
}
