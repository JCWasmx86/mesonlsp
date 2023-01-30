import MesonAST

public class ListGetTypeAnalyzer: MesonTypeAnalyzer {
  public func derive(node: Node, fn: Function, options: [MesonOption], ns: TypeNamespace) -> [Type]
  {
    if let me = node as? MethodExpression {
      let parentTypes = me.obj.types
      let extraTypes: [Type]
      if let al = me.argumentList, let argList = al as? ArgumentList, argList.args.count > 1 {
        extraTypes = argList.args[1].types
      } else {
        extraTypes = []
      }
      for p in parentTypes where p is ListType { return extraTypes + (p as! ListType).types }
    }
    return fn.returnTypes
  }
}
