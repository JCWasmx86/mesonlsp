import Foundation
import IOUtils
import LanguageServerProtocol
import MesonAnalyze
import MesonAST
import Wrap

class DownloadFromWrapDBCodeActionProvider: MainTreeCodeActionProvider {
  func findCodeActionsForNode(
    uri: DocumentURI,
    node: Node,
    tree: MesonTree,
    subprojects: SubprojectState?,
    rootDirectory: String
  ) -> [CodeAction] {
    if let sp = subprojects, let fe = node as? FunctionExpression, let fn = fe.function,
      fn.name == "subproject", let al = fe.argumentList as? ArgumentList,
      let firstArg = al.args.first, let sl = firstArg as? StringLiteral
    {
      if sp.subprojects.first(where: { $0.name == sl.contents() }) != nil { return [] }
      if !WrapDB.INSTANCE.containsWrap(sl.contents()) { return [] }
      let range = Position(line: 0, utf16index: 0)..<Position(line: 0, utf16index: 1)
      guard let contents = try? WrapDB.INSTANCE.downloadWrapToString(sl.contents()) else {
        return []
      }
      let wrapPath = Path(
        rootDirectory + Path.separator + "subprojects\(Path.separator)\(sl.contents()).wrap"
      )
      let changes = [
        DocumentURI(URL(fileURLWithPath: wrapPath.description)): [
          TextEdit(range: range, newText: contents)
        ]
      ]
      let edit = WorkspaceEdit(changes: changes)
      return [
        CodeAction(
          title: "Download wrap \(sl.contents()) from WrapDB",
          kind: CodeActionKind.refactor,
          edit: edit
        )
      ]
    }
    return []
  }
}
