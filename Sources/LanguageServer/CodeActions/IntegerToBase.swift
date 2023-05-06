import LanguageServerProtocol
import MesonAST

class IntegerToBaseCodeActionProvider: CodeActionProvider {
  func findCodeActionsForNode(uri: DocumentURI, node: Node) -> [CodeAction] {
    var actions: [CodeAction] = []
    if let il = node as? IntegerLiteral {
      let strvalue = il.value.lowercased()
      let value = il.parse()
      if !strvalue.starts(with: "0x") {
        actions.append(
          self.makeAction(
            uri,
            il,
            "Convert to hexadecimal literal",
            "0x",
            String(value, radix: 16, uppercase: false)
          )
        )
      }
      if !strvalue.starts(with: "0b") {
        actions.append(
          self.makeAction(
            uri,
            il,
            "Convert to binary literal",
            "0b",
            String(value, radix: 2, uppercase: false)
          )
        )
      }
      if !strvalue.starts(with: "0o") {
        actions.append(
          self.makeAction(
            uri,
            il,
            "Convert to octal literal",
            "0o",
            String(value, radix: 8, uppercase: false)
          )
        )
      }
      if strvalue.starts(with: "0x") || strvalue.starts(with: "0b") || strvalue.starts(with: "0o") {
        actions.append(
          self.makeAction(
            uri,
            il,
            "Convert to decimal literal",
            "",
            String(value, radix: 10, uppercase: false)
          )
        )
      }
    }
    return actions
  }

  private func makeAction(
    _ uri: DocumentURI,
    _ il: IntegerLiteral,
    _ title: String,
    _ p: String,
    _ val: String
  ) -> CodeAction {
    let newValue =
      val.hasPrefix("-") ? (p + "-" + val.replacingOccurrences(of: "-", with: "")) : (p + val)
    let range =
      Position(
        line: Int(il.location.startLine),
        utf16index: Int(il.location.startColumn)
      )..<Position(line: Int(il.location.endLine), utf16index: Int(il.location.endColumn))
    let changes = [uri: [TextEdit(range: range, newText: newValue)]]
    let edit = WorkspaceEdit(changes: changes)
    return CodeAction(title: title + " (\(newValue))", kind: CodeActionKind.refactor, edit: edit)
  }
}
