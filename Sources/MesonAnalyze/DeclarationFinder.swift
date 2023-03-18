import Foundation
import Logging
import MesonAST

extension MesonTree {
  public func findDeclaration(node: IdExpression) -> (String, [UInt32])? {
    if let p = node.parent {
      if let assS = p as? AssignmentStatement, assS.lhs.equals(right: node), assS.op == .equals {
        return makeTuple(node)
      } else {
        return findDeclaration2(name: node.id, node: node, parent: p)
      }
    }
    return nil
  }

  func iterateOverSelectionStatement(name: String, node: Node, sst: SelectionStatement) -> (
    String, [UInt32]
  )? {
    var block_idx = 0
    var stmt_idx = 0
    var breakLoops = false
    for bb in sst.blocks {
      for b in bb {
        if b.location.startLine <= node.location.startLine
          && b.location.endLine >= node.location.endLine
        {
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
        if let r = evalStatement(name, s) { return r }
      }
    }
    return nil
  }

  func iterateOverIterationStatement(name: String, node: Node, its: IterationStatement) -> (
    String, [UInt32]
  )? {
    var stmt_idx = 0
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
        if let r = evalStatement(name, s) { return r }
      }
    }
    for x in its.ids where x is IdExpression && (x as! IdExpression).id == name {
      return makeTuple(x)
    }
    return nil
  }

  func iterateOverBuildDefinition(name: String, node: Node, parent: Node, bd: BuildDefinition) -> (
    String, [UInt32]
  )? {
    var stmt_idx = 0
    for b in bd.stmts {
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
        let s = bd.stmts[ridx]
        if let r = evalStatement(name, s) { return r }
      }
      if node.parent == nil { return nil }
      return findDeclaration2(name: name, node: parent, parent: node.parent!)
    }
    return nil
  }
  func findDeclaration2(name: String, node: Node, parent: Node) -> (String, [UInt32])? {
    if let sst = parent as? SelectionStatement {
      if let r = iterateOverSelectionStatement(name: name, node: node, sst: sst) { return r }
    } else if let bd = parent as? BuildDefinition {
      if let r = iterateOverBuildDefinition(name: name, node: node, parent: parent, bd: bd) {
        return r
      }
    } else if let its = parent as? IterationStatement {
      if let r = iterateOverIterationStatement(name: name, node: node, its: its) { return r }
    } else if parent is SourceFile {
      if parent.parent != nil && parent.parent is SubdirCall {
        return findDeclaration2(name: name, node: parent.parent!, parent: parent.parent!.parent!)
      }
    }
    if node.parent != nil && node.parent!.parent != nil {
      return findDeclaration2(name: name, node: node.parent!, parent: node.parent!.parent!)
    }
    return nil
  }

  func simpleAnalyze(_ name: String, _ s: Node) -> (String, [UInt32])? {
    if let assS = s as? AssignmentStatement, let assSLHS = assS.lhs as? IdExpression,
      assSLHS.id == name, assS.op == .equals
    {
      return makeTuple(assS.lhs)
    } else if let its = s as? IterationStatement {
      for s1 in its.block.reversed() { if let r = simpleAnalyze(name, s1) { return r } }
      for ids in its.ids where ids is IdExpression && (ids as! IdExpression).id == name {
        return makeTuple(ids)
      }
    } else if let ses = s as? SelectionStatement {
      for block in ses.blocks.reversed() {
        for s in block.reversed() { if let r = simpleAnalyze(name, s) { return r } }
      }
    } else if let sc = s as? SubdirCall, let r = self.evalSubdir(name, sc) {
      return r
    }
    return nil
  }
  func evalSubdir(_ name: String, _ s: SubdirCall) -> (String, [UInt32])? {
    if let sf = self.findSubdirTree(file: s.fullFile), let sfn = sf.ast as? SourceFile,
      let bd = sfn.build_definition as? BuildDefinition
    {
      for stmt in bd.stmts.reversed() { if let r = simpleAnalyze(name, stmt) { return r } }
    }
    return nil
  }

  func evalStatement(_ name: String, _ s: Node) -> (String, [UInt32])? {
    if let assS = s as? AssignmentStatement, let assSLHS = assS.lhs as? IdExpression,
      assSLHS.id == name, assS.op == .equals
    {
      return makeTuple(assS.lhs)
    } else if s is IterationStatement || s is SelectionStatement {
      if let r = searchExtended(name: name, node: s) { return r }
    } else if let sc = s as? SubdirCall, let r = self.evalSubdir(name, sc) {
      return r
    }
    return nil
  }
  func searchExtended(name: String, node: Node) -> (String, [UInt32])? {
    if let its = node as? IterationStatement {
      for s in its.block.reversed() { if let r = evalStatement(name, s) { return r } }
    } else if let ses = node as? SelectionStatement {
      for block in ses.blocks.reversed() {
        for s in block.reversed() { if let r = evalStatement(name, s) { return r } }
      }
    } else if let sc = node as? SubdirCall, let r = self.evalSubdir(name, sc) {
      return r
    }
    return nil
  }
  func makeTuple(_ node: Node) -> (String, [UInt32]) {
    let file = node.file.file
    let line = node.location.startLine
    let column = node.location.startColumn
    return (file, [line, column])
  }
}
