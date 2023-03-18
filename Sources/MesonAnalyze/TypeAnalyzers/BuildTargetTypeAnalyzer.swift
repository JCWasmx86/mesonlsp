import MesonAST

public class BuildTargetTypeAnalyzer: MesonTypeAnalyzer {
  static let mappings: [String: String] = [
    "executable": "exe", "shared_library": "lib", "shared_module": "build_tgt",
    "static_library": "lib", "both_libraries": "both_libs", "library": "lib", "jar": "jar",
  ]

  public func derive(node: Node, fn: Function, options: [MesonOption], ns: TypeNamespace) -> [Type]
  {
    if let fe = node as? FunctionExpression, let alo = fe.argumentList,
      let al = alo as? ArgumentList
    {
      for arg in al.args where arg is KeywordItem {
        if let sl = (arg as! KeywordItem).value as? StringLiteral {
          let s = sl.contents()
          if let t = Self.mappings[s] { return [ns.types[t]!] }
          break
        }
      }
    }
    return [
      ns.types["exe"]!, ns.types["lib"]!, ns.types["build_tgt"]!, ns.types["both_libs"]!,
      ns.types["jar"]!,
    ]
  }
}
