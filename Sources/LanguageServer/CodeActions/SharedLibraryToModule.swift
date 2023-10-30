import LanguageServerProtocol
import MesonAnalyze
import MesonAST

class SharedLibraryToModuleCodeActionProvider: CodeActionProvider {
  func findCodeActionsForNode(uri: DocumentURI, node: Node, tree: MesonTree) -> [CodeAction] {
    guard let fexpr = node as? FunctionExpression else { return [] }
    guard let function = fexpr.function else { return [] }
    if function.id() != "shared_library" { return [] }
    guard let al = fexpr.argumentList as? ArgumentList else { return [] }
    if al.getKwarg(name: "darwin_versions") != nil || al.getKwarg(name: "soversion") != nil
      || al.getKwarg(name: "version") != nil
    {
      return []
    }
    let range = Shared.nodeToRange(fexpr.id)
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
}
