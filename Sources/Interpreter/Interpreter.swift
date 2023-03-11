import Logging
import MesonAST
import MesonAnalyze
import Foundation
import PathKit

public class Interpreter {
  static let LOG = Logger(label: "Interpreter::Interpreter")

  private var ns: TypeNamespace
  private var tree: MesonTree
  private var scope: [String: ValueHolder]
  private var tempDir: Path

  public init(ns: TypeNamespace, tree: MesonTree) {
    self.ns = ns
    self.tree = tree
    self.scope = [:]
    self.scope["meson"] = MesonValueHolder(t: self.ns)
    self.scope["build_machine"] = BuildMachineHolder(t: self.ns)
    self.scope["host_machine"] = HostMachineHolder(t: self.ns)
    self.tempDir = try! Path.uniqueTemporary()
    Interpreter.LOG.info("MESON_BUILD_ROOT: \(self.tempDir)")
  }

  public func run() {
    if let ast = tree.ast, let sf = ast as? SourceFile,
      let bd = sf.build_definition as? BuildDefinition
    {
      let stmts = bd.stmts
      var broken = false
      self.executeStmts(stmts, &broken)
    }
  }

  func executeStmts(_ stmts: [Node], _ broken: inout Bool) {
    for stmt in stmts {
      Interpreter.LOG.info("Executing stmt at: \(stmt.file.file):\(stmt.location.format())")
      if let assignment = stmt as? AssignmentStatement {
        let value = self.eval(assignment.rhs)
        if assignment.op! == .equals {
          if let idExpr = assignment.lhs as? IdExpression {
            self.scope[idExpr.id] = value
          } else if let subscr = assignment.lhs as? SubscriptExpression {
            let inner = self.eval(subscr.inner)
            if let idExpr2 = subscr.outer as? IdExpression {
              let parentContainer = self.scope[idExpr2.id]!
              if let dict = parentContainer as? DictValueHolder,
                let si = inner as? StringValueHolder
              {
                var newMappings: [String: ValueHolder] = [:]
                for n in dict.values { newMappings[n.key] = n.value.clone() }
                newMappings[si.value] = value
                scope[idExpr2.id] = DictValueHolder(t: ns, values: newMappings)
              } else if let arr = parentContainer as? ListValueHolder,
                let ii = inner as? IntegerValueHolder
              {
                var newArr = Array(arr.values.map({ $0.clone() }))
                newArr[ii.value] = value!
                scope[idExpr2.id] = ListValueHolder(t: ns, values: newArr)
              }
            }
          }
        } else {
          if let idExpr = assignment.lhs as? IdExpression {
            let containerToAddTo = self.scope[idExpr.id]
            if let ivh = containerToAddTo as? IntegerValueHolder,
              let il = value as? IntegerValueHolder
            {
              self.scope[idExpr.id] = IntegerValueHolder(t: self.ns, value: ivh.value + il.value)
            } else if let svh = containerToAddTo as? StringValueHolder,
              let sl = value as? StringValueHolder
            {
              self.scope[idExpr.id] = StringValueHolder(t: self.ns, value: svh.value + sl.value)
            } else if let lvh = containerToAddTo as? ListValueHolder {
              var newValues: [ValueHolder] = Array(lvh.values.map({ $0.clone() }))
              if let lvh2 = value as? ListValueHolder {
                newValues += Array(lvh2.values.map({ $0.clone() }))
              } else {
                newValues.append(value!)
              }
              self.scope[idExpr.id] = ListValueHolder(t: self.ns, values: newValues)
            } else if let dvh = containerToAddTo as? DictValueHolder {
              var newMappings: [String: ValueHolder] = [:]
              for n in dvh.values { newMappings[n.key] = n.value.clone() }
              if let dvh2 = value as? DictValueHolder {
                for d in dvh2.values { newMappings[d.key] = d.value.clone() }
              }
              self.scope[idExpr.id] = DictValueHolder(t: self.ns, values: newMappings)
            }
          } else if let subscr = assignment.lhs as? SubscriptExpression {
            let inner = self.eval(subscr.inner)
            if let idExpr2 = subscr.outer as? IdExpression {
              let parentContainer = self.scope[idExpr2.id]!
              if let dict = parentContainer as? DictValueHolder,
                let si = inner as? StringValueHolder
              {
                var newMappings: [String: ValueHolder] = [:]
                for n in dict.values { newMappings[n.key] = n.value.clone() }
                newMappings[si.value] = self.addValues(newMappings[si.value]!, value!)
                scope[idExpr2.id] = DictValueHolder(t: ns, values: newMappings)
              } else if let arr = parentContainer as? ListValueHolder,
                let ii = inner as? IntegerValueHolder
              {
                var newArr = Array(arr.values.map({ $0.clone() }))
                newArr[ii.value] = self.addValues(newArr[ii.value], value!)
                scope[idExpr2.id] = ListValueHolder(t: ns, values: newArr)
              }
            }
          }
        }
      } else if let selectionStatement = stmt as? SelectionStatement {
        let conds = [selectionStatement.ifCondition] + selectionStatement.conditions
        var idx = 0
        for c in conds {
          let val = self.eval(c)
          if let v = val as? BoolValueHolder, v.value {
            self.executeStmts(selectionStatement.blocks[idx], &broken)
            if broken { return }
            break
          }
          idx += 1
        }
        // Execute else block
        if idx == conds.count && selectionStatement.blocks.count == conds.count + 2 {
          self.executeStmts(selectionStatement.blocks[selectionStatement.blocks.count - 1], &broken)
          if broken { return }
        }
      } else if let its = stmt as? IterationStatement {
        let lhs = self.eval(its.expression)
        let idexprs = its.ids.map({ $0 as! IdExpression })
        if let dvh = lhs as? DictValueHolder {
          for l in dvh.values {
            self.scope[idexprs[0].id] = StringValueHolder(t: self.ns, value: l.key)
            self.scope[idexprs[1].id] = l.value.clone()
            var brk = false
            self.executeStmts(its.block, &brk)
            if brk { break }
          }
        } else if let lvh = lhs as? ListValueHolder {
          for l in lvh.values {
            self.scope[idexprs[0].id] = l.clone()
            var brk = false
            self.executeStmts(its.block, &brk)
            if brk { break }
          }
        }
      } else if stmt is ContinueNode {
        return
      } else if stmt is BreakNode {
        broken = true
        return
      } else {
        _ = self.eval(stmt)
      }
    }
  }

  func addValues(_ l: ValueHolder, _ r: ValueHolder) -> ValueHolder {
    if let ivh = l as? IntegerValueHolder, let il = r as? IntegerValueHolder {
      return IntegerValueHolder(t: self.ns, value: ivh.value + il.value)
    } else if let svh = l as? StringValueHolder, let sl = r as? StringValueHolder {
      return StringValueHolder(t: self.ns, value: svh.value + sl.value)
    } else if let lvh = l as? ListValueHolder {
      var newValues: [ValueHolder] = Array(lvh.values.map({ $0.clone() }))
      if let lvh2 = r as? ListValueHolder {
        newValues += Array(lvh2.values.map({ $0.clone() }))
      } else {
        newValues.append(r)
      }
      return ListValueHolder(t: self.ns, values: newValues)
    } else if let dvh = l as? DictValueHolder {
      var newMappings: [String: ValueHolder] = [:]
      for n in dvh.values { newMappings[n.key] = n.value.clone() }
      if let dvh2 = r as? DictValueHolder {
        for d in dvh2.values { newMappings[d.key] = d.value.clone() }
      }
      return DictValueHolder(t: self.ns, values: newMappings)
    }
    return ErrorValueHolder(t: self.ns)
  }

  func eval(_ node: Node) -> ValueHolder? {
    // TODO: Handle subdircall before function expression
    if let al = node as? ArrayLiteral {
      var types: [ValueHolder] = []
      for a in al.args { types.append(self.eval(a)!) }
      return ListValueHolder(t: self.ns, values: types)
    } else if let be = node as? BinaryExpression {
      let lhs = self.eval(be.lhs)!
      let rhs = self.eval(be.rhs)!
      switch be.op! {
      case .and:
        if let lhsB = lhs as? BoolValueHolder, let rhsB = rhs as? BoolValueHolder {
          return BoolValueHolder(t: self.ns, value: lhsB.value && rhsB.value)
        }
      case .div:
        if let lhsB = lhs as? IntegerValueHolder, let rhsB = rhs as? IntegerValueHolder {
          return IntegerValueHolder(t: self.ns, value: lhsB.value / rhsB.value)
        } else if let lhsB = lhs as? StringValueHolder, let rhsB = rhs as? StringValueHolder {
          return StringValueHolder(t: self.ns, value: lhsB.value + "/" + rhsB.value)
        }
      case .equalsEquals: return BoolValueHolder(t: self.ns, value: lhs.equals(rhs))
      case .ge:
        if let lhsB = lhs as? IntegerValueHolder, let rhsB = rhs as? IntegerValueHolder {
          return BoolValueHolder(t: self.ns, value: lhsB.value >= rhsB.value)
        } else if let lhsB = lhs as? StringValueHolder, let rhsB = rhs as? StringValueHolder {
          return BoolValueHolder(t: self.ns, value: lhsB.value >= rhsB.value)
        }
      case .gt:
        if let lhsB = lhs as? IntegerValueHolder, let rhsB = rhs as? IntegerValueHolder {
          return BoolValueHolder(t: self.ns, value: lhsB.value > rhsB.value)
        } else if let lhsB = lhs as? StringValueHolder, let rhsB = rhs as? StringValueHolder {
          return BoolValueHolder(t: self.ns, value: lhsB.value > rhsB.value)
        }
      case .IN:
        if let lhsB = lhs as? StringValueHolder, let rhsB = rhs as? StringValueHolder {
          return BoolValueHolder(t: self.ns, value: rhsB.value.contains(lhsB.value))
        } else if let lhsB = lhs as? StringValueHolder, let rhsB = rhs as? DictValueHolder {
          return BoolValueHolder(t: self.ns, value: rhsB.values[lhsB.value] != nil)
        } else if let rhsB = rhs as? ListValueHolder {
          return BoolValueHolder(
            t: self.ns,
            value: !rhsB.values.filter({ $0.equals(rhsB) }).isEmpty
          )
        }
      case .le:
        if let lhsB = lhs as? IntegerValueHolder, let rhsB = rhs as? IntegerValueHolder {
          return BoolValueHolder(t: self.ns, value: lhsB.value <= rhsB.value)
        } else if let lhsB = lhs as? StringValueHolder, let rhsB = rhs as? StringValueHolder {
          return BoolValueHolder(t: self.ns, value: lhsB.value <= rhsB.value)
        }
      case .lt:
        if let lhsB = lhs as? IntegerValueHolder, let rhsB = rhs as? IntegerValueHolder {
          return BoolValueHolder(t: self.ns, value: lhsB.value < rhsB.value)
        } else if let lhsB = lhs as? StringValueHolder, let rhsB = rhs as? StringValueHolder {
          return BoolValueHolder(t: self.ns, value: lhsB.value < rhsB.value)
        }
      case .minus:
        if let lhsB = lhs as? IntegerValueHolder, let rhsB = rhs as? IntegerValueHolder {
          return IntegerValueHolder(t: self.ns, value: lhsB.value - rhsB.value)
        }
      case .modulo:
        if let lhsB = lhs as? IntegerValueHolder, let rhsB = rhs as? IntegerValueHolder {
          return IntegerValueHolder(t: self.ns, value: lhsB.value % rhsB.value)
        }
      case .mul:
        if let lhsB = lhs as? IntegerValueHolder, let rhsB = rhs as? IntegerValueHolder {
          return IntegerValueHolder(t: self.ns, value: lhsB.value * rhsB.value)
        }
      case .notEquals: return BoolValueHolder(t: self.ns, value: !lhs.equals(rhs))
      case .notIn:
        if let lhsB = lhs as? StringValueHolder, let rhsB = rhs as? StringValueHolder {
          return BoolValueHolder(t: self.ns, value: !rhsB.value.contains(lhsB.value))
        } else if let lhsB = lhs as? StringValueHolder, let rhsB = rhs as? DictValueHolder {
          return BoolValueHolder(t: self.ns, value: rhsB.values[lhsB.value] == nil)
        } else if let rhsB = rhs as? ListValueHolder {
          return BoolValueHolder(t: self.ns, value: rhsB.values.filter({ $0.equals(rhsB) }).isEmpty)
        }
      case .or:
        if let lhsB = lhs as? BoolValueHolder, let rhsB = rhs as? BoolValueHolder {
          return BoolValueHolder(t: self.ns, value: lhsB.value || rhsB.value)
        }
      case .plus: return self.addValues(lhs, rhs)
      }
    } else if let bl = node as? BooleanLiteral {
      return BoolValueHolder(t: self.ns, value: bl.value)
    } else if let ce = node as? ConditionalExpression {
      let condition = self.eval(ce.condition)
      if let bvh = condition as? BoolValueHolder {
        return self.eval(bvh.value ? ce.ifTrue : ce.ifFalse)
      } else {
        return ErrorValueHolder(t: self.ns)
      }
    } else if let de = node as? DictionaryLiteral {
      var mappings: [String: ValueHolder] = [:]
      for mapping in de.values {
        if let m = mapping as? KeyValueItem {
          let k = self.eval(m.key)
          if let svh = k as? StringValueHolder { mappings[svh.value] = self.eval(m.value) }
        }
      }
      return DictValueHolder(t: self.ns, values: mappings)
    } else if let fe = node as? FunctionExpression {
      return self.executeFunction(fe)
    } else if let id = node as? IdExpression {
      Interpreter.LOG.info("Accessing id: \(id.id)")
      return self.scope[id.id]!.clone()
    } else if let il = node as? IntegerLiteral {
      return IntegerValueHolder(t: self.ns, value: il.parse())
    } else if let me = node as? MethodExpression {
      return self.executeMethod(me)
    } else if let sl = node as? StringLiteral {
      return StringValueHolder(t: self.ns, value: sl.contents())
    } else if let se = node as? SubscriptExpression {
      let outer = self.eval(se.outer)
      let inner = self.eval(se.inner)
      if let dvh = outer as? DictValueHolder, let key = inner as? StringValueHolder {
        return dvh.values[key.value]!
      } else if let lvh = outer as? ListValueHolder, let key = inner as? IntegerValueHolder {
        return lvh.values[key.value]
      }
    } else if let ue = node as? UnaryExpression {
      let rhs = self.eval(ue.expression)
      if let op = ue.op {
        if op == .minus, let il = rhs as? IntegerValueHolder {
          return IntegerValueHolder(t: self.ns, value: -il.value)
        } else if op == .not, let bl = rhs as? BoolValueHolder {
          return BoolValueHolder(t: self.ns, value: !bl.value)
        } else if op == .exclamationMark, let bl = rhs as? BoolValueHolder {
          return BoolValueHolder(t: self.ns, value: !bl.value)
        }
      }
    }
    Interpreter.LOG.info("\(type(of: node))")
    return ErrorValueHolder(t: self.ns)
  }

  func executeFunction(_ fe: FunctionExpression) -> ValueHolder? {
    let ao = ArgsObject()
    if let al = fe.argumentList as? ArgumentList {
      for arg in al.args {
        if let kwi = arg as? KeywordItem {
          ao.kwargs[(kwi.key as! IdExpression).id] = self.eval(kwi.value)!
        } else {
          ao.positionalArguments.append(self.eval(arg)!)
        }
      }
    }
    switch fe.functionName() {
    case "alias_target":
      let aliasTgtName = (ao.positionalArguments[0] as! StringValueHolder).value
      var dependencies: [ValueHolder] = []
      for i in 1..<ao.positionalArguments.count {
        dependencies.append(ao.positionalArguments[i].clone())
      }
      return AliasTgtValueHolder(t: self.ns, name: aliasTgtName, deps: dependencies)
    case "assert":
      let isTrue = (ao.positionalArguments[0] as! BoolValueHolder).value
      if isTrue { return nil }
      let msg =
        ao.positionalArguments.count == 2
        ? (ao.positionalArguments[1] as! StringValueHolder).value : "Unknown"
      Interpreter.LOG.critical(
        "Assertion failed at \(fe.file.file):\(fe.location.format()): \(msg)"
      )
      exit(1)
    case "run_command":
      var args: [String] = []
      var capture = true
      var check = true
      for p in ao.positionalArguments {
        if let s = p as? StringValueHolder { args.append(s.value) }
      }
      if let al = ao.kwargs["capture"] as? BoolValueHolder { capture = al.value }
      if let al = ao.kwargs["check"] as? BoolValueHolder { check = al.value }
      if capture {
        let task = Process()
        task.executableURL = resolvePathToExecutableURL(args[0])
        task.arguments = Array(args.dropFirst())

        let pipe = Pipe()
        let pipe2 = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe2
        try! task.run()
        task.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .newlines)
        let data2 = pipe2.fileHandleForReading.readDataToEndOfFile()
        let error = String(data: data2, encoding: .utf8)?.trimmingCharacters(in: .newlines)
        if check && task.terminationStatus != 0 {
          Interpreter.LOG.critical(
            "Failed to run \(args.joined(separator: " ")): Exited with \(task.terminationStatus)"
          )
          exit(1)
        }
        return RunresultHolder(t: self.ns, task.terminationStatus, output!, error!)
      } else {
        let task = Process()
        task.executableURL = resolvePathToExecutableURL(args[0])
        task.arguments = Array(args.dropFirst())

        try! task.run()
        task.waitUntilExit()

        if check && task.terminationStatus != 0 {
          Interpreter.LOG.critical(
            "Failed to run \(args.joined(separator: " ")): Exited with \(task.terminationStatus)"
          )
          exit(1)
        }
        return RunresultHolder(t: self.ns, task.terminationStatus, "", "")
      }
    default:
      Interpreter.LOG.critical("Unhandled function call: \(fe.functionName())")
      break
    }
    return nil
  }

  func executeMethod(_ me: MethodExpression) -> ValueHolder? {
    let obj = self.eval(me.obj)!
    let method = (me.id as! IdExpression).id
    Interpreter.LOG.info("Executing method \(obj.type.name)::\(method)")
    let ao = ArgsObject()
    if let al = me.argumentList as? ArgumentList {
      for arg in al.args {
        if let kwi = arg as? KeywordItem {
          ao.kwargs[(kwi.key as! IdExpression).id] = self.eval(kwi.value)!
        } else {
          ao.positionalArguments.append(self.eval(arg)!)
        }
      }
    }

    return obj.executeMethod(t: self.ns, args: ao, name: method)
  }

  func resolvePathToExecutableURL(_ command: String) -> URL? {
    if command.starts(with: "/") { return URL(fileURLWithPath: command) }
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
    process.arguments = [command]

    let pipe = Pipe()
    process.standardOutput = pipe

    do {
      try process.run()
      process.waitUntilExit()

      let data = pipe.fileHandleForReading.readDataToEndOfFile()
      if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .newlines),
        !path.isEmpty
      {
        return URL(fileURLWithPath: path)
      } else {
        return nil
      }
    } catch {
      print("Error resolving command path: \(error.localizedDescription)")
      return nil
    }
  }

}
