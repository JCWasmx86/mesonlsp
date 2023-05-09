import LanguageServerProtocol
import MesonAnalyze
import MesonAST

class CodeActionState {
  let providers: [CodeActionProvider] = [
    IntegerToBaseCodeActionProvider(), LibraryToGenericCodeActionProvider(),
    SharedLibraryToModuleCodeActionProvider(), SharedModuleToLibraryCodeActionProvider(),
    SortFilenamesCodeActionProvider(), SortFilenamesSAICodeActionProvider(),
    SortFilenamesIASCodeActionProvider(), CopyFileCodeActionProvider(),
  ]

  public func apply(uri: DocumentURI, node: Node, tree: MesonTree) -> [CodeAction] {
    return self.providers.flatMap { $0.findCodeActionsForNode(uri: uri, node: node, tree: tree) }
  }
}
