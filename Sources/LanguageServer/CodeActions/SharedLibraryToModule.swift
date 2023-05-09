import LanguageServerProtocol
import MesonAnalyze
import MesonAST

class SharedLibraryToModuleCodeActionProvider: CodeActionProvider {
  func findCodeActionsForNode(uri: DocumentURI, node: Node, tree: MesonTree) -> [CodeAction] {
    if let fexpr = node as? FunctionExpression, let f = fexpr.function,
      let al = fexpr.argumentList as? ArgumentList, f.id() == "shared_library",
      al.getKwarg(name: "darwin_versions") == nil && al.getKwarg(name: "soversion") == nil
        && al.getKwarg(name: "version") == nil
    {
      let range =
        Position(
          line: Int(fexpr.id.location.startLine),
          utf16index: Int(fexpr.id.location.startColumn)
        )..<Position(
          line: Int(fexpr.id.location.endLine),
          utf16index: Int(fexpr.id.location.endColumn)
        )
      let changes = [uri: [TextEdit(range: range, newText: "shared_module")]]
      let edit = WorkspaceEdit(changes: changes)
      return [
        CodeAction(
          title: "Use shared_module() instead of shared_library()",
          kind: CodeActionKind.refactor,
          edit: edit
        )
      ]
    }
    return []
  }
}
