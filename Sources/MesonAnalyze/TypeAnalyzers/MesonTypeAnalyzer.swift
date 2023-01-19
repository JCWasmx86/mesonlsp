import MesonAST

public protocol MesonTypeAnalyzer {
  func derive(node: Node, fn: Function, options: [MesonOption], ns: TypeNamespace) -> [Type]
}
