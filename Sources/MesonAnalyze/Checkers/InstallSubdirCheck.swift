import MesonAST

public class InstallSubdirCheck: MesonChecker {
  public func check(node: Node, metadata: MesonMetadata) {
    metadata.registerDiagnostic(
      node: node,
      diag: MesonDiagnostic(
        sev: .warning,
        node: node,
        message: "Deprecated. Use `install_emptydir` instead"
      )
    )
  }
}
