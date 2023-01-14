import Foundation
import MesonAST

public func findDeclaration(node: IdExpression) -> (String, UInt32, UInt32)? {
  print(node, node.parent)
  if let p = node.parent {
    print(p is AssignmentStatement)
    if p is AssignmentStatement && (p as! AssignmentStatement).lhs.equals(right: node)
      && (p as! AssignmentStatement).op == .equals
    {
      print("Is assignment")
      return makeTuple(node)
    } else {
      return findDeclaration2(name: node.id, node: node, parent: p)
    }
  }
  return nil
}

public func findDeclaration2(name: String, node: Node, parent: Node) -> (String, UInt32, UInt32)? {
  print(node, parent)
  if parent is SelectionStatement {
    let sst = (parent as! SelectionStatement)
    var block_idx = 0
    var stmt_idx = 0
    var breakLoops = false
    for bb in sst.blocks {
      for b in bb {
        if b.location.startLine <= node.location.startLine
          && b.location.endLine >= node.location.endLine
        {
          print("Found our statement in SST")
          // We found our statement
          breakLoops = true
        }
        if breakLoops { break }
        stmt_idx += 1
      }
      if breakLoops { break }
      block_idx += 1
    }
    if block_idx < sst.blocks.count && stmt_idx <= sst.blocks[block_idx].count {
      for idx in 0..<stmt_idx {
        let ridx = (stmt_idx - 1) - idx
        let s = sst.blocks[block_idx][ridx]
        if s is AssignmentStatement && (s as! AssignmentStatement).lhs is IdExpression
          && ((s as! AssignmentStatement).lhs as! IdExpression).id == name
          && (s as! AssignmentStatement).op == .equals
        {
          return makeTuple((s as! AssignmentStatement).lhs)
        }
      }
    } else {
      print("SST: \(block_idx) is equals to \(sst.blocks.count)")
    }
  } else if parent is BuildDefinition {
    var stmt_idx = 0
    let bd = (parent as! BuildDefinition)
    for b in bd.stmts {
      print("BD: ", b.location.format(), node.location.format())
      if (b.location.startLine <= node.location.startLine
        && b.location.endLine >= node.location.endLine) || b.equals(right: node)
      {
        break
      }
      stmt_idx += 1
    }
    if stmt_idx <= bd.stmts.count {
      for idx in 0..<stmt_idx {
        let ridx = (stmt_idx - 1) - idx
        print(ridx, stmt_idx, bd.stmts.count)
        let s = bd.stmts[ridx]
        print(">>", s, s.location.format())
        if s is AssignmentStatement && (s as! AssignmentStatement).lhs is IdExpression
          && ((s as! AssignmentStatement).lhs as! IdExpression).id == name
          && (s as! AssignmentStatement).op == .equals
        {
          return makeTuple((s as! AssignmentStatement).lhs)
        }
      }
      if node.parent == nil { return nil }
      return findDeclaration2(name: name, node: parent, parent: node.parent!)
    }
  } else if parent is IterationStatement {
    var stmt_idx = 0
    let its = (parent as! IterationStatement)
    for b in its.block {
      if b.location.startLine <= node.location.startLine
        && b.location.endLine >= node.location.endLine
      {
        break
      }
      stmt_idx += 1
    }
    if stmt_idx <= its.block.count {
      for idx in 0..<stmt_idx {
        let ridx = (stmt_idx - 1) - idx
        let s = its.block[ridx]
        if s is AssignmentStatement && (s as! AssignmentStatement).lhs is IdExpression
          && ((s as! AssignmentStatement).lhs as! IdExpression).id == name
          && (s as! AssignmentStatement).op == .equals
        {
          return makeTuple((s as! AssignmentStatement).lhs)
        }
      }
    }
    for x in its.ids where x is IdExpression && (x as! IdExpression).id == name {
      return makeTuple(x)
    }
  } else if parent is SourceFile {
    print(parent, parent.parent)
    if parent.parent != nil && parent.parent is SubdirCall {
      print("SubdirCall")
      return findDeclaration2(name: name, node: parent.parent!, parent: parent.parent!.parent!)
    }
  }
  if node.parent != nil && node.parent!.parent != nil {
    return findDeclaration2(name: name, node: node.parent!, parent: node.parent!.parent!)
  }
  return nil
}

func makeTuple(_ node: Node) -> (String, UInt32, UInt32) {
  let file = node.file.file
  let line = node.location.startLine
  let column = node.location.startColumn
  return (file, line, column)
}
