import Glibc
import Logging
import MesonAST
import PathKit
import Timing

public final class TypeAnalyzer: ExtendedCodeVisitor {
  static let LOG = Logger(label: "MesonAnalyze::TypeAnalyzer")
  static let ITERATION_DICT_VAR_COUNT = 2
  static let GET_SET_VARIABLE_ARG_COUNT_MAX = 2
  var scope: Scope
  var t: TypeNamespace
  var tree: MesonTree
  var metadata: MesonMetadata
  let checkerState: CheckerState = CheckerState()
  let typeanalyzersState: TypeAnalyzersState = TypeAnalyzersState()
  let options: [MesonOption]
  var stack: [[String: [Type]]] = []
  var overriddenVariables: [[String: [Type]]] = []

  public init(parent: Scope, tree: MesonTree, options: [MesonOption]) {
    self.scope = parent
    self.tree = tree
    self.t = tree.ns
    self.options = options
    self.metadata = MesonMetadata()
  }

  public func visitSubdirCall(node: SubdirCall) {
    let begin = clock()
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
      st.ast?.setParents()
      st.ast?.parent = node
      st.ast?.visit(visitor: self)
      self.tree = tmptree
    } else {
      self.metadata.registerDiagnostic(
        node: node,
        diag: MesonDiagnostic(
          sev: .error,
          node: node,
          message: "Unable to find subdir \(node.subdirname)"
        )
      )
      TypeAnalyzer.LOG.warning("Not found: \(node.subdirname)")
    }
    Timing.INSTANCE.registerMeasurement(name: "visitSubdirCall", begin: begin, end: clock())
  }

  public func applyToStack(_ name: String, _ types: [Type]) {
    if self.stack.isEmpty { return }
    let begin = clock()
    if self.scope.variables[name] != nil {
      let orVCount = self.overriddenVariables.count - 1
      if self.overriddenVariables[orVCount][name] == nil {
        self.overriddenVariables[orVCount][name] = self.scope.variables[name]!
      } else {
        self.overriddenVariables[orVCount][name]! += self.scope.variables[name]!
      }
    }
    let ssC = self.stack.count - 1
    if self.stack[ssC][name] == nil {
      self.stack[ssC][name] = types
    } else {
      self.stack[ssC][name]! += types
    }
    Timing.INSTANCE.registerMeasurement(name: "applyToStack", begin: begin, end: clock())
  }
  public func visitSourceFile(file: SourceFile) { file.visitChildren(visitor: self) }
  public func visitBuildDefinition(node: BuildDefinition) { node.visitChildren(visitor: self) }
  public func visitErrorNode(node: ErrorNode) {
    node.visitChildren(visitor: self)
    self.metadata.registerDiagnostic(
      node: node,
      diag: MesonDiagnostic(sev: .error, node: node, message: node.message)
    )
  }
  public func visitSelectionStatement(node: SelectionStatement) {
    let begin1 = clock()
    self.stack.append([:])
    self.overriddenVariables.append([:])
    var oldVars: [String: [Type]] = [:]
    self.scope.variables.forEach({ oldVars[$0.key] = Array($0.value) })
    node.visitChildren(visitor: self)
    for condition in [node.ifCondition] + node.conditions {
      var foundBoolOrAny = false
      for t in condition.types where t is `Any` || t is BoolType {
        foundBoolOrAny = true
        break
      }
      if !foundBoolOrAny {
        self.metadata.registerDiagnostic(
          node: condition,
          diag: MesonDiagnostic(sev: .error, node: condition, message: "Condition is not bool")
        )
      }
    }
    let begin = clock()
    let types = self.stack.removeLast()
    // If: 1 c, 1 b
    // If,else if: 2c, 2b
    // if, else if, else, 2c, 3b
    for k in types.keys {
      // TODO: This leaks some overwritten types
      // x = 'Foo'
      // if bar
      //   x = 2
      // else
      //   x = true
      // endif
      // x is now str|int|bool instead of int|bool
      var arr = (self.scope.variables[k] ?? []) + types[k]!
      if node.conditions.count + 1 == node.blocks.count { arr += (oldVars[k] ?? []) }
      let l = dedup(types: arr)
      self.scope.variables[k] = l
    }
    self.overriddenVariables.removeLast()
    Timing.INSTANCE.registerMeasurement(
      name: "SelectionStatementTypeMerge",
      begin: begin,
      end: clock()
    )
    Timing.INSTANCE.registerMeasurement(
      name: "visitSelectionStatement",
      begin: begin1,
      end: clock()
    )
  }
  public func visitBreakStatement(node: BreakNode) { node.visitChildren(visitor: self) }
  public func visitContinueStatement(node: ContinueNode) { node.visitChildren(visitor: self) }
  public func visitIterationStatement(node: IterationStatement) {
    let begin = clock()
    node.expression.visit(visitor: self)
    for id in node.ids { id.visit(visitor: self) }
    let iterTypes = node.expression.types
    if node.ids.count == 1 {
      var res: [Type] = []
      var errs = 0
      var foundDict = false
      for l in iterTypes {
        if l is RangeType {
          res.append(self.t.types["int"]!)
        } else if let lt = l as? ListType {
          res += lt.types
        } else {
          if l is Dict { foundDict = true }
          errs += 1
        }
      }
      if errs != iterTypes.count {
        node.ids[0].types = res
      } else {
        node.ids[0].types = []
        self.metadata.registerDiagnostic(
          node: node.expression,
          diag: MesonDiagnostic(
            sev: .error,
            node: node.expression,
            message: foundDict
              ? "Iterating over a dict requires two identifiers"
              : "Expression yields no iterable result"
          )
        )
      }
      if let id0Expr = (node.ids[0] as? IdExpression) {
        self.applyToStack(id0Expr.id, node.ids[0].types)
        self.scope.variables[id0Expr.id] = node.ids[0].types
        self.checkIdentifier(id0Expr)
      }
    } else if node.ids.count == TypeAnalyzer.ITERATION_DICT_VAR_COUNT {
      node.ids[0].types = [self.t.types["str"]!]
      if let dd = iterTypes.filter({ $0 is Dict }).first, let ddd = dd as? Dict {
        node.ids[1].types = ddd.types
      } else {
        node.ids[1].types = []
        self.metadata.registerDiagnostic(
          node: node.expression,
          diag: MesonDiagnostic(
            sev: .error,
            node: node.expression,
            message: iterTypes.filter({ $0 is ListType || $0 is RangeType }).first != nil
              ? "Iterating over a list/range requires one identifier"
              : "Expression yields no iterable result"
          )
        )
      }
      if let id0Expr = (node.ids[0] as? IdExpression), let id1Expr = (node.ids[1] as? IdExpression)
      {
        self.applyToStack(id1Expr.id, node.ids[1].types)
        self.applyToStack(id0Expr.id, node.ids[0].types)
        self.scope.variables[id1Expr.id] = node.ids[1].types
        self.scope.variables[id0Expr.id] = node.ids[0].types
        self.checkIdentifier(id0Expr)
        self.checkIdentifier(id1Expr)
      }
    }
    for b in node.block { b.visit(visitor: self) }
    Timing.INSTANCE.registerMeasurement(name: "visitIterationStatement", begin: begin, end: clock())
  }

  func checkIdentifier(_ node: IdExpression) {
    let begin = clock()
    if !isSnakeCase(str: node.id) {
      self.metadata.registerDiagnostic(
        node: node,
        diag: MesonDiagnostic(sev: .warning, node: node, message: "Expected snake case")
      )
    }
    Timing.INSTANCE.registerMeasurement(
      name: "checkIdentifier",
      begin: Int(begin),
      end: Int(clock())
    )
  }

  // swiftlint:disable cyclomatic_complexity
  func evalAssignment(_ op: AssignmentOperator, _ lhs: [Type], _ rhs: [Type]) -> [Type]? {
    var newTypes: [Type] = []
    for l in lhs {
      for r in rhs {
        switch op {
        case .divequals:
          if l is `IntType` && r is `IntType` {
            newTypes.append(self.t.types["int"]!)
          } else if l is Str && r is Str {
            newTypes.append(self.t.types["str"]!)
          }
        case .minusequals:
          if l is `IntType` && r is `IntType` { newTypes.append(self.t.types["int"]!) }
        case .modequals:
          if l is `IntType` && r is `IntType` { newTypes.append(self.t.types["int"]!) }
        case .mulequals:
          if l is `IntType` && r is `IntType` { newTypes.append(self.t.types["int"]!) }
        case .plusequals:
          if l is `IntType` && r is `IntType` {
            newTypes.append(self.t.types["int"]!)
          } else if l is Str && r is Str {
            newTypes.append(self.t.types["str"]!)
          } else if let ll = l as? ListType, let lr = r as? ListType {
            newTypes.append(ListType(types: dedup(types: ll.types + lr.types)))
          } else if let ll = l as? ListType {
            newTypes.append(ListType(types: dedup(types: ll.types + [r])))
          } else if let dl = l as? Dict, let dr = r as? Dict {
            newTypes.append(Dict(types: dedup(types: dl.types + dr.types)))
          } else if let dl = l as? Dict {
            newTypes.append(Dict(types: dedup(types: dl.types + [r])))
          }
        default: _ = 1
        }
      }
    }
    return newTypes.isEmpty ? nil : newTypes
  }
  // swiftlint:enable cyclomatic_complexity
  public func visitAssignmentStatement(node: AssignmentStatement) {
    let begin = clock()
    node.visitChildren(visitor: self)
    if !(node.lhs is IdExpression) {
      self.metadata.registerDiagnostic(
        node: node.lhs,
        diag: MesonDiagnostic(sev: .error, node: node.lhs, message: "Can only assign to variables")
      )
      Timing.INSTANCE.registerMeasurement(
        name: "visitAssignmentStatement",
        begin: begin,
        end: clock()
      )
      return
    }
    guard let lhsIdExpr = node.lhs as? IdExpression else { return }
    if node.op == .equals {
      var arr = node.rhs.types
      if arr.isEmpty, let arrLit = node.rhs as? ArrayLiteral, arrLit.args.isEmpty {
        arr = [ListType(types: [])]
      }
      if arr.isEmpty, let dictLit = node.rhs as? DictionaryLiteral, dictLit.values.isEmpty {
        arr = [Dict(types: [])]
      }
      lhsIdExpr.types = arr
      self.checkIdentifier(lhsIdExpr)
      self.applyToStack(lhsIdExpr.id, arr)
      self.scope.variables[lhsIdExpr.id] = arr
    } else {
      let newTypes = evalAssignment(node.op!, node.lhs.types, node.rhs.types)
      var deduped = dedup(types: newTypes == nil ? node.lhs.types : newTypes!)
      if deduped.isEmpty && node.rhs.types.isEmpty && self.scope.variables[lhsIdExpr.id] != nil
        && !self.scope.variables[lhsIdExpr.id]!.isEmpty
      {
        deduped = dedup(types: self.scope.variables[lhsIdExpr.id]!)
      }
      if newTypes == nil {
        self.metadata.registerDiagnostic(
          node: node,
          diag: MesonDiagnostic(
            sev: .error,
            node: node,
            message:
              "Unable to apply operator `\(node.op!)` to types \(self.joinTypes(types: node.lhs.types)) and \(self.joinTypes(types: node.rhs.types))"
          )
        )
      }
      lhsIdExpr.types = deduped
      self.applyToStack(lhsIdExpr.id, deduped)
      self.scope.variables[lhsIdExpr.id] = deduped
    }
    self.metadata.registerIdentifier(id: lhsIdExpr)
    let asStr = self.scope.variables[lhsIdExpr.id]!.map({ $0.toString() }).sorted().joined(
      separator: "|"
    )
    TypeAnalyzer.LOG.trace("\(lhsIdExpr.id) = \(asStr)")
    Timing.INSTANCE.registerMeasurement(
      name: "visitAssignmentStatement",
      begin: begin,
      end: clock()
    )
  }
  func specialFunctionCallHandling(_ node: FunctionExpression, _ fn: Function) {
    if fn.name == "get_variable" && node.argumentList != nil,
      let al = node.argumentList as? ArgumentList
    {
      let args = al.args
      if !args.isEmpty, let sl = args[0] as? StringLiteral {
        let varname = sl.contents()
        var types: [Type] = []
        if let sv = self.scope.variables[varname] {
          types += sv
        } else {
          types.append(self.t.types["any"]!)
        }
        if args.count >= TypeAnalyzer.GET_SET_VARIABLE_ARG_COUNT_MAX { types += args[1].types }
        node.types = types
        TypeAnalyzer.LOG.info("get_variable: \(varname) = \(self.joinTypes(types: types))")
      } else if !args.isEmpty {
        var types: [Type] = [self.t.types["any"]!]
        if args.count >= TypeAnalyzer.GET_SET_VARIABLE_ARG_COUNT_MAX { types += args[1].types }
        node.types = self.dedup(types: types)
        TypeAnalyzer.LOG.info("get_variable (Imprecise): ??? = \(self.joinTypes(types: types))")
      }
    } else if fn.name == "subdir" && node.argumentList != nil,
      let al = node.argumentList as? ArgumentList
    {
      if let sl = al.args[0] as? StringLiteral {
        let s = sl.contents()
        self.metadata.registerDiagnostic(
          node: node,
          diag: MesonDiagnostic(sev: .error, node: node, message: s + "/meson.build not found")
        )
      }
    }
  }
  public func visitFunctionExpression(node: FunctionExpression) {
    let begin = clock()
    node.visitChildren(visitor: self)
    guard let funcNameId = node.id as? IdExpression else { return }
    let funcName = funcNameId.id
    if let fn = self.t.lookupFunction(name: funcName) {
      node.types = self.typeanalyzersState.apply(
        node: node,
        options: self.options,
        f: fn,
        ns: self.t
      )
      self.specialFunctionCallHandling(node, fn)
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
              sev: .error,
              node: node,
              message: "Expected " + String(node.function!.minPosArgs())
                + " positional arguments, but got none!"
            )
          )
        }
      }
      if node.argumentList != nil, let al = node.argumentList as? ArgumentList {
        for a in al.args where a is KeywordItem {
          self.metadata.registerKwarg(item: a as! KeywordItem, f: fn)
        }
        if node.function!.name == "set_variable" {
          let args = al.args
          if !args.isEmpty, let sl = args[0] as? StringLiteral {
            let varname = sl.contents()
            let types = args[1].types
            self.scope.variables[varname] = types
            self.applyToStack(varname, types)
            TypeAnalyzer.LOG.info("set_variable: \(varname) = \(self.joinTypes(types: types))")
          }
        }
      }
    } else {
      self.metadata.registerDiagnostic(
        node: node,
        diag: MesonDiagnostic(sev: .error, node: node, message: "Unknown function \(funcName)")
      )
    }
    Timing.INSTANCE.registerMeasurement(name: "visitFunctionExpression", begin: begin, end: clock())
  }
  public func visitArgumentList(node: ArgumentList) { node.visitChildren(visitor: self) }
  public func visitKeywordItem(node: KeywordItem) { node.visitChildren(visitor: self) }
  public func visitConditionalExpression(node: ConditionalExpression) {
    node.visitChildren(visitor: self)
    node.types = dedup(types: node.ifFalse.types + node.ifTrue.types)
    for t in node.condition.types where t is `Any` || t is BoolType { return }
    self.metadata.registerDiagnostic(
      node: node,
      diag: MesonDiagnostic(sev: .error, node: node, message: "Condition is not bool")
    )
  }
  public func visitUnaryExpression(node: UnaryExpression) {
    node.visitChildren(visitor: self)
    switch node.op! {
    case .minus: node.types = [self.t.types["int"]!]
    case .not, .exclamationMark: node.types = [self.t.types["bool"]!]
    }
  }
  public func visitSubscriptExpression(node: SubscriptExpression) {
    node.visitChildren(visitor: self)
    var newTypes: [Type] = []
    for t in node.outer.types {
      if let d = t as? Dict {
        newTypes += d.types
      } else if let lt = t as? ListType {
        newTypes += lt.types
      } else if t is Str {
        newTypes += [self.t.types["str"]!]
      } else if t is CustomTgt {
        newTypes += [self.t.types["custom_idx"]!]
      }
    }
    node.types = dedup(types: newTypes)
  }
  // swiftlint:disable cyclomatic_complexity
  public func visitMethodExpression(node: MethodExpression) {
    let begin = clock()
    node.visitChildren(visitor: self)
    let types = node.obj.types
    var ownResultTypes: [Type] = []
    var found = false
    guard let methodNameId = node.id as? IdExpression else { return }
    let methodName = methodNameId.id
    var nAny = 0
    for t in types {
      if t is `Any` {
        nAny += 1
        continue
      }
      if let m = t.getMethod(name: methodName, ns: self.t) {
        ownResultTypes += self.typeanalyzersState.apply(
          node: node,
          options: self.options,
          f: m,
          ns: self.t
        )
        node.method = m
        self.metadata.registerMethodCall(call: node)
        found = true
        checkerState.apply(node: node, metadata: self.metadata, f: m)
      }
    }
    node.types = dedup(types: ownResultTypes)
    if !found && nAny == types.count {
      let begin = clock()
      let guessedMethod = self.t.lookupMethod(name: methodName)
      Timing.INSTANCE.registerMeasurement(name: "guessingMethod", begin: begin, end: clock())
      if let guessedM = guessedMethod {
        TypeAnalyzer.LOG.info(
          "Guessed method \(guessedM.id()) at \(node.file.file)\(node.location.format())"
        )
        ownResultTypes += self.typeanalyzersState.apply(
          node: node,
          options: self.options,
          f: guessedM,
          ns: self.t
        )
        node.method = guessedM
        self.metadata.registerMethodCall(call: node)
        found = true
        checkerState.apply(node: node, metadata: self.metadata, f: guessedM)
      }
    }
    let onlyDisabler = types.count == 1 && (types[0] as? Disabler) != nil
    if !found && !onlyDisabler {
      let t = joinTypes(types: types)
      self.metadata.registerDiagnostic(
        node: node,
        diag: MesonDiagnostic(
          sev: .error,
          node: node,
          message: "No method \(methodName) found for types `\(t)'"
        )
      )
    } else if !found && onlyDisabler {
      TypeAnalyzer.LOG.info("Ignoring invalid method for disabler")
    } else {
      if let args = node.argumentList, args is ArgumentList {
        self.checkCall(node: node)
      } else if node.argumentList == nil {
        if node.method!.minPosArgs() != 0 {
          self.metadata.registerDiagnostic(
            node: node,
            diag: MesonDiagnostic(
              sev: .error,
              node: node,
              message: "Expected " + String(node.method!.minPosArgs())
                + " positional arguments, but got none!"
            )
          )
        }
      }
      if node.argumentList != nil, let al = node.argumentList as? ArgumentList {
        for a in al.args where a is KeywordItem {
          self.metadata.registerKwarg(item: a as! KeywordItem, f: node.method!)
        }
      }
    }
    Timing.INSTANCE.registerMeasurement(name: "visitMethodExpression", begin: begin, end: clock())
  }
  // swiftlint:enable cyclomatic_complexity

  // swiftlint:disable cyclomatic_complexity
  func checkCall(node: Expression) {
    let begin = clock()
    let args: [Node]
    let fn: Function
    if let fne = node as? FunctionExpression {
      fn = fne.function!
      if let al = fne.argumentList as? ArgumentList { args = al.args } else { args = [] }
    } else if let me = node as? MethodExpression {
      fn = me.method!
      if let al = me.argumentList as? ArgumentList { args = al.args } else { args = [] }
    } else {
      return
    }
    var kwargsOnly = false
    for arg in args {
      if kwargsOnly {
        if arg is KeywordItem { continue }
        self.metadata.registerDiagnostic(
          node: arg,
          diag: MesonDiagnostic(
            sev: .error,
            node: arg,
            message: "Unexpected positional argument after a keyword argument"
          )
        )
        continue
      } else if arg is KeywordItem {
        kwargsOnly = true
      }
    }
    var nKwargs = 0
    var nPos = 0
    for arg in args { if arg is KeywordItem { nKwargs += 1 } else { nPos += 1 } }
    if nPos < fn.minPosArgs() {
      self.metadata.registerDiagnostic(
        node: node,
        diag: MesonDiagnostic(
          sev: .error,
          node: node,
          message: "Expected " + String(fn.minPosArgs()) + " positional arguments, but got "
            + String(nPos) + "!"
        )
      )
    }
    if nPos > fn.maxPosArgs() {
      self.metadata.registerDiagnostic(
        node: node,
        diag: MesonDiagnostic(
          sev: .error,
          node: node,
          message: "Expected " + String(fn.maxPosArgs()) + " positional arguments, but got "
            + String(nPos) + "!"
        )
      )
    }
    var usedKwargs: [String: KeywordItem] = [:]
    for arg in args where arg is KeywordItem {
      let k = (arg as! KeywordItem).key
      if let kId = k as? IdExpression {
        usedKwargs[kId.id] = (arg as! KeywordItem)
        // TODO: What is this kwargs kwarg? Can it be applied everywhere?
        if !fn.hasKwarg(name: kId.id) && kId.id != "kwargs" {
          self.metadata.registerDiagnostic(
            node: arg,
            diag: MesonDiagnostic(
              sev: .error,
              node: arg,
              message: "Unknown key word argument '" + kId.id + "'!"
            )
          )
        }
      }
    }
    for requiredKwarg in fn.requiredKwargs() where usedKwargs[requiredKwarg] == nil {
      self.metadata.registerDiagnostic(
        node: node,
        diag: MesonDiagnostic(
          sev: .error,
          node: node,
          message: "Missing required key word argument '" + requiredKwarg + "'!"
        )
      )
    }
    // TODO: Type checking for each argument
    Timing.INSTANCE.registerMeasurement(name: "checkCall", begin: Int(begin), end: Int(clock()))
  }
  // swiftlint:enable cyclomatic_complexity

  public func evalStack(name: String) -> [Type] {
    var ret: [Type] = []
    for ov in self.overriddenVariables where ov[name] != nil { ret += ov[name]! }
    return ret
  }
  func ignoreIdExpression(node: IdExpression) -> Bool {
    let parent = node.parent
    return (parent is FunctionExpression && (parent as! FunctionExpression).id.equals(right: node))
      || (parent is MethodExpression && (parent as! MethodExpression).id.equals(right: node))
      || (parent is KeywordItem && (parent as! KeywordItem).key.equals(right: node))
  }
  public func visitIdExpression(node: IdExpression) {
    let begin = clock()
    let s = self.evalStack(name: node.id)
    Timing.INSTANCE.registerMeasurement(name: "evalStack", begin: begin, end: clock())
    node.types = dedup(types: s + (scope.variables[node.id] ?? []))
    node.visitChildren(visitor: self)
    if self.ignoreIdExpression(node: node) { return }
    if !isKnownId(id: node) {
      self.metadata.registerDiagnostic(
        node: node,
        diag: MesonDiagnostic(sev: .error, node: node, message: "Unknown identifier")
      )
    }
    self.metadata.registerIdentifier(id: node)
  }

  func isKnownId(id: IdExpression) -> Bool {
    let parent = id.parent
    if let a = parent as? AssignmentStatement, let b = a.lhs as? IdExpression {
      if b.id == id.id && a.op == .equals { return true }
    } else if let i = parent as? IterationStatement {
      for idd in i.ids { if let l = idd as? IdExpression, id.id == l.id { return true } }
    } else if let kw = parent as? KeywordItem, let b = kw.key as? IdExpression, id.id == b.id {
      return true
    } else if let fe = parent as? FunctionExpression, let b = fe.id as? IdExpression, id.id == b.id
    {
      return true
    } else if let me = parent as? MethodExpression, let b = me.id as? IdExpression, id.id == b.id {
      return true
    }

    return self.scope.variables[id.id] != nil
  }

  func isType(_ type: Type, _ name: String) -> Bool {
    return type.name == name || type.name == "any"
  }
  // swiftlint:disable cyclomatic_complexity
  func evalBinaryExpression(_ op: BinaryOperator, _ lhs: [Type], _ rhs: [Type]) -> (Int, [Type]) {
    var newTypes: [Type] = []
    var nErrors = 0
    for l in lhs {
      for r in rhs {
        // Theoretically not an error (yet),
        // but practically better safe than sorry.
        if r.name == "any" && l.name == "any" {
          nErrors += 1
          continue
        }
        switch op {
        case .and, .or:
          if isType(l, "bool") && isType(r, "bool") {
            newTypes.append(self.t.types["bool"]!)
          } else {
            nErrors += 1
          }
        case .div:
          if isType(l, "int") && isType(r, "int") {
            newTypes.append(self.t.types["int"]!)
          } else if isType(l, "str") && isType(r, "str") {
            newTypes.append(self.t.types["str"]!)
          } else {
            nErrors += 1
          }
        case .equalsEquals:
          if isType(l, "int") && isType(r, "int") {
            newTypes.append(self.t.types["bool"]!)
          } else if isType(l, "str") && isType(r, "str") {
            newTypes.append(self.t.types["bool"]!)
          } else if isType(l, "bool") && isType(r, "bool") {
            newTypes.append(self.t.types["bool"]!)
          } else if isType(l, "dict") && isType(r, "dict") {
            newTypes.append(self.t.types["bool"]!)
          } else if isType(l, "list") && isType(r, "list") {
            newTypes.append(self.t.types["bool"]!)
          } else if l is AbstractObject && r is AbstractObject && l.name == r.name {
            newTypes.append(self.t.types["bool"]!)
          } else {
            nErrors += 1
          }
        case .ge, .gt, .le, .lt:
          if isType(l, "int") && isType(r, "int") {
            newTypes.append(self.t.types["bool"]!)
          } else if isType(l, "str") && isType(r, "str") {
            newTypes.append(self.t.types["bool"]!)
          } else {
            nErrors += 1
          }
        case .IN: newTypes.append(self.t.types["bool"]!)
        case .minus, .modulo, .mul:
          if isType(l, "int") && isType(r, "int") {
            newTypes.append(self.t.types["int"]!)
          } else {
            nErrors += 1
          }
        case .notEquals:
          if isType(l, "int") && isType(r, "int") {
            newTypes.append(self.t.types["bool"]!)
          } else if isType(l, "str") && isType(r, "str") {
            newTypes.append(self.t.types["bool"]!)
          } else if isType(l, "bool") && isType(r, "bool") {
            newTypes.append(self.t.types["bool"]!)
          } else if isType(l, "dict") && isType(r, "dict") {
            newTypes.append(self.t.types["bool"]!)
          } else if isType(l, "list") && isType(r, "list") {
            newTypes.append(self.t.types["bool"]!)
          } else if l is AbstractObject && r is AbstractObject && l.name == r.name {
            newTypes.append(self.t.types["bool"]!)
          } else {
            nErrors += 1
          }
        case .notIn: newTypes.append(self.t.types["bool"]!)
        case .plus:
          if isType(l, "int") && isType(r, "int") {
            newTypes.append(self.t.types["int"]!)
          } else if isType(l, "str") && isType(r, "str") {
            newTypes.append(self.t.types["str"]!)
          } else if let ll = l as? ListType, let lr = r as? ListType {
            newTypes.append(ListType(types: dedup(types: ll.types + lr.types)))
          } else if let ll = l as? ListType {
            newTypes.append(ListType(types: dedup(types: ll.types + [r])))
          } else if let dl = l as? Dict, let dr = r as? Dict {
            newTypes.append(Dict(types: dedup(types: dl.types + dr.types)))
          } else if let dl = l as? Dict {
            newTypes.append(Dict(types: dedup(types: dl.types + [r])))
          } else {
            nErrors += 1
          }
        }
      }
    }
    return (nErrors, nErrors == lhs.count * rhs.count ? lhs : newTypes)
  }
  // swiftlint:enable cyclomatic_complexity

  public func visitBinaryExpression(node: BinaryExpression) {
    let begin = clock()
    node.visitChildren(visitor: self)
    if node.op == nil {
      // Emergency fix
      node.types = dedup(types: node.lhs.types + node.rhs.types)
      self.metadata.registerDiagnostic(
        node: node,
        diag: MesonDiagnostic(sev: .error, node: node, message: "Missing binary operator")
      )
      Timing.INSTANCE.registerMeasurement(name: "visitBinaryExpression", begin: begin, end: clock())
      return
    }
    let (nErrors, newTypes) = self.evalBinaryExpression(node.op!, node.lhs.types, node.rhs.types)
    let nTimes = node.lhs.types.count * node.rhs.types.count
    if nTimes != 0 && nErrors == nTimes && (!node.lhs.types.isEmpty) && (!node.rhs.types.isEmpty) {
      self.metadata.registerDiagnostic(
        node: node,
        diag: MesonDiagnostic(
          sev: .error,
          node: node,
          message:
            "Unable to apply operator `\(node.op!)` to types \(self.joinTypes(types: node.lhs.types)) and \(self.joinTypes(types: node.rhs.types))"
        )
      )
    }
    node.types = dedup(types: newTypes)
    Timing.INSTANCE.registerMeasurement(name: "visitBinaryExpression", begin: begin, end: clock())
  }
  public func visitStringLiteral(node: StringLiteral) {
    node.types = [self.t.types["str"]!]
    node.visitChildren(visitor: self)
  }
  public func visitArrayLiteral(node: ArrayLiteral) {
    node.visitChildren(visitor: self)
    var t: [Type] = []
    for elem in node.args { t += elem.types }
    node.types = [ListType(types: dedup(types: t))]
  }
  public func visitBooleanLiteral(node: BooleanLiteral) {
    node.types = [self.t.types["bool"]!]
    node.visitChildren(visitor: self)
  }
  public func visitIntegerLiteral(node: IntegerLiteral) {
    node.types = [self.t.types["int"]!]
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
    return types.map({ $0.toString() }).sorted().joined(separator: "|")
  }
  // swiftlint:disable cyclomatic_complexity
  public func dedup(types: [Type]) -> [Type] {
    if types.isEmpty { return types }
    let begin = clock()
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
      if t is `Any` {
        hasAny = true
        continue
      }
      if t is BoolType {
        hasBool = true
      } else if t is `IntType` {
        hasInt = true
      } else if t is Str {
        hasStr = true
      } else if let d = t as? Dict {
        dicttypes += d.types
        gotDict = true
      } else if let lt = t as? ListType {
        listtypes += lt.types
        gotList = true
      } else {
        objs[t.name] = t
      }
    }
    var ret: [Type] = []
    if !listtypes.isEmpty || gotList { ret.append(ListType(types: dedup(types: listtypes))) }
    if !dicttypes.isEmpty || gotDict { ret.append(Dict(types: dedup(types: dicttypes))) }
    if hasAny { ret.append(self.t.types["any"]!) }
    if hasBool { ret.append(self.t.types["bool"]!) }
    if hasInt { ret.append(self.t.types["int"]!) }
    if hasStr { ret.append(self.t.types["str"]!) }
    ret += objs.values
    Timing.INSTANCE.registerMeasurement(name: "dedup", begin: begin, end: clock())
    return ret
  }  // swiftlint:enable cyclomatic_complexity
}
