import MesonAST
public class BuildTargetTypeAnalyzer: MesonTypeAnalyzer {
  public func derive(node: Node, fn: Function, options: [MesonOption], ns: TypeNamespace) -> [Type]
  {
    if let fe = node as? FunctionExpression, let alo = fe.argumentList,
      let al = alo as? ArgumentList
    {
      for arg in al.args where arg is KeywordItem {
        if let sl = (arg as! KeywordItem).value as? StringLiteral {
          switch sl.contents() {
          case "executable": return [ns.types["exe"]!]
          case "shared_library": return [ns.types["lib"]!]
          case "shared_module": return [ns.types["build_tgt"]!]
          case "static_library": return [ns.types["lib"]!]
          case "both_libraries": return [ns.types["both_libs"]!]
          case "library": return [ns.types["lib"]!]
          case "jar": return [ns.types["jar"]!]
          default: break
          }
        }
      }
    }
    return [
      ns.types["exe"]!, ns.types["lib"]!, ns.types["build_tgt"]!, ns.types["both_libs"]!,
      ns.types["jar"]!,
    ]
  }
}
