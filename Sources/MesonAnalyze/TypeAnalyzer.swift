import MesonAST

// TODO: Type derivation based on the options
public class TypeAnalyzer: ExtendedCodeVisitor {
  var scope: Scope
  var t: TypeNamespace = TypeNamespace()
  var tree: MesonTree
  var metadata: MesonMetadata

  public init(parent: Scope, tree: MesonTree) {
    self.scope = parent
    self.tree = tree
    self.metadata = MesonMetadata()
  }

  public func visitSubdirCall(node: SubdirCall) {
    node.visitChildren(visitor: self)
    self.metadata.registerSubdirCall(call: node)
    let subtree = self.tree.findSubdirTree(
      file: node.file.file + "/../" + node.subdirname + "/meson.build")
    if let st = subtree {
      let tmptree = self.tree
      self.tree = st
      self.scope = Scope(parent: self.scope)
      subtree?.ast?.setParents()
      subtree?.ast?.parent = node
      subtree?.ast?.visit(visitor: self)
      self.tree = tmptree
    }
  }
  public func visitSourceFile(file: SourceFile) { file.visitChildren(visitor: self) }
  public func visitBuildDefinition(node: BuildDefinition) { node.visitChildren(visitor: self) }
  public func visitErrorNode(node: ErrorNode) { node.visitChildren(visitor: self) }
  public func visitSelectionStatement(node: SelectionStatement) {
    node.visitChildren(visitor: self)
  }
  public func visitBreakStatement(node: BreakNode) { node.visitChildren(visitor: self) }
  public func visitContinueStatement(node: ContinueNode) { node.visitChildren(visitor: self) }
  public func visitIterationStatement(node: IterationStatement) {
    node.expression.visit(visitor: self)
    let tmp = self.scope
    let iterTypes = node.expression.types
    let childScope = Scope(parent: self.scope)
    if node.ids.count == 1 {
      if iterTypes.count > 0 && iterTypes[0] is ListType {
        node.ids[0].types = (iterTypes[0] as! ListType).types
      } else if iterTypes.count > 0 && iterTypes[0] is Range {
        node.ids[0].types = [`IntType`()]
      } else {
        node.ids[0].types = [`Any`()]
      }
      childScope.variables[(node.ids[0] as! IdExpression).id] = node.ids[0].types
    } else if node.ids.count == 2 {
      node.ids[0].types = [Str()]
      node.ids[1].types = iterTypes
      childScope.variables[(node.ids[1] as! IdExpression).id] = node.ids[1].types
      childScope.variables[(node.ids[0] as! IdExpression).id] = node.ids[0].types
    }
    self.scope = childScope
    for b in node.block { b.visit(visitor: self) }
    tmp.merge(other: self.scope)
    self.scope = tmp
  }
  public func visitAssignmentStatement(node: AssignmentStatement) {
    node.visitChildren(visitor: self)
    if node.op == .equals {
      var arr = node.rhs.types
      if arr.isEmpty && node.rhs is ArrayLiteral && (node.rhs as! ArrayLiteral).args.isEmpty {
        arr = [ListType(types: [])]
      }
      if arr.isEmpty && node.rhs is DictionaryLiteral
        && (node.rhs as! DictionaryLiteral).values.isEmpty
      {
        arr = [Dict(types: [])]
      }
      self.scope.variables[(node.lhs as! IdExpression).id] = arr
      (node.lhs as! IdExpression).types = arr
    } else {
      var newTypes: [Type] = []
      for l in node.lhs.types {
        for r in node.rhs.types {
          switch node.op {
          case .divequals:
            if l is `IntType` && r is `IntType` {
              newTypes.append(`IntType`())
            } else if l is Str && r is Str {
              newTypes.append(Str())
            }
          case .minusequals: if l is `IntType` && r is `IntType` { newTypes.append(`IntType`()) }
          case .modequals: if l is `IntType` && r is `IntType` { newTypes.append(`IntType`()) }
          case .mulequals: if l is `IntType` && r is `IntType` { newTypes.append(`IntType`()) }
          case .plusequals:
            if l is `IntType` && r is `IntType` {
              newTypes.append(`IntType`())
            } else if l is Str && r is Str {
              newTypes.append(Str())
            } else if l is ListType && r is ListType {
              newTypes.append(
                ListType(types: dedup(types: (l as! ListType).types + (r as! ListType).types)))
            } else if l is ListType {
              newTypes.append(ListType(types: dedup(types: (l as! ListType).types + [r])))
            } else if l is Dict && r is Dict {
              newTypes.append(Dict(types: dedup(types: (l as! Dict).types + (r as! Dict).types)))
            } else if l is Dict {
              newTypes.append(Dict(types: dedup(types: (l as! Dict).types + [r])))
            }
          default: _ = 1
          }
        }
      }
      var deduped = dedup(types: newTypes)
      if deduped.isEmpty {
        if node.rhs.types.count == 0 && self.scope.variables[(node.lhs as! IdExpression).id] != nil
          && self.scope.variables[(node.lhs as! IdExpression).id]!.count != 0
        {
          deduped = dedup(types: self.scope.variables[(node.lhs as! IdExpression).id]!)
        }
      }
      (node.lhs as! IdExpression).types = deduped
      self.scope.variables[(node.lhs as! IdExpression).id] = deduped
    }
    self.metadata.registerIdentifier(id: (node.lhs as! IdExpression))
    print(
      (node.lhs as! IdExpression).id, "is a",
      joinTypes(types: self.scope.variables[(node.lhs as! IdExpression).id]!))
  }
  public func visitFunctionExpression(node: FunctionExpression) {
    node.visitChildren(visitor: self)
    if let fn = self.t.lookupFunction(name: (node.id as! IdExpression).id) {
      node.types = fn.returnTypes
      node.function = fn
      self.metadata.registerFunctionCall(call: node)
    }
  }
  public func visitArgumentList(node: ArgumentList) { node.visitChildren(visitor: self) }
  public func visitKeywordItem(node: KeywordItem) { node.visitChildren(visitor: self) }
  public func visitConditionalExpression(node: ConditionalExpression) {
    node.visitChildren(visitor: self)
    node.types = dedup(types: node.ifFalse.types + node.ifTrue.types)
  }
  public func visitUnaryExpression(node: UnaryExpression) {
    node.visitChildren(visitor: self)
    switch node.op! {
    case .minus: node.types = [`IntType`()]
    case .not: node.types = [BoolType()]
    case .exclamationMark: node.types = [BoolType()]
    }
  }
  public func visitSubscriptExpression(node: SubscriptExpression) {
    node.visitChildren(visitor: self)
    var newTypes: [Type] = []
    for t in node.outer.types {
      if t is Dict {
        newTypes += (t as! Dict).types
      } else if t is ListType {
        newTypes += (t as! ListType).types
      } else if t is Str {
        newTypes += [Str()]
      }
    }
    node.types = dedup(types: newTypes)
  }
  public func visitMethodExpression(node: MethodExpression) {
    node.visitChildren(visitor: self)
    let types = node.obj.types
    var ownResultTypes: [Type] = []
    for t in types {
      if let m = t.getMethod(name: (node.id as! IdExpression).id) {
        ownResultTypes += m.returnTypes
        node.method = m
        self.metadata.registerMethodCall(call: node)
      }
    }
    node.types = dedup(types: ownResultTypes)
  }
  public func visitIdExpression(node: IdExpression) {
    node.types = dedup(types: scope.variables[node.id] ?? [])
    node.visitChildren(visitor: self)
    self.metadata.registerIdentifier(id: node)
  }
  public func visitBinaryExpression(node: BinaryExpression) {
    node.visitChildren(visitor: self)
    var newTypes: [Type] = []
    for l in node.lhs.types {
      for r in node.rhs.types {
        switch node.op! {
        case .and: newTypes.append(BoolType())
        case .div:
          if l is `IntType` && r is `IntType` {
            newTypes.append(`IntType`())
          } else if l is Str && r is Str {
            newTypes.append(Str())
          }
        case .equalsEquals: newTypes.append(BoolType())
        case .ge: newTypes.append(BoolType())
        case .gt: newTypes.append(BoolType())
        case .IN: newTypes.append(BoolType())
        case .le: newTypes.append(BoolType())
        case .lt: newTypes.append(BoolType())
        case .minus: if l is `IntType` && r is `IntType` { newTypes.append(`IntType`()) }
        case .modulo: if l is `IntType` && r is `IntType` { newTypes.append(`IntType`()) }
        case .mul: if l is `IntType` && r is `IntType` { newTypes.append(`IntType`()) }
        case .notEquals: newTypes.append(BoolType())
        case .notIn: newTypes.append(BoolType())
        case .or: newTypes.append(BoolType())
        case .plus:
          if l is `IntType` && r is `IntType` {
            newTypes.append(`IntType`())
          } else if l is Str && r is Str {
            newTypes.append(Str())
          } else if l is ListType && r is ListType {
            newTypes.append(
              ListType(types: dedup(types: (l as! ListType).types + (r as! ListType).types)))
          } else if l is ListType {
            newTypes.append(ListType(types: dedup(types: (l as! ListType).types + [r])))
          } else if l is Dict && r is Dict {
            newTypes.append(Dict(types: dedup(types: (l as! Dict).types + (r as! Dict).types)))
          } else if l is Dict {
            newTypes.append(Dict(types: dedup(types: (l as! Dict).types + [r])))
          }
        }
      }
    }
    node.types = dedup(types: newTypes)
  }
  public func visitStringLiteral(node: StringLiteral) {
    node.types = [Str()]
    node.visitChildren(visitor: self)
  }
  public func visitArrayLiteral(node: ArrayLiteral) {
    node.visitChildren(visitor: self)
    var t: [Type] = []
    for elem in node.args { t += elem.types }
    node.types = [ListType(types: dedup(types: t))]
  }
  public func visitBooleanLiteral(node: BooleanLiteral) {
    node.types = [BoolType()]
    node.visitChildren(visitor: self)
  }
  public func visitIntegerLiteral(node: IntegerLiteral) {
    node.types = [`IntType`()]
    node.visitChildren(visitor: self)
  }
  public func visitDictionaryLiteral(node: DictionaryLiteral) {
    node.visitChildren(visitor: self)
    var t: [Type] = []
    for elem in node.values { t += elem.types }
    node.types = dedup(types: t)
  }
  public func visitKeyValueItem(node: KeyValueItem) {
    node.visitChildren(visitor: self)
    node.types = node.value.types
  }

  public func joinTypes(types: [Type]) -> String {
    return types.map({ $0.toString() }).joined(separator: "|")
  }
}
public func dedup(types: [Type]) -> [Type] {
  var listtypes: [Type] = []
  var dicttypes: [Type] = []
  var hasAny: Bool = false
  var hasBool: Bool = false
  var hasInt: Bool = false
  var hasStr: Bool = false
  var objs: [String: Type] = [:]
  var gotList: Bool = false
  for t in types {
    if t is `Any` { hasAny = true }
    if t is BoolType {
      hasBool = true
    } else if t is `IntType` {
      hasInt = true
    } else if t is Str {
      hasStr = true
    } else if t is Dict {
      dicttypes += (t as! Dict).types
    } else if t is ListType {
      listtypes += (t as! ListType).types
      gotList = true
    } else if t is `Void` {
      // Do nothing
    } else {
      objs[t.name] = t
    }
  }
  var ret: [Type] = []
  if listtypes.count != 0 || gotList { ret.append(ListType(types: dedup(types: listtypes))) }
  if dicttypes.count != 0 { ret.append(Dict(types: dedup(types: dicttypes))) }
  if hasAny { ret.append(`Any`()) }
  if hasBool { ret.append(`BoolType`()) }
  if hasInt { ret.append(`IntType`()) }
  if hasStr { ret.append(Str()) }
  ret += objs.values
  return ret
}
