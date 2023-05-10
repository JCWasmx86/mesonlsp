import LanguageServerProtocol
import MesonAnalyze
import MesonAST

class SortFilenamesCodeActionProvider: CodeActionProvider {
  func findCodeActionsForNode(uri: DocumentURI, node: Node, tree: MesonTree) -> [CodeAction] {
    if let fexpr = node as? FunctionExpression, let al = fexpr.argumentList as? ArgumentList,
      let f = fexpr.function, let count = Shared.isSortableFunction(f), self.validArgs(al, count)
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
      let nodes = al.args.filter { $0 as? KeywordItem == nil }[count...].reversed()
      var n = 0
      let revSortedStrs = sortedStrLiterals.reversed()
      var edits: [TextEdit] = []
      while n < nodes.count {
        let node = nodes[nodes.index(nodes.startIndex, offsetBy: n)]
        let range = Shared.nodeToRange(node)
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
}
