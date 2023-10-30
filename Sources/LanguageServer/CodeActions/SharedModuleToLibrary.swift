import LanguageServerProtocol
import MesonAnalyze
import MesonAST

class SharedModuleToLibraryCodeActionProvider: CodeActionProvider {
  func findCodeActionsForNode(uri: DocumentURI, node: Node, tree: MesonTree) -> [CodeAction] {
    guard let fexpr = node as? FunctionExpression else { return [] }
    guard let function = fexpr.function else { return [] }
    if function.id() != "shared_module" { return [] }
    let range = Shared.nodeToRange(fexpr.id)
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
}
