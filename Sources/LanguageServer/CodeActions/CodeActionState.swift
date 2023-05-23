import LanguageServerProtocol
import MesonAnalyze
import MesonAST

class CodeActionState {
  let providers: [CodeActionProvider] = [
    IntegerToBaseCodeActionProvider(), LibraryToGenericCodeActionProvider(),
    SharedLibraryToModuleCodeActionProvider(), SharedModuleToLibraryCodeActionProvider(),
    SortFilenamesCodeActionProvider(), SortFilenamesSAICodeActionProvider(),
    SortFilenamesIASCodeActionProvider(), CopyFileCodeActionProvider(),
    DeclareDependencyCodeActionProvider(),
  ]
  let mainTreeProviders: [MainTreeCodeActionProvider] = [

    ]

  public func apply(uri: DocumentURI, node: Node, tree: MesonTree) -> [CodeAction] {
    return self.providers.flatMap { $0.findCodeActionsForNode(uri: uri, node: node, tree: tree) }
  }

  public func applyToMainTree(
    uri: DocumentURI,
    node: Node,
    tree: MesonTree,
    subprojects: SubprojectState?
  ) -> [CodeAction] {
    return self.mainTreeProviders.flatMap {
      $0.findCodeActionsForNode(uri: uri, node: node, tree: tree, subprojects: subprojects)
    }
  }
}
