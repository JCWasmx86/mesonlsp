import MesonAST

public func guessSetVariable(fe: FunctionExpression) -> [String] {
  if let al = fe.argumentList as? ArgumentList, !al.args.isEmpty {
    let exprToCalculate = al.args[0]
    var parent: Node? = fe
    while !(parent?.parent is IterationStatement || parent?.parent is SelectionStatement
      || parent?.parent is BuildDefinition)
    { parent = parent!.parent }
    return calculateExpression(parent!, exprToCalculate)
  }
  return []
}

func calculateBinaryExpression(_ parentExpr: Node, _ be: BinaryExpression) -> [String] {
  let lhs = calculateExpression(parentExpr, be.lhs)
  let rhs = calculateExpression(parentExpr, be.rhs)
  var ret: [String] = []
  for l in lhs { for r in rhs { ret.append(l + (be.op == .plus ? "" : "/") + r) } }
  return ret
}

func calculateExpression(_ parentExpr: Node, _ argExpression: Node) -> [String] {
  if let sl = argExpression as? StringLiteral {
    return [sl.contents()]
  } else if let be = argExpression as? BinaryExpression {
    return calculateBinaryExpression(parentExpr, be)
  } else if let me = argExpression as? MethodExpression, isValidMethod(me) {
    let objStrs = calculateExpression(parentExpr, me.obj)
    return objStrs.map({ applyMethod(varname: $0, name: (me.id as! IdExpression).id) })
  } else if let me = argExpression as? MethodExpression, let meid = me.id as? IdExpression,
    meid.id == "format", let al = me.argumentList as? ArgumentList, !al.args.isEmpty
  {
    let objStrs = calculateExpression(parentExpr, me.obj)
    let fmtStrs = calculateExpression(parentExpr, al.args[0])
    var ret: [String] = []
    for o in objStrs { for f in fmtStrs { ret.append(o.replacingOccurrences(of: "@0@", with: f)) } }
    return ret
  } else if let me = argExpression as? MethodExpression, let meobj = me.obj as? IdExpression,
    let meid = me.id as? IdExpression, meid.id == "get", let al = me.argumentList as? ArgumentList,
    !al.args.isEmpty
  {
    let nodes = resolveArrayOrDict(parentExpr, meobj)
    var ret: [String] = []
    for r in nodes {
      if let arr = r.node as? ArrayLiteral, let il = al.args[0] as? IntegerLiteral {
        let idx = il.parse()
        if idx < arr.args.count, let sl = arr.args[idx] as? StringLiteral {
          ret.append(sl.contents())
        }
      } else if let dict = r.node as? DictionaryLiteral, let keyLit = al.args[0] as? StringLiteral {
        for k in dict.values
        where (k is KeyValueItem)
          && ((k as! KeyValueItem).key as? StringLiteral)?.contents() == keyLit.contents()
        {
          if let keySL = (k as! KeyValueItem).value as? StringLiteral {
            ret.append(keySL.contents())
          }
        }
      } else if let arr = r.node as? ArrayLiteral, let sl = al.args[0] as? StringLiteral {
        for a in arr.args where a is DictionaryLiteral {
          let dict = (a as! DictionaryLiteral)
          for k in dict.values
          where (k is KeyValueItem)
            && ((k as! KeyValueItem).key as? StringLiteral)?.contents() == sl.contents()
          {
            if let keySL = (k as! KeyValueItem).value as? StringLiteral {
              ret.append(keySL.contents())
            }
          }
        }
      }
    }
    return ret
  } else if let idexpr = argExpression as? IdExpression {
    let l = resolveArrayOrDict(parentExpr, idexpr)
    var ret: [String] = []
    for v in l {
      if let sn = v.node as? StringLiteral {
        ret.append(sn.contents())
      } else if let an = v as? ArrayNode, let al = an.node as? ArrayLiteral {
        for arg in al.args { if let sl = arg as? StringLiteral { ret.append(sl.contents()) } }
      }
    }
    return ret
  } else if let sse = argExpression as? SubscriptExpression {
    let outer = abstractEval(parentExpr, sse.outer)
    let inner = abstractEval(parentExpr, sse.inner)
    var ret: [String] = []
    for o in outer {
      for i in inner {
        if let arr = o.node as? ArrayLiteral, let il = i.node as? IntegerLiteral {
          let idx = il.parse()
          if idx < arr.args.count, let sl = arr.args[idx] as? StringLiteral {
            ret.append(sl.contents())
          }
        } else if let arr = o.node as? ArrayLiteral, let sl = i.node as? StringLiteral {
          for a in arr.args where a is DictionaryLiteral {
            let dict = (a as! DictionaryLiteral)
            for k in dict.values
            where (k is KeyValueItem)
              && ((k as! KeyValueItem).key as? StringLiteral)?.contents() == sl.contents()
            {
              if let keySL = (k as! KeyValueItem).value as? StringLiteral {
                ret.append(keySL.contents())
              }
            }
          }
        } else if let dict = o.node as? DictionaryLiteral, let keyLit = i.node as? StringLiteral {
          for k in dict.values
          where (k is KeyValueItem)
            && ((k as! KeyValueItem).key as? StringLiteral)?.contents() == keyLit.contents()
          {
            if let keySL = (k as! KeyValueItem).value as? StringLiteral {
              ret.append(keySL.contents())
            }
          }
        }
      }
    }
    return ret
  }
  return []
}

func analyseBuildDefinition(_ bd: BuildDefinition, _ parentExpr: Node, _ toResolve: IdExpression)
  -> [InterpretNode]
{
  var foundOurselves = false
  var tmp: [InterpretNode] = []
  for b in bd.stmts.reversed() {
    if b.equals(right: parentExpr) {
      foundOurselves = true
      continue
    } else if foundOurselves {
      if let assignment = b as? AssignmentStatement, let lhs = assignment.lhs as? IdExpression,
        lhs.id == toResolve.id
      {
        if assignment.op == .equals {
          return abstractEval(b, assignment.rhs) + tmp
        } else {
          tmp += abstractEval(b, assignment.rhs)
        }
      } else {
        tmp += fullEval(b, toResolve)
      }
    }
  }
  return tmp
}

func analyseIterationStatement(
  _ its: IterationStatement,
  _ parentExpr: Node,
  _ toResolve: IdExpression
) -> [InterpretNode] {
  var foundOurselves = false
  var tmp: [InterpretNode] = []

  for b in its.block.reversed() {
    if b.equals(right: parentExpr) {
      foundOurselves = true
      continue
    } else if foundOurselves {
      if let assignment = b as? AssignmentStatement, let lhs = assignment.lhs as? IdExpression,
        lhs.id == toResolve.id
      {
        if assignment.op == .equals {
          return abstractEval(b, assignment.rhs) + tmp
        } else {
          tmp += abstractEval(b, assignment.rhs)
        }
      } else {
        tmp += fullEval(b, toResolve)
      }
    }
  }
  for b in its.ids {
    if let idexpr = b as? IdExpression, idexpr.id == toResolve.id {
      return abstractEval(parentExpr.parent!, its.expression) + tmp
    }
  }
  return resolveArrayOrDict(its, toResolve) + tmp
}

func analyseSelectionStatement(
  _ sst: SelectionStatement,
  _ parentExpr: Node,
  _ toResolve: IdExpression
) -> [InterpretNode] {
  var foundOurselves = false
  var tmp: [InterpretNode] = []
  for block in sst.blocks.reversed() {
    for b in block.reversed() {
      if b.equals(right: parentExpr) {
        foundOurselves = true
        continue
      } else if foundOurselves {
        if let assignment = b as? AssignmentStatement, let lhs = assignment.lhs as? IdExpression,
          lhs.id == toResolve.id
        {
          if assignment.op == .equals {
            return abstractEval(b, assignment.rhs) + tmp
          } else {
            tmp += abstractEval(b, assignment.rhs)
          }
        } else {
          tmp += fullEval(b, toResolve)
        }
      }
    }
  }
  return resolveArrayOrDict(sst, toResolve) + tmp
}

func resolveArrayOrDict(_ parentExpr: Node, _ toResolve: IdExpression) -> [InterpretNode] {
  let parent = parentExpr.parent!
  if let bd = parent as? BuildDefinition {
    return analyseBuildDefinition(bd, parentExpr, toResolve)
  } else if let its = parent as? IterationStatement {
    return analyseIterationStatement(its, parentExpr, toResolve)
  } else if let sst = parent as? SelectionStatement {
    return analyseSelectionStatement(sst, parentExpr, toResolve)
  }
  return []
}

func evalStatement(_ b: Node, _ toResolve: IdExpression) -> [InterpretNode] {
  if let ass = b as? AssignmentStatement, let lhs = ass.lhs as? IdExpression, toResolve.id == lhs.id
  {
    return abstractEval(ass, ass.rhs)
  } else {
    return fullEval(b, toResolve)
  }
}

func fullEval(_ stmt: Node, _ toResolve: IdExpression) -> [InterpretNode] {
  var ret: [InterpretNode] = []
  if let its = stmt as? BuildDefinition {
    for b in its.stmts.reversed() { ret += evalStatement(b, toResolve) }
  } else if let its = stmt as? IterationStatement {
    for b in its.block.reversed() { ret += evalStatement(b, toResolve) }
    for b in its.ids {
      if let idexpr = b as? IdExpression, idexpr.id == toResolve.id {
        ret += abstractEval(b, its.expression)
      }
    }
  } else if let sst = stmt as? SelectionStatement {
    for block in sst.blocks.reversed() {
      for b in block.reversed() { ret += evalStatement(b, toResolve) }
    }
  }
  return ret
}

func abstractEvalBinaryExpression(_ be: BinaryExpression, _ parentStmt: Node) -> [InterpretNode] {
  let rhs = abstractEval(parentStmt, be.rhs)
  let lhs = abstractEval(parentStmt, be.lhs)
  var ret: [InterpretNode] = []
  let sep = be.op == .div ? "/" : ""
  for l in lhs {
    for r in rhs {
      if let sl = l.node as? StringLiteral, let sr = r.node as? StringLiteral {
        ret.append(ArtificalStringNode(contents: sl.contents() + sep + sr.contents()))
      } else if let sl = l.node as? StringLiteral, let arrR = r.node as? ArrayLiteral {
        for arrArg in arrR.args {
          if let sr = arrArg as? StringLiteral {
            ret.append(ArtificalStringNode(contents: sl.contents() + sep + sr.contents()))
          } else if let sr2 = arrArg as? ArrayLiteral {
            for arrArg2 in sr2.args where arrArg2 is StringLiteral {
              ret.append(
                ArtificalStringNode(
                  contents: sl.contents() + sep + (arrArg2 as! StringLiteral).contents()
                )
              )
            }
          }
        }
      } else if let sl = r.node as? StringLiteral, let arrR = l.node as? ArrayLiteral {
        for arrArg in arrR.args {
          if let sr = arrArg as? StringLiteral {
            ret.append(ArtificalStringNode(contents: sr.contents() + sep + sl.contents()))
          } else if let sr2 = arrArg as? ArrayLiteral {
            for arrArg2 in sr2.args where arrArg2 is StringLiteral {
              ret.append(
                ArtificalStringNode(
                  contents: (arrArg2 as! StringLiteral).contents() + sep + sl.contents()
                )
              )
            }
          }
        }
      }
    }
  }
  return ret
}

func abstractEvalComputeSubscript(i: InterpretNode, o: InterpretNode, ret: inout [InterpretNode]) {
  if let arr = o.node as? ArrayLiteral, let idx = i.node as? IntegerLiteral,
    idx.parse() < arr.args.count
  {
    if let atIdx = arr.args[idx.parse()] as? StringLiteral {
      ret.append(StringNode(node: atIdx))
    } else if let atIdx = arr.args[idx.parse()] as? ArrayLiteral {
      for a2 in atIdx.args where a2 is StringLiteral { ret.append(StringNode(node: a2)) }
    }
  } else if let sl = i.node as? StringLiteral, let dict = o.node as? DictionaryLiteral {
    for kvi in dict.values {
      if let k = kvi as? KeyValueItem, let key = k.key as? StringLiteral,
        key.contents() == sl.contents(), let val = k.value as? StringLiteral
      {
        ret.append(StringNode(node: val))
      }
    }
  } else if let arr = o.node as? ArrayLiteral, let sl = i.node as? StringLiteral {
    for a in arr.args where a is DictionaryLiteral {
      let dict = (a as! DictionaryLiteral)
      for k in dict.values
      where (k is KeyValueItem)
        && ((k as! KeyValueItem).key as? StringLiteral)?.contents() == sl.contents()
      {
        if let keySL = (k as! KeyValueItem).value as? StringLiteral {
          ret.append(StringNode(node: keySL))
        }
      }
    }
  }
}

func abstractEvalSubscriptExpression(_ sse: SubscriptExpression, _ parentStmt: Node)
  -> [InterpretNode]
{
  let outer = abstractEval(parentStmt, sse.outer)
  let inner = abstractEval(parentStmt, sse.inner)
  var ret: [InterpretNode] = []
  for o in outer { for i in inner { abstractEvalComputeSubscript(i: i, o: o, ret: &ret) } }
  return ret
}

// For foo.split(bar)[baz]
func abstractEvalSplitWithSubscriptExpression(
  _ idx: IntegerLiteral,
  _ sl: StringLiteral,
  _ outerME: MethodExpression,
  _ parentStmt: Node
) -> [InterpretNode] {
  let objs = abstractEval(parentStmt, outerME.obj)
  var ret: [InterpretNode] = []
  let splitAt = sl.contents()
  let idxI = idx.parse()
  for o in objs {
    if let sl1 = o.node as? StringLiteral {
      let parts = sl1.contents().components(separatedBy: splitAt)
      if idxI < parts.count { ret.append(ArtificalStringNode(contents: parts[idxI])) }
    } else if let arr = o.node as? ArrayLiteral {
      for sl1 in arr.args where sl1 is StringLiteral {
        let parts = (sl1 as! StringLiteral).contents().components(separatedBy: splitAt)
        if idxI < parts.count { ret.append(ArtificalStringNode(contents: parts[idxI])) }
      }
    }
  }
  return ret
}

func abstractEvalMethod(_ me: MethodExpression, _ parentStmt: Node) -> [InterpretNode] {
  let meobj = abstractEval(parentStmt, me.obj)
  var ret: [InterpretNode] = []
  for r in meobj {
    var strValues: [String] = []
    if let arr = r.node as? ArrayLiteral {
      for a in arr.args { if let sl = a as? StringLiteral { strValues.append(sl.contents()) } }
    } else if let sl = r.node as? StringLiteral {
      strValues.append(sl.contents())
    }
    ret += Array(
      strValues.map({
        ArtificalStringNode(contents: applyMethod(varname: $0, name: (me.id as! IdExpression).id))
      })
    )
  }
  return ret
}

func abstractEvalSimpleSubscriptExpression(
  _ se: SubscriptExpression,
  _ outerObj: IdExpression,
  _ parentStmt: Node
) -> [InterpretNode] {
  let objs = resolveArrayOrDict(parentStmt, outerObj)
  var ret: [InterpretNode] = []
  for r in objs {
    if let arr = r.node as? ArrayLiteral, let idx = se.inner as? IntegerLiteral,
      idx.parse() < arr.args.count
    {
      if let atIdx = arr.args[idx.parse()] as? StringLiteral {
        ret.append(StringNode(node: atIdx))
      } else if let atIdx = arr.args[idx.parse()] as? ArrayLiteral {
        for a2 in atIdx.args where a2 is StringLiteral { ret.append(StringNode(node: a2)) }
      }
    } else if r is StringNode || r is ArtificalStringNode {
      ret.append(StringNode(node: r.node))
    } else if let sl = se.inner as? StringLiteral, let dict = r.node as? DictionaryLiteral {
      for kvi in dict.values {
        if let k = kvi as? KeyValueItem, let key = k.key as? StringLiteral,
          key.contents() == sl.contents(), let val = k.value as? StringLiteral
        {
          ret.append(StringNode(node: val))
        }
      }
    } else if let arr = r.node as? ArrayLiteral, let sl = se.inner as? StringLiteral {
      for a in arr.args where a is DictionaryLiteral {
        let dict = (a as! DictionaryLiteral)
        for k in dict.values
        where (k is KeyValueItem)
          && ((k as! KeyValueItem).key as? StringLiteral)?.contents() == sl.contents()
        {
          if let keySL = (k as! KeyValueItem).value as? StringLiteral {
            ret.append(StringNode(node: keySL))
          }
        }
      }
    }
  }
  return ret
}

func abstractEvalGetMethodCall(
  _ me: MethodExpression,
  _ meobj: IdExpression,
  _ al: ArgumentList,
  _ parentStmt: Node
) -> [InterpretNode] {
  let objs = resolveArrayOrDict(parentStmt, meobj)
  var ret: [InterpretNode] = []
  for r in objs {
    if let arr = r.node as? ArrayLiteral, let idx = al.args[0] as? IntegerLiteral,
      idx.parse() < arr.args.count
    {
      if let atIdx = arr.args[idx.parse()] as? StringLiteral { ret.append(StringNode(node: atIdx)) }
    } else if r is StringNode {
      ret.append(StringNode(node: r.node))
    } else if let sl = al.args[0] as? StringLiteral, let dict = r.node as? DictionaryLiteral {
      for kvi in dict.values {
        if let k = kvi as? KeyValueItem, let key = k.key as? StringLiteral,
          key.contents() == sl.contents(), let val = k.value as? StringLiteral
        {
          ret.append(StringNode(node: val))
        }
      }
    }
  }
  return ret
}

func abstractEvalArrayLiteral(_ al: ArrayLiteral, _ toEval: Node, _ parentStmt: Node)
  -> [InterpretNode]
{
  if !al.args.isEmpty {
    let firstArg = al.args[0]
    if firstArg is ArrayLiteral {
      return al.args.map({ ArrayNode(node: $0) })
    } else if firstArg is DictionaryLiteral {
      return al.args.map({ DictNode(node: $0) })
    } else if firstArg is IdExpression {
      return al.args.map({ resolveArrayOrDict(parentStmt, $0 as! IdExpression) }).flatMap({ $0 })
    }
  }
  return [ArrayNode(node: toEval)]
}

func abstractEvalGenericSubscriptExpression(_ se: SubscriptExpression, _ parentStmt: Node)
  -> [InterpretNode]
{
  if se.inner is IntegerLiteral || se.inner is StringLiteral,
    let outerObj = se.outer as? IdExpression
  {
    return abstractEvalSimpleSubscriptExpression(se, outerObj, parentStmt)
  } else if let idx = se.inner as? IntegerLiteral, let outerME = se.outer as? MethodExpression,
    let meid = outerME.id as? IdExpression, meid.id == "split",
    let al = outerME.argumentList as? ArgumentList, !al.args.isEmpty,
    let sl = al.args[0] as? StringLiteral
  {
    return abstractEvalSplitWithSubscriptExpression(idx, sl, outerME, parentStmt)
  }
  return abstractEvalSubscriptExpression(se, parentStmt)

}

func abstractEval(_ parentStmt: Node, _ toEval: Node) -> [InterpretNode] {
  if toEval is DictionaryLiteral {
    return [DictNode(node: toEval)]
  } else if let al = toEval as? ArrayLiteral {
    return abstractEvalArrayLiteral(al, toEval, parentStmt)
  } else if toEval is StringLiteral {
    return [StringNode(node: toEval)]
  } else if toEval is IntegerLiteral {
    return [IntNode(node: toEval)]
  } else if let be = toEval as? BinaryExpression {
    return abstractEvalBinaryExpression(be, parentStmt)
  } else if let id = toEval as? IdExpression {
    return resolveArrayOrDict(parentStmt, id)
  } else if let me = toEval as? MethodExpression, let meid = me.id as? IdExpression,
    meid.id == "get", let meobj = me.obj as? IdExpression,
    let al = me.argumentList as? ArgumentList, !al.args.isEmpty
  {
    return abstractEvalGetMethodCall(me, meobj, al, parentStmt)
  } else if let me = toEval as? MethodExpression, isValidMethod(me) {
    return abstractEvalMethod(me, parentStmt)
  } else if let ce = toEval as? ConditionalExpression {
    return abstractEval(parentStmt, ce.ifTrue) + abstractEval(parentStmt, ce.ifFalse)
  } else if let sse = toEval as? SubscriptExpression {
    return abstractEvalGenericSubscriptExpression(sse, parentStmt)
  }
  return []
}

func isValidMethod(_ me: MethodExpression) -> Bool {
  if let meid = me.id as? IdExpression {
    return ["underscorify", "to_lower", "to_upper", "strip"].contains(meid.id)
  }
  return false
}

func applyMethod(varname: String, name: String) -> String {
  switch name {
  case "underscorify":
    var res = ""
    for v in varname {
      if v.isLetter || v.isNumber {
        res.append(v)
        continue
      }
      res += "_"
    }
    return res
  case "to_lower": return varname.lowercased()
  case "to_upper": return varname.uppercased()
  case "strip": return varname.trimmingCharacters(in: .whitespacesAndNewlines)
  default: fatalError("unreachable")
  }
}

class InterpretNode {
  public let node: Node

  init(node: Node) { self.node = node }
}

class ArrayNode: InterpretNode {

}

class StringNode: InterpretNode {

}

class DictNode: InterpretNode {

}

class IntNode: InterpretNode {

}

class ArtificalStringNode: InterpretNode {

  public init(contents: String) { super.init(node: StringLiteral(contents)) }
}
