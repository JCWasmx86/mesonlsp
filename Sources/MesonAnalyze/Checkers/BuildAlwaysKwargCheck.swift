import MesonAST

public class BuildAlwaysKwargCheck: MesonChecker {
  public func check(node: Node, metadata: MesonMetadata) {
    if let args = (node as! FunctionExpression).argumentList as? ArgumentList {
      for a in args.args {
        if let kwi = a as? KeywordItem {
          if (kwi.key as! IdExpression).id == "build_always" {
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
  }
}
