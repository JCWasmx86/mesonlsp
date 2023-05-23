import LanguageServerProtocol
import MesonAnalyze
import MesonAST

protocol MainTreeCodeActionProvider {
  func findCodeActionsForNode(
    uri: DocumentURI,
    node: Node,
    tree: MesonTree,
    subprojects: SubprojectState?,
    rootDirectory: String
  ) -> [CodeAction]
}
