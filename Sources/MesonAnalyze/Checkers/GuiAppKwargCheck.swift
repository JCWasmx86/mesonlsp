import MesonAST

public class GuiAppKwargCheck: MesonChecker {
  public func check(node: Node, metadata: MesonMetadata) {
    if let fe = node as? FunctionExpression, let args = fe.argumentList as? ArgumentList {
      for a in args.args
      where a is KeywordItem && ((a as! KeywordItem).key as! IdExpression).id == "gui_app" {
        metadata.registerDiagnostic(
          node: node,
          diag: MesonDiagnostic(
            sev: .warning,
            node: node,
            message: "Deprecated. Use `win_subsystem` instead"
          )
        )
        break
      }
    }
  }
}
