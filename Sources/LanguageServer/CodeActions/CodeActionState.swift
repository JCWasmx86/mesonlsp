import LanguageServerProtocol
import MesonAST

class CodeActionState {
  let providers: [CodeActionProvider] = [
    IntegerToBaseCodeActionProvider(), LibraryToGenericCodeActionProvider(),
  ]

  public func apply(uri: DocumentURI, node: Node) -> [CodeAction] {
    return self.providers.flatMap { $0.findCodeActionsForNode(uri: uri, node: node) }
  }
}
