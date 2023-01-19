import MesonAST

public class ImportTypeAnalyzer: MesonTypeAnalyzer {
  public func derive(node: Node, fn: Function, options: [MesonOption], ns: TypeNamespace) -> [Type]
  {
    if let fe = node as? FunctionExpression {
      if (fe.id as! IdExpression).id != "import" { return fn.returnTypes }
      if let alo = fe.argumentList {
        if let al = alo as? ArgumentList {
          if al.args.count > 0 {
            let arg0 = al.args[0]
            if arg0 is StringLiteral {
              let t = (arg0 as! StringLiteral).contents()
              switch t {
              case "cmake": return [ns.types["cmake_module"]!]
              case "fs": return [ns.types["fs_module"]!]
              case "gnome": return [ns.types["gnome_module"]!]
              case "i18n": return [ns.types["i18n_module"]!]
              default: return fn.returnTypes
              }
            }
          }
        }
      }
    }
    return fn.returnTypes
  }
}
