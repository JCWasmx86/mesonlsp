import LanguageServerProtocol
import MesonAnalyze
import MesonAST

class LibraryToGenericCodeActionProvider: CodeActionProvider {
  func findCodeActionsForNode(uri: DocumentURI, node: Node, tree: MesonTree) -> [CodeAction] {
    guard let fexpr = node as? FunctionExpression else { return [] }
    guard let function = fexpr.function else { return [] }
    if function.id() != "static_library" && function.id() != "shared_library"
      && function.id() != "both_libraries"
    {
      return []
    }
    let range = Shared.nodeToRange(fexpr.id)
    let changes = [uri: [TextEdit(range: range, newText: "library")]]
    let edit = WorkspaceEdit(changes: changes)
    return [
      CodeAction(
        title: "Use library() instead of \(function.id())()",
        kind: CodeActionKind.refactor,
        edit: edit
      )
    ]
  }
}
