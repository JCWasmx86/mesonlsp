import LanguageServerProtocol
import MesonAST

class SortFilenamesCodeActionProvider: CodeActionProvider {
  func findCodeActionsForNode(uri: DocumentURI, node: Node) -> [CodeAction] {
    if let fexpr = node as? FunctionExpression, let al = fexpr.argumentList as? ArgumentList,
      let f = fexpr.function, let count = self.sourceFunc(f), self.validArgs(al, count)
    {
      let strLiterals = al.args.filter { $0 as? KeywordItem == nil }.map {
        ($0 as! StringLiteral).contents()
      }[count...]
      let sortedStrLiterals = strLiterals.sorted(by: sortFunc)
      if strLiterals.elementsEqual(sortedStrLiterals) { return [] }
      if al.args.filter({ $0 as? KeywordItem == nil }).count - count != strLiterals.count {
        fatalError(
          "Oops: Expected \(al.args.filter { $0 as? KeywordItem == nil }.count - count), got \(strLiterals.count)"
        )
      }
      let strNodes = al.args.filter { $0 as? KeywordItem == nil }[count...].reversed()
      var n = 0
      let revSortedStrs = sortedStrLiterals.reversed()
      var edits: [TextEdit] = []
      while n < strNodes.count {
        let il = strNodes[strNodes.index(strNodes.startIndex, offsetBy: n)]
        let range =
          Position(
            line: Int(il.location.startLine),
            utf16index: Int(il.location.startColumn)
          )..<Position(line: Int(il.location.endLine), utf16index: Int(il.location.endColumn))
        edits.append(
          TextEdit(
            range: range,
            newText:
              "'\(revSortedStrs[revSortedStrs.index(revSortedStrs.startIndex, offsetBy: n)])'"
          )
        )
        n += 1
      }
      return [
        CodeAction(
          title: "Sort filenames",
          kind: CodeActionKind.refactor,
          edit: WorkspaceEdit(changes: [uri: edits])
        )
      ]
    }
    return []
  }

  func sortFunc(_ a: String, _ b: String) -> Bool {
    let aC = a.filter { $0 == "/" }.count
    let bC = b.filter { $0 == "/" }.count
    if aC == bC && aC != 0 { return aC < bC }
    if aC > bC { return true }
    if bC > aC { return false }
    return a <= b
  }

  func validArgs(_ al: ArgumentList, _ count: Int) -> Bool {
    let args = al.args
    // It does not make sense to sort one string/identifier
    if al.countPositionalArgs() < (count + 1) { return false }
    return args.filter { $0 as? KeywordItem == nil }[count...].filter {
      ($0 as? StringLiteral) != nil
    }.count == al.countPositionalArgs() - count
  }

  // We will have to special case files(), include_directories(), install_data()
  func sourceFunc(_ f: Function) -> Int? {
    let id = f.id()
    if id == "both_libraries" || id == "build_target" || id == "executable" || id == "jar"
      || id == "library" || id == "shared_library" || id == "shared_module"
      || id == "static_library"
    {
      return 1
    } else if id == "files" || id == "include_directories" || id == "install_data" {
      return 0
    }
    return nil
  }
}
