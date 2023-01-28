import Glibc
import MesonAST
import PathKit
import Timing

// TODO: Type derivation based on the options
public class TypeAnalyzer: ExtendedCodeVisitor {
  var scope: Scope
  var t: TypeNamespace?
  var tree: MesonTree
  var metadata: MesonMetadata
  let checkerState: CheckerState = CheckerState()
  let typeanalyzersState: TypeAnalyzersState = TypeAnalyzersState()
  let options: [MesonOption]
  var stack: [[String: [Type]]] = []

  public init(parent: Scope, tree: MesonTree, options: [MesonOption]) {
    self.scope = parent
    self.tree = tree
    self.t = tree.ns
    self.options = options
    self.metadata = MesonMetadata()
  }

  deinit { self.t = nil }

  public func visitSubdirCall(node: SubdirCall) {
    node.visitChildren(visitor: self)
    self.metadata.registerSubdirCall(call: node)
    let newPath = Path(
      Path(node.file.file).absolute().parent().description + "/" + node.subdirname + "/meson.build"
    ).description
    let subtree = self.tree.findSubdirTree(file: newPath)
    if let st = subtree {
      let tmptree = self.tree
      self.tree = st
      self.scope = Scope(parent: self.scope)
      subtree?.ast?.setParents()
      subtree?.ast?.parent = node
      subtree?.ast?.visit(visitor: self)
      self.tree = tmptree
    } else {
      self.metadata.registerDiagnostic(
        node: node,
        diag: MesonDiagnostic(
          sev: .error, node: node, message: "Unable to find subdir \(node.subdirname)"))
      print("Not found", node.subdirname)
    }
  }

  public func applyToStack(_ name: String, _ types: [Type]) {
    if self.stack.isEmpty { return }
    if self.stack[self.stack.count - 1][name] == nil {
      self.stack[self.stack.count - 1][name] = types
    } else {
      self.stack[self.stack.count - 1][name]! += types
    }
  }
  public func visitSourceFile(file: SourceFile) { file.visitChildren(visitor: self) }
  public func visitBuildDefinition(node: BuildDefinition) { node.visitChildren(visitor: self) }
  public func visitErrorNode(node: ErrorNode) {
    node.visitChildren(visitor: self)
    self.metadata.registerDiagnostic(
      node: node, diag: MesonDiagnostic(sev: .error, node: node, message: node.message))
  }
  public func visitSelectionStatement(node: SelectionStatement) {
    self.stack.append([:])
    node.visitChildren(visitor: self)
    let types = self.stack.removeLast()
    for k in types.keys {
      let l = dedup(types: (self.scope.variables[k] ?? []) + types[k]!)
      self.scope.variables[k] = l
    }
  }
  public func visitBreakStatement(node: BreakNode) { node.visitChildren(visitor: self) }
  public func visitContinueStatement(node: ContinueNode) { node.visitChildren(visitor: self) }
  public func visitIterationStatement(node: IterationStatement) {
    node.expression.visit(visitor: self)
    for id in node.ids { id.visit(visitor: self) }
    let iterTypes = node.expression.types
    if node.ids.count == 1 {
      if iterTypes.count > 0 && iterTypes[0] is ListType {
        node.ids[0].types = (iterTypes[0] as! ListType).types
      } else if iterTypes.count > 0 && iterTypes[0] is RangeType {
        node.ids[0].types = [self.t!.types["int"]!]
      } else {
        node.ids[0].types = [`Any`()]
      }
      self.applyToStack((node.ids[0] as! IdExpression).id, node.ids[0].types)
      self.scope.variables[(node.ids[0] as! IdExpression).id] = node.ids[0].types
      self.checkIdentifier(node.ids[0] as! IdExpression)
    } else if node.ids.count == 2 {
      node.ids[0].types = [self.t!.types["str"]!]
      if let d = iterTypes.filter({ $0 is Dict }).first {
        node.ids[1].types = (d as! Dict).types
      } else {
        node.ids[1].types = []
      }
      self.applyToStack((node.ids[1] as! IdExpression).id, node.ids[0].types)
      self.applyToStack((node.ids[1] as! IdExpression).id, node.ids[0].types)
      self.scope.variables[(node.ids[1] as! IdExpression).id] = node.ids[1].types
      self.scope.variables[(node.ids[0] as! IdExpression).id] = node.ids[0].types
      self.checkIdentifier(node.ids[0] as! IdExpression)
      self.checkIdentifier(node.ids[1] as! IdExpression)
    }
    for b in node.block { b.visit(visitor: self) }
  }

  func checkIdentifier(_ node: IdExpression) {
    let begin = clock()
    if !isSnakeCase(str: node.id) {
      // TODO: For assignments, too
      self.metadata.registerDiagnostic(
        node: node, diag: MesonDiagnostic(sev: .warning, node: node, message: "Expected snake case")
      )
    }
    Timing.INSTANCE.registerMeasurement(
      name: "checkIdentifier", begin: Int(begin), end: Int(clock()))
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
      self.applyToStack((node.lhs as! IdExpression).id, arr)
      self.scope.variables[(node.lhs as! IdExpression).id] = arr
      (node.lhs as! IdExpression).types = arr
    } else {
      var newTypes: [Type] = []
      for l in node.lhs.types {
        for r in node.rhs.types {
          switch node.op {
          case .divequals:
            if l is `IntType` && r is `IntType` {
              newTypes.append(self.t!.types["int"]!)
            } else if l is Str && r is Str {
              newTypes.append(self.t!.types["str"]!)
            }
          case .minusequals:
            if l is `IntType` && r is `IntType` { newTypes.append(self.t!.types["int"]!) }
          case .modequals:
            if l is `IntType` && r is `IntType` { newTypes.append(self.t!.types["int"]!) }
          case .mulequals:
            if l is `IntType` && r is `IntType` { newTypes.append(self.t!.types["int"]!) }
          case .plusequals:
            if l is `IntType` && r is `IntType` {
              newTypes.append(self.t!.types["int"]!)
            } else if l is Str && r is Str {
              newTypes.append(self.t!.types["str"]!)
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
      self.applyToStack((node.lhs as! IdExpression).id, deduped)
      self.scope.variables[(node.lhs as! IdExpression).id] = deduped
    }
    self.metadata.registerIdentifier(id: (node.lhs as! IdExpression))
    /*print(
      (node.lhs as! IdExpression).id, "is a",
      joinTypes(types: self.scope.variables[(node.lhs as! IdExpression).id]!))*/
  }
  public func visitFunctionExpression(node: FunctionExpression) {
    node.visitChildren(visitor: self)
    let funcName = (node.id as! IdExpression).id
    if let fn = self.t!.lookupFunction(name: funcName) {
      node.types = self.typeanalyzersState.apply(
        node: node, options: self.options, f: fn, ns: self.t!)
      node.function = fn
      self.metadata.registerFunctionCall(call: node)
      checkerState.apply(node: node, metadata: self.metadata, f: fn)
      if let args = node.argumentList, args is ArgumentList {
        self.checkCall(node: node)
      } else if node.argumentList == nil {
        if node.function!.minPosArgs() != 0 {
          self.metadata.registerDiagnostic(
            node: node,
            diag: MesonDiagnostic(
              sev: .error, node: node,
              message: "Expected " + String(node.function!.minPosArgs())
                + " positional arguments, but got none!"))
        }
      }
      if node.argumentList != nil, node.argumentList is ArgumentList {
        for a in (node.argumentList as! ArgumentList).args where a is KeywordItem {
          self.metadata.registerKwarg(item: a as! KeywordItem, f: fn)
        }
      }
    } else {
      self.metadata.registerDiagnostic(
        node: node,
        diag: MesonDiagnostic(sev: .error, node: node, message: "Unknown function \(funcName)"))
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
    case .minus: node.types = [self.t!.types["int"]!]
    case .not: node.types = [self.t!.types["bool"]!]
    case .exclamationMark: node.types = [self.t!.types["bool"]!]
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
        newTypes += [self.t!.types["str"]!]
      } else if t is CustomTgt {
        newTypes += [self.t!.types["custom_idx"]!]
      }
    }
    node.types = dedup(types: newTypes)
  }
  public func visitMethodExpression(node: MethodExpression) {
    node.visitChildren(visitor: self)
    let types = node.obj.types
    var ownResultTypes: [Type] = []
    var found = false
    let methodName = (node.id as! IdExpression).id
    for t in types {
      if let m = t.getMethod(name: methodName) {
        ownResultTypes += m.returnTypes
        node.method = m
        self.metadata.registerMethodCall(call: node)
        found = true
        checkerState.apply(node: node, metadata: self.metadata, f: m)
      }
    }
    node.types = dedup(types: ownResultTypes)
    if !found {
      let types = joinTypes(types: types)
      self.metadata.registerDiagnostic(
        node: node,
        diag: MesonDiagnostic(
          sev: .error, node: node, message: "No method \(methodName) found for types `\(types)'"))
    } else {
      if let args = node.argumentList, args is ArgumentList {
        self.checkCall(node: node)
      } else if node.argumentList == nil {
        if node.method!.minPosArgs() != 0 {
          self.metadata.registerDiagnostic(
            node: node,
            diag: MesonDiagnostic(
              sev: .error, node: node,
              message: "Expected " + String(node.method!.minPosArgs())
                + " positional arguments, but got none!"))
        }
      }
      if node.argumentList != nil, node.argumentList is ArgumentList {
        for a in (node.argumentList as! ArgumentList).args where a is KeywordItem {
          self.metadata.registerKwarg(item: a as! KeywordItem, f: node.method!)
        }
      }
    }
  }

  func checkCall(node: Expression) {
    let begin = clock()
    let args: [Node]
    let fn: Function
    if node is FunctionExpression {
      fn = (node as! FunctionExpression).function!
      args = ((node as! FunctionExpression).argumentList! as! ArgumentList).args
    } else {
      fn = (node as! MethodExpression).method!
      args = ((node as! MethodExpression).argumentList! as! ArgumentList).args
    }
    var kwargsOnly = false
    for arg in args {
      if kwargsOnly {
        if arg is KeywordItem { continue }
        self.metadata.registerDiagnostic(
          node: arg,
          diag: MesonDiagnostic(
            sev: .error, node: arg,
            message: "Unexpected positional argument after a keyword argument"))
        continue
      } else if arg is KeywordItem {
        kwargsOnly = true
      }
    }
    var nKwargs = 0
    var nPos = 0
    for arg in args { if arg is Kwarg { nKwargs += 1 } else { nPos += 1 } }
    if nPos < fn.minPosArgs() {
      self.metadata.registerDiagnostic(
        node: node,
        diag: MesonDiagnostic(
          sev: .error, node: node,
          message: "Expected " + String(fn.minPosArgs()) + " positional arguments, but got "
            + String(nPos) + "!"))
    }
    var usedKwargs: [String: KeywordItem] = [:]
    for arg in args where arg is KeywordItem {
      let k = (arg as! KeywordItem).key
      if let kId = k as? IdExpression {
        usedKwargs[kId.id] = (arg as! KeywordItem)
        if !fn.hasKwarg(name: kId.id) {
          self.metadata.registerDiagnostic(
            node: arg,
            diag: MesonDiagnostic(
              sev: .error, node: arg, message: "Unknown key word argument '" + kId.id + "'!"))
        }
      }
    }
    for requiredKwarg in fn.requiredKwargs() where usedKwargs[requiredKwarg] == nil {
      self.metadata.registerDiagnostic(
        node: node,
        diag: MesonDiagnostic(
          sev: .error, node: node,
          message: "Missing required key word argument '" + requiredKwarg + "'!"))
    }
    Timing.INSTANCE.registerMeasurement(name: "checkCall", begin: Int(begin), end: Int(clock()))
  }
  public func visitIdExpression(node: IdExpression) {
    node.types = dedup(types: scope.variables[node.id] ?? [])
    node.visitChildren(visitor: self)
    if (node.parent is FunctionExpression
      && (node.parent as! FunctionExpression).id.equals(right: node))
      || (node.parent is MethodExpression
        && (node.parent as! MethodExpression).id.equals(right: node))
    {
      return
    } else if node.parent is KeywordItem && (node.parent as! KeywordItem).key.equals(right: node) {
      return
    }
    if node.id != "break" && node.id != "continue" && !isKnownId(id: node) {
      self.metadata.registerDiagnostic(
        node: node, diag: MesonDiagnostic(sev: .error, node: node, message: "Unknown identifier"))
    }
    if node.id != "break" && node.id != "continue" { self.metadata.registerIdentifier(id: node) }
  }

  func isKnownId(id: IdExpression) -> Bool {
    if let a = id.parent as? AssignmentStatement, let b = a.lhs as? IdExpression {
      if b.id == id.id && a.op == .equals { return true }
    } else if let i = id.parent as? IterationStatement {
      for idd in i.ids { if let l = idd as? IdExpression, id.id == l.id { return true } }
    } else if let kw = id.parent as? KeywordItem, let b = kw.key as? IdExpression {
      if id.id == b.id { return true }
    } else if let fe = id.parent as? FunctionExpression, let b = fe.id as? IdExpression {
      if id.id == b.id { return true }
    } else if let me = id.parent as? MethodExpression, let b = me.id as? IdExpression {
      if id.id == b.id { return true }
    }

    return self.scope.variables[id.id] != nil
  }
  public func visitBinaryExpression(node: BinaryExpression) {
    node.visitChildren(visitor: self)
    var newTypes: [Type] = []
    if node.op == nil {
      // Emergency fix
      node.types = dedup(types: node.lhs.types + node.rhs.types)
      self.metadata.registerDiagnostic(
        node: node,
        diag: MesonDiagnostic(sev: .error, node: node, message: "Missing binary operator"))
      return
    }
    for l in node.lhs.types {
      for r in node.rhs.types {
        switch node.op! {
        case .and: newTypes.append(self.t!.types["bool"]!)
        case .div:
          if l is `IntType` && r is `IntType` {
            newTypes.append(self.t!.types["int"]!)
          } else if l is Str && r is Str {
            newTypes.append(self.t!.types["str"]!)
          }
        case .equalsEquals: newTypes.append(self.t!.types["bool"]!)
        case .ge: newTypes.append(self.t!.types["bool"]!)
        case .gt: newTypes.append(self.t!.types["bool"]!)
        case .IN: newTypes.append(self.t!.types["bool"]!)
        case .le: newTypes.append(self.t!.types["bool"]!)
        case .lt: newTypes.append(self.t!.types["bool"]!)
        case .minus: if l is `IntType` && r is `IntType` { newTypes.append(self.t!.types["int"]!) }
        case .modulo: if l is `IntType` && r is `IntType` { newTypes.append(self.t!.types["int"]!) }
        case .mul: if l is `IntType` && r is `IntType` { newTypes.append(self.t!.types["int"]!) }
        case .notEquals: newTypes.append(self.t!.types["bool"]!)
        case .notIn: newTypes.append(self.t!.types["bool"]!)
        case .or: newTypes.append(self.t!.types["bool"]!)
        case .plus:
          if l is `IntType` && r is `IntType` {
            newTypes.append(self.t!.types["int"]!)
          } else if l is Str && r is Str {
            newTypes.append(self.t!.types["str"]!)
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
    node.types = [self.t!.types["str"]!]
    node.visitChildren(visitor: self)
  }
  public func visitArrayLiteral(node: ArrayLiteral) {
    node.visitChildren(visitor: self)
    var t: [Type] = []
    for elem in node.args { t += elem.types }
    node.types = [ListType(types: dedup(types: t))]
  }
  public func visitBooleanLiteral(node: BooleanLiteral) {
    node.types = [self.t!.types["bool"]!]
    node.visitChildren(visitor: self)
  }
  public func visitIntegerLiteral(node: IntegerLiteral) {
    node.types = [self.t!.types["int"]!]
    node.visitChildren(visitor: self)
  }
  public func visitDictionaryLiteral(node: DictionaryLiteral) {
    node.visitChildren(visitor: self)
    var t: [Type] = []
    for elem in node.values { t += elem.types }
    node.types = [Dict(types: dedup(types: t))]
  }
  public func visitKeyValueItem(node: KeyValueItem) {
    node.visitChildren(visitor: self)
    node.types = node.value.types
  }

  func isSnakeCase(str: String) -> Bool {
    for s in str where s.isUppercase { return false }
    return true
  }

  public func joinTypes(types: [Type]) -> String {
    return types.map({ $0.toString() }).joined(separator: "|")
  }

  public func dedup(types: [Type]) -> [Type] {
    if types.count <= 0 { return types }
    var listtypes: [Type] = []
    var dicttypes: [Type] = []
    var hasAny: Bool = false
    var hasBool: Bool = false
    var hasInt: Bool = false
    var hasStr: Bool = false
    var objs: [String: Type] = [:]
    var gotList: Bool = false
    var gotDict: Bool = false
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
        gotDict = true
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
    if dicttypes.count != 0 || gotDict { ret.append(Dict(types: dedup(types: dicttypes))) }
    if hasAny { ret.append(self.t!.types["any"]!) }
    if hasBool { ret.append(self.t!.types["bool"]!) }
    if hasInt { ret.append(self.t!.types["int"]!) }
    if hasStr { ret.append(self.t!.types["str"]!) }
    ret += objs.values
    return ret
  }
}
