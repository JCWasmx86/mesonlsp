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
    for a in (self.argumentList as! ArgumentList).args
    where (a is IdExpression || a is BinaryExpression) {
      if let idexpr = a as? IdExpression {
        return Array(Set(self.searchFor(idexpr.id)))
      } else if let binaryExpr = a as? BinaryExpression {
        return Array(Set(self.evalBinaryExpression(binaryExpr)))
      }
    }
    return ret
  }

  func evalNode(_ node: MesonAST.Node) -> [String] {
    if let idexpr = node as? IdExpression {
      return self.searchFor(idexpr.id)
    } else if let sl = node as? StringLiteral {
      return [sl.contents()]
    } else if let be = node as? BinaryExpression {
      return self.evalBinaryExpression(be)
    }
    return []
  }

  func evalBinaryExpression(_ node: BinaryExpression) -> [String] {
    let str1 = self.evalNode(node.lhs)
    let str2 = self.evalNode(node.rhs)
    let sep = node.op == .div ? "/" : ""
    var ret: [String] = []
    for s in str1 { for s1 in str2 { ret.append(s + sep + s1) } }
    return ret
  }

  func searchFor(_ id: String) -> [String] { return searchFor2(id, self) }

  func evalBlock(_ node: MesonAST.Node, _ id: String) -> [String]? {
    if let its = node as? IterationStatement {
      var ret: [String] = []
      for b in its.block.reversed() { if let blocks = self.evalBlock(b, id) { ret += blocks } }
      for i in its.ids {
        if let idexpr = i as? IdExpression, idexpr.id == id {
          if let arr = its.expression as? ArrayLiteral {
            return Array(
              arr.args.filter({ $0 is StringLiteral }).map({ ($0 as! StringLiteral).contents() })
            )
          } else if let idexpr2 = its.expression as? IdExpression {
            ret += self.searchFor2(idexpr2.id, node)
          }
          break
        }
      }
      return ret.isEmpty ? nil : ret
    } else if let sst = node as? SelectionStatement {
      var ret: [String] = []
      for b1 in sst.blocks.reversed() {
        for b in b1.reversed() { if let blocks = self.evalBlock(b, id) { ret += blocks } }
      }
      return ret.isEmpty ? nil : ret
    } else if let s = node as? AssignmentStatement, let idexpr = s.lhs as? IdExpression,
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
    return nil
  }

  func searchFor2(_ id: String, _ node: MesonAST.Node) -> [String] {
    let parent = node.parent!
    if let bd = parent as? BuildDefinition {
      var foundOurselves = false
      var tmp: [String] = []
      for b in bd.stmts.reversed() {
        if b.equals(right: node) {
          foundOurselves = true
          continue
        } else if foundOurselves {
          if let s = b as? AssignmentStatement, let idexpr = s.lhs as? IdExpression,
            s.op == .some(.equals), idexpr.id == id
          {
            if let r = s.rhs as? StringLiteral {
              return [r.contents()] + tmp
            } else if let r = s.rhs as? ArrayLiteral {
              return Array(
                r.args.filter({ $0 is StringLiteral }).map({ ($0 as! StringLiteral).contents() })
              ) + tmp
            }
          } else if let rets = self.evalBlock(b, id) {
            tmp += rets
          }
          continue
        }  // We are below the subdir call
      }
      // Won't traverse the sourcefiles, too slow (For now)
      return tmp
    } else if let its = parent as? IterationStatement {
      var foundOurselves = false
      var tmp: [String] = []
      for b in its.block.reversed() {
        if b.equals(right: node) {
          foundOurselves = true
          continue
        } else if foundOurselves {
          if let s = b as? AssignmentStatement, let idexpr = s.lhs as? IdExpression,
            s.op == .some(.equals), idexpr.id == id
          {
            if let r = s.rhs as? StringLiteral {
              return [r.contents()] + tmp
            } else if let r = s.rhs as? ArrayLiteral {
              return Array(
                r.args.filter({ $0 is StringLiteral }).map({ ($0 as! StringLiteral).contents() })
              ) + tmp
            }
          } else if let rets = self.evalBlock(b, id) {
            tmp += rets
          }
          continue
        }  // We are below the subdir call
      }
      for i in its.ids {
        if let idexpr = i as? IdExpression, idexpr.id == id {
          if let arr = its.expression as? ArrayLiteral {
            return Array(
              arr.args.filter({ $0 is StringLiteral }).map({ ($0 as! StringLiteral).contents() })
            ) + tmp
          } else if let idexpr2 = its.expression as? IdExpression {
            return self.searchFor2(idexpr2.id, parent) + tmp
          }
          break
        }
      }
      return self.searchFor2(id, parent) + tmp
    } else if let sst = parent as? SelectionStatement {
      var tmp: [String] = []
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
                return [r.contents()] + tmp
              } else if let r = s.rhs as? ArrayLiteral {
                return Array(
                  r.args.filter({ $0 is StringLiteral }).map({ ($0 as! StringLiteral).contents() })
                ) + tmp
              }
            } else if let rets = self.evalBlock(b, id) {
              tmp += rets
            }
          }
        }
        if foundOurselves { break }
      }
      return self.searchFor2(id, parent) + tmp
    }
    return []
  }
}
