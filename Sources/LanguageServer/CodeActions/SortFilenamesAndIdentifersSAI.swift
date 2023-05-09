import LanguageServerProtocol
import MesonAST

class SortFilenamesSAICodeActionProvider: CodeActionProvider {
  func findCodeActionsForNode(uri: DocumentURI, node: Node) -> [CodeAction] {
    if let fexpr = node as? FunctionExpression, let al = fexpr.argumentList as? ArgumentList,
      let f = fexpr.function, let count = self.sourceFunc(f), self.validArgs(al, count)
    {
      let toSort = al.args.filter { $0 as? KeywordItem == nil }[count...]
      let sortedNodes = toSort.sorted(by: sortFunc)
      // if toSort.elementsEqual(sortedNodes) { return [] }
      if al.args.filter({ $0 as? KeywordItem == nil }).count - count != toSort.count {
        fatalError(
          "Oops: Expected \(al.args.filter { $0 as? KeywordItem == nil }.count - count), got \(toSort.count)"
        )
      }
      let strNodes = al.args.filter { $0 as? KeywordItem == nil }[count...].reversed()
      var n = 0
      let revSortedNodes = sortedNodes.reversed()
      var edits: [TextEdit] = []
      while n < strNodes.count {
        let il = strNodes[strNodes.index(strNodes.startIndex, offsetBy: n)]
        let range =
          Position(
            line: Int(il.location.startLine),
            utf16index: Int(il.location.startColumn)
          )..<Position(line: Int(il.location.endLine), utf16index: Int(il.location.endColumn))
        let nodeToAdd = revSortedNodes[revSortedNodes.index(revSortedNodes.startIndex, offsetBy: n)]
        let str =
          nodeToAdd is IdExpression
          ? (nodeToAdd as! IdExpression).id : ("'" + (nodeToAdd as! StringLiteral).contents() + "'")
        edits.append(TextEdit(range: range, newText: str))
        n += 1
      }
      return [
        CodeAction(
          title: "Sort filenames (String literals after identifiers)",
          kind: CodeActionKind.refactor,
          edit: WorkspaceEdit(changes: [uri: edits])
        )
      ]
    }
    return []
  }

  func sortFunc(_ a: Node, _ b: Node) -> Bool {
    if let aI = a as? IdExpression, let bI = b as? IdExpression {
      return aI.id <= bI.id
    } else if a is IdExpression {
      return true
    } else if b is IdExpression {
      return false
    }
    let aS = (a as! StringLiteral).contents()
    let bS = (b as! StringLiteral).contents()
    let aC = aS.filter { $0 == "/" }.count
    let bC = bS.filter { $0 == "/" }.count
    if aC == bC && aC != 0 { return aC < bC }
    if aC > bC { return true }
    if bC > aC { return false }
    return aS <= bS
  }

  func validArgs(_ al: ArgumentList, _ count: Int) -> Bool {
    let args = al.args
    // It does not make sense to sort one string/identifier
    if al.countPositionalArgs() < (count + 1) { return false }
    return args.filter { $0 as? KeywordItem == nil }[count...].filter {
      ($0 as? StringLiteral) != nil || ($0 as? IdExpression) != nil
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
