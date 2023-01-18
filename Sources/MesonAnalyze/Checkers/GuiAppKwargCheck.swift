import MesonAST

public class GuiAppKwargCheck: MesonChecker {
  public func check(node: Node, metadata: MesonMetadata) {
    if let args = (node as! FunctionExpression).argumentList as? ArgumentList {
      for a in args.args {
        if let kwi = a as? KeywordItem {
          if (kwi.key as! IdExpression).id == "gui_app" {
            metadata.registerDiagnostic(
              node: node,
              diag: MesonDiagnostic(
                sev: .warning, node: node, message: "Deprecated. Use `win_subsystem` instead"))
            break
          }
        }
      }
    }
  }
}
