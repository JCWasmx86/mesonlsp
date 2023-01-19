import MesonAST

public class ImportTypeAnalyzer: MesonTypeAnalyzer {
  public func derive(node: Node, fn: Function, options: [MesonOption], ns: TypeNamespace) -> [Type]
  {
    print("Running ImportTypeAnalyzer")
    if let fe = node as? FunctionExpression {
      print("Is FunctionExpression")
      if (fe.id as! IdExpression).id != "import" { return fn.returnTypes }
      if let alo = fe.argumentList {
        print("Has ArgumentList")
        if let al = alo as? ArgumentList {
          print("Has ArgumentList II")
          if al.args.count > 0 {
            print("Has args")
            let arg0 = al.args[0]
            if arg0 is StringLiteral {
              let t = (arg0 as! StringLiteral).contents()
              print(">>", t)
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
