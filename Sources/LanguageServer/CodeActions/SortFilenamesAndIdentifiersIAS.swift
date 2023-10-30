import LanguageServerProtocol
import MesonAnalyze
import MesonAST

class SortFilenamesIASCodeActionProvider: CodeActionProvider {
  func findCodeActionsForNode(uri: DocumentURI, node: Node, tree: MesonTree) -> [CodeAction] {
    guard let fexpr = node as? FunctionExpression else { return [] }
    guard let function = fexpr.function else { return [] }
    guard let al = fexpr.argumentList as? ArgumentList else { return [] }
    guard let count = Shared.isSortableFunction(function) else { return [] }
    if !self.validArgs(al, count) { return [] }
    let toSort = al.args.filter { $0 as? KeywordItem == nil }[count...]
    if toSort.filter({ $0 as? IdExpression != nil }).isEmpty { return [] }
    let sortedNodes = toSort.sorted(by: sortFunc)
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
      let node = strNodes[strNodes.index(strNodes.startIndex, offsetBy: n)]
      let range = Shared.nodeToRange(node)
      let nodeToAdd = revSortedNodes[revSortedNodes.index(revSortedNodes.startIndex, offsetBy: n)]
      if nodeToAdd.equals(right: node) {
        n += 1
        continue
      }
      let str =
        nodeToAdd is IdExpression
        ? (nodeToAdd as! IdExpression).id : ("'" + (nodeToAdd as! StringLiteral).contents() + "'")
      edits.append(TextEdit(range: range, newText: str))
      n += 1
    }
    if edits.isEmpty { return [] }
    return [
      CodeAction(
        title: "Sort filenames (Identifiers after string literals)",
        kind: CodeActionKind.refactor,
        edit: WorkspaceEdit(changes: [uri: edits])
      )
    ]
  }

  func sortFunc(_ a: Node, _ b: Node) -> Bool {
    if let aI = a as? IdExpression, let bI = b as? IdExpression {
      return aI.id <= bI.id
    } else if a is IdExpression {
      return false
    } else if b is IdExpression {
      return true
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
}
