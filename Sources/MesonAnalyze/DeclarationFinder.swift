import MesonAST

public func findDeclaration(node: IdExpression) -> (String, UInt32, UInt32)? {
  if let p = node.parent {
    print(p is AssignmentStatement)
    if p is AssignmentStatement && (p as! AssignmentStatement).lhs.equals(right: node)
      && (p as! AssignmentStatement).op == .equals
    {
      return makeTuple(node)
    }
  }
  return nil
}

func makeTuple(_ node: Node) -> (String, UInt32, UInt32) {
  let file = node.file.file
  let line = node.location.startLine
  let column = node.location.startColumn
  return (file, line, column)
}
