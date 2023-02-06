import MesonAST

public class BuildAlwaysKwargCheck: MesonChecker {
  public func check(node: Node, metadata: MesonMetadata) {
    if let fe = node as? FunctionExpression, let args = fe.argumentList as? ArgumentList {
      for a in args.args
      where a is KeywordItem && ((a as! KeywordItem).key as! IdExpression).id == "build_always" {
        metadata.registerDiagnostic(
          node: node,
          diag: MesonDiagnostic(
            sev: .warning,
            node: node,
            message: "Deprecated. Use `build_always_stale` and `build_by_default` instead"
          )
        )
        break
      }
    }
  }
}
