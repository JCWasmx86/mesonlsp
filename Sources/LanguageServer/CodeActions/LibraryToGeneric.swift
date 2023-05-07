import LanguageServerProtocol
import Logging
import MesonAST

class LibraryToGenericCodeActionProvider: CodeActionProvider {
  func findCodeActionsForNode(uri: DocumentURI, node: Node) -> [CodeAction] {
    Logger(label: "LanguageServer::LibraryToGenericCodeActionProvider").info("\(node)")
    if let fexpr = node as? FunctionExpression, let f = fexpr.function,
      f.id() == "static_library" || f.id() == "shared_library" || f.id() == "both_libraries"
    {
      let range =
        Position(
          line: Int(fexpr.id.location.startLine),
          utf16index: Int(fexpr.id.location.startColumn)
        )..<Position(
          line: Int(fexpr.id.location.endLine),
          utf16index: Int(fexpr.id.location.endColumn)
        )
      let changes = [uri: [TextEdit(range: range, newText: "library")]]
      let edit = WorkspaceEdit(changes: changes)
      return [
        CodeAction(
          title: "Use library() instead of \(f.id())()",
          kind: CodeActionKind.refactor,
          edit: edit
        )
      ]
    }
    return []
  }
}
