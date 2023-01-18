import MesonAST

public class DepGetPkgConfigToolVariableCheck: MesonChecker {
  public func check(node: Node, metadata: MesonMetadata) {
    metadata.registerDiagnostic(
      node: node,
      diag: MesonDiagnostic(
        sev: .warning, node: node, message: "Deprecated. Use `dep.get_variable` instead."))
  }
}
