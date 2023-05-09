import LanguageServerProtocol
import MesonAnalyze
import MesonAST

protocol CodeActionProvider {
  func findCodeActionsForNode(uri: DocumentURI, node: Node, tree: MesonTree) -> [CodeAction]
}
