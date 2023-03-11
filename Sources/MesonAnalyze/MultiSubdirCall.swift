import MesonAST
import SwiftTreeSitter

public class MultiSubdirCall: FunctionExpression {
  public var subdirnames: [String]
  public var fullFiles: [String]

  init(file: MesonSourceFile, node: FunctionExpression) {
    self.subdirnames = []
    self.fullFiles = []
    super.init()
    self.file = file
    self.id = node.id
    self.location = node.location
    self.argumentList = node.argumentList
  }
  public override func visit(visitor: CodeVisitor) {
    if let ev = visitor as? ExtendedCodeVisitor {
      ev.visitMultiSubdirCall(node: self)
    } else {
      visitor.visitFunctionExpression(node: self)
    }
  }
  public override func visitChildren(visitor: CodeVisitor) { super.visitChildren(visitor: visitor) }

  public override func setParents() {
    self.id.parent = self
    self.id.setParents()
    self.argumentList?.parent = self
    self.argumentList?.setParents()
  }

  public func heuristics() -> [String] {
    let ret: [String] = []
    for a in (self.argumentList as! ArgumentList).args where a is IdExpression {
      if let idexpr = a as? IdExpression {
        let id = idexpr.id
        return self.searchFor(id)
      }
    }
    return ret
  }

  func searchFor(_ id: String) -> [String] { return searchFor2(id, self) }

  func searchFor2(_ id: String, _ node: MesonAST.Node) -> [String] {
    let parent = node.parent!
    if let bd = parent as? BuildDefinition {
      var foundOurselves = false
      for b in bd.stmts.reversed() {
        if b.equals(right: node) {
          foundOurselves = true
          continue
        } else if foundOurselves {
          if let s = b as? AssignmentStatement, let idexpr = s.lhs as? IdExpression,
            s.op == .some(.equals), idexpr.id == id
          {
            if let r = s.rhs as? StringLiteral {
              return [r.contents()]
            } else if let r = s.rhs as? ArrayLiteral {
              return Array(
                r.args.filter({ $0 is StringLiteral }).map({ ($0 as! StringLiteral).contents() })
              )
            }
          }
          continue
        }  // We are below the subdir call
      }
      // Won't traverse the sourcefiles, too slow (For now)
      return []
    } else if let its = parent as? IterationStatement {
      var foundOurselves = false
      for b in its.block.reversed() {
        if b.equals(right: node) {
          foundOurselves = true
          continue
        } else if foundOurselves {
          if let s = b as? AssignmentStatement, let idexpr = s.lhs as? IdExpression,
            s.op == .some(.equals), idexpr.id == id
          {
            if let r = s.rhs as? StringLiteral {
              return [r.contents()]
            } else if let r = s.rhs as? ArrayLiteral {
              return Array(
                r.args.filter({ $0 is StringLiteral }).map({ ($0 as! StringLiteral).contents() })
              )
            }
          }
          continue
        }  // We are below the subdir call
      }
      for i in its.ids {
        if let idexpr = i as? IdExpression, idexpr.id == id {
          if let arr = its.expression as? ArrayLiteral {
            return Array(
              arr.args.filter({ $0 is StringLiteral }).map({ ($0 as! StringLiteral).contents() })
            )
          } else if let idexpr2 = its.expression as? IdExpression {
            return self.searchFor2(idexpr2.id, parent)
          }
          break
        }
      }
      return self.searchFor2(id, parent)
    } else if let sst = parent as? SelectionStatement {
      for blk in sst.blocks.reversed() {
        var foundOurselves = true
        for b in blk.reversed() {
          if b.equals(right: node) {
            foundOurselves = true
            continue
          } else if foundOurselves {
            if let s = b as? AssignmentStatement, let idexpr = s.lhs as? IdExpression,
              s.op == .some(.equals), idexpr.id == id
            {
              if let r = s.rhs as? StringLiteral {
                return [r.contents()]
              } else if let r = s.rhs as? ArrayLiteral {
                return Array(
                  r.args.filter({ $0 is StringLiteral }).map({ ($0 as! StringLiteral).contents() })
                )
              }
            }
          }
        }
        if foundOurselves { break }
      }
      return self.searchFor2(id, parent)
    }
    return []
  }
}
