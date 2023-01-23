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
              case "rust": return [ns.types["rust_module"]!]
              case "unstable-rust": return [ns.types["rust_module"]!]
              case "python": return [ns.types["python_module"]!]
              case "python3": return [ns.types["python3_module"]!]
              case "pkgconfig": return [ns.types["pkgconfig_module"]!]
              case "keyval": return [ns.types["keyval_module"]!]
              case "dlang": return [ns.types["dlang_module"]!]
              case "unstable-external_project": return [ns.types["external_project_module"]!]
              case "hotdoc": return [ns.types["hotdoc_module"]!]
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
