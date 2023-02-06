import MesonAST

public class OptionTypeAnalyzer: MesonTypeAnalyzer {
  public func derive(node: Node, fn: Function, options: [MesonOption], ns: TypeNamespace) -> [Type]
  {
    if let fe = node as? FunctionExpression, (fe.id as! IdExpression).id == "get_option" {
      if let alo = fe.argumentList, let al = alo as? ArgumentList, al.args.count > 0 {
        let arg0 = al.args[0]
        if arg0 is StringLiteral {
          let t = (arg0 as! StringLiteral).contents()
          let opt = options.filter({ $0.name == t }).first
          if let o = opt {
            if o is StringOption {
              return [ns.types["str"]!]
            } else if o is IntOption {
              return [ns.types["int"]!]
            } else if o is BoolOption {
              return [ns.types["bool"]!]
            } else if o is FeatureOption {
              return [ns.types["feature"]!]
            } else if o is ComboOption {
              // TODO: Is this right?
              return [ns.types["str"]!]
            } else {
              // TODO: Can we do more?
              return [ListType(types: [ns.types["int"]!, ns.types["str"]!, ns.types["bool"]!])]
            }
          }
        }
      }
    }
    return fn.returnTypes
  }
}
