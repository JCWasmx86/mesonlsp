import MesonAST

public class ExternalProgramPathCheck: MesonChecker {
  public func check(node: Node, metadata: MesonMetadata) {
    metadata.registerDiagnostic(
      node: node,
      diag: MesonDiagnostic(
        sev: .warning,
        node: node,
        message: "Deprecated. Use `external_program.full_path` instead"
      )
    )
  }
}
