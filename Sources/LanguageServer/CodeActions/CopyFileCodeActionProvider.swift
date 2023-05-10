import LanguageServerProtocol
import Logging
import MesonAnalyze
import MesonAST

class CopyFileCodeActionProvider: CodeActionProvider {
  func findCodeActionsForNode(uri: DocumentURI, node: Node, tree: MesonTree) -> [CodeAction] {
    if let fexpr = node as? FunctionExpression, let f = fexpr.function, f.id() == "configure_file",
      let al = fexpr.argumentList as? ArgumentList, self.expectedArgs(al)
    {
      let input = al.getKwarg(name: "input")!
      let output = al.getKwarg(name: "output")!
      let install = al.getKwarg(name: "install")
      let install_dir = al.getKwarg(name: "install_dir")
      let install_mode = al.getKwarg(name: "install_mode")
      let install_tag = al.getKwarg(name: "install_tag")
      var str = ""
      str += self.stringValue(node: input) + ",\n"
      str += self.stringValue(node: output) + ",\n"
      if install != nil { str += "install: " + self.stringValue(node: install!) + ",\n" }
      if install_dir != nil {
        str += "install_dir: " + self.stringValue(node: install_dir!) + ",\n"
      }
      if install_mode != nil {
        str += "install_mode: " + self.stringValue(node: install_mode!) + ",\n"
      }
      if install_tag != nil {
        str += "install_tag: " + self.stringValue(node: install_tag!) + ",\n"
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
    return []
  }

  private func stringValue(node: Node) -> String {
    do {
      let string = try node.file.contents()
      let lines = string.split(separator: "\n", omittingEmptySubsequences: false)
      if node.location.startLine == node.location.endLine {
        let line = lines[Int(node.location.startLine)]
        let sI = line.index(line.startIndex, offsetBy: Int(node.location.startColumn))
        let eI = line.index(line.startIndex, offsetBy: Int(node.location.endColumn - 1))
        return String(line[sI...eI])
      }
      let firstLine = String(lines[Int(node.location.startLine - 1)])
      let sI = firstLine.index(firstLine.startIndex, offsetBy: Int(node.location.startColumn))
      let firstLine1 = String(firstLine[sI...])
      let lastLine = lines[Int(node.location.endLine - 1)]
      let eI = lastLine.index(lastLine.startIndex, offsetBy: Int(node.location.endColumn - 1))
      let lastLine1 = String(lastLine[...eI])
      let sI1 = lines.index(lines.startIndex, offsetBy: Int(node.location.startLine))
      let eI1 = lines.index(lines.startIndex, offsetBy: Int(node.location.endLine - 1))
      let concatenated: String = Array(lines[sI1..<eI1].map { String($0) }).joined(separator: "\n")
      return String(firstLine1) + "\n" + concatenated + "\n" + String(lastLine1)
    } catch { return "Something went wrong" }
  }

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
