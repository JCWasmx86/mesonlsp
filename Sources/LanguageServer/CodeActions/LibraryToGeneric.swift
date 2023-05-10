import LanguageServerProtocol
import MesonAnalyze
import MesonAST

class LibraryToGenericCodeActionProvider: CodeActionProvider {
  func findCodeActionsForNode(uri: DocumentURI, node: Node, tree: MesonTree) -> [CodeAction] {
    if let fexpr = node as? FunctionExpression, let f = fexpr.function,
      f.id() == "static_library" || f.id() == "shared_library" || f.id() == "both_libraries"
    {
      let range = Shared.nodeToRange(fexpr.id)
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
