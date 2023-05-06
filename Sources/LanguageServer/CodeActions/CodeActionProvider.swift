import LanguageServerProtocol
import MesonAST

protocol CodeActionProvider {
  func findCodeActionsForNode(uri: DocumentURI, node: Node) -> [CodeAction]
}
