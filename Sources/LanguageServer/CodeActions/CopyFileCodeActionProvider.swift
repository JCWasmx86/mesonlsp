import LanguageServerProtocol
import Logging
import MesonAnalyze
import MesonAST

class CopyFileCodeActionProvider: CodeActionProvider {
  // swiftlint:disable cyclomatic_complexity
  func findCodeActionsForNode(uri: DocumentURI, node: Node, tree: MesonTree) -> [CodeAction] {
    guard let fexpr = node as? FunctionExpression else { return [] }
    guard let function = fexpr.function else { return [] }
    if function.id() != "configure_file" { return [] }
    guard let al = fexpr.argumentList as? ArgumentList else { return [] }
    if !self.expectedArgs(al) { return [] }
    let input = al.getKwarg(name: "input")!
    let output = al.getKwarg(name: "output")!
    let install = al.getKwarg(name: "install")
    let install_dir = al.getKwarg(name: "install_dir")
    let install_mode = al.getKwarg(name: "install_mode")
    let install_tag = al.getKwarg(name: "install_tag")
    var str = ""
    str += Shared.stringValue(node: input) + ",\n"
    str += Shared.stringValue(node: output) + ",\n"
    if install != nil { str += "install: " + Shared.stringValue(node: install!) + ",\n" }
    if install_dir != nil {
      str += "install_dir: " + Shared.stringValue(node: install_dir!) + ",\n"
    }
    if install_mode != nil {
      str += "install_mode: " + Shared.stringValue(node: install_mode!) + ",\n"
    }
    if install_tag != nil {
      str += "install_tag: " + Shared.stringValue(node: install_tag!) + ",\n"
    }
    var replacementString = "import('fs').copyfile"
    if let scope = tree.scope {
      var name: String?
      for v in scope.variables where !v.1.isEmpty && v.1[0] is FSModule {
        name = v.0
        break
      }
      if name != nil { replacementString = name! + ".copyfile" }
    }
    let editArgumentList = TextEdit(range: Shared.nodeToRange(al), newText: str)
    let fn = fexpr.id
    let editFunctionName = TextEdit(range: Shared.nodeToRange(fn), newText: replacementString)
    let changes = [uri: [editArgumentList, editFunctionName]]
    let edit = WorkspaceEdit(changes: changes)
    return [
      CodeAction(
        title: "Use fs.copyfile() instead of configure_file to copy files",
        kind: CodeActionKind.refactor,
        edit: edit
      )
    ]
  }
  // swiftlint:enable cyclomatic_complexity

  private func expectedArgs(_ al: ArgumentList) -> Bool {
    guard let copy = al.getKwarg(name: "copy") else { return false }
    guard al.getKwarg(name: "input") != nil else { return false }
    guard al.getKwarg(name: "output") != nil else { return false }
    for a in al.args where a is KeywordItem {
      guard let a = a as? KeywordItem else { return false }
      guard let id = a.key as? IdExpression else { continue }
      if id.id == "copy" || id.id == "input" || id.id == "output" || id.id == "install"
        || id.id == "install_dir" || id.id == "install_mode" || id.id == "install_tag"
      {
        continue
      }
      return false
    }
    guard let copyValue = copy as? BooleanLiteral else { return false }
    return copyValue.value
  }
}
