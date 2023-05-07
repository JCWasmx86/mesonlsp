import LanguageServerProtocol
import MesonAST

class SharedModuleToLibraryCodeActionProvider: CodeActionProvider {
  func findCodeActionsForNode(uri: DocumentURI, node: Node) -> [CodeAction] {
    if let fexpr = node as? FunctionExpression, let f = fexpr.function, f.id() == "shared_module" {
      let range =
        Position(
          line: Int(fexpr.id.location.startLine),
          utf16index: Int(fexpr.id.location.startColumn)
        )..<Position(
          line: Int(fexpr.id.location.endLine),
          utf16index: Int(fexpr.id.location.endColumn)
        )
      let changes = [uri: [TextEdit(range: range, newText: "shared_library")]]
      let edit = WorkspaceEdit(changes: changes)
      return [
        CodeAction(
          title: "Use shared_library() instead of shared_module()",
          kind: CodeActionKind.refactor,
          edit: edit
        )
      ]
    }
    return []
  }
}
