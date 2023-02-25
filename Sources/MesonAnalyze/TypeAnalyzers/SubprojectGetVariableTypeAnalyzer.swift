import MesonAST

public class SubprojectGetVariableTypeAnalyzer: MesonTypeAnalyzer {
  public func derive(node: Node, fn: Function, options: [MesonOption], ns: TypeNamespace) -> [Type]
  {
    if let me = node as? MethodExpression {
      let extraTypes: [Type]
      if let al = me.argumentList, let argList = al as? ArgumentList, argList.args.count > 1 {
        extraTypes = argList.args[1].types
      } else {
        extraTypes = []
      }
      return fn.returnTypes + extraTypes
    }
    return fn.returnTypes
  }
}
