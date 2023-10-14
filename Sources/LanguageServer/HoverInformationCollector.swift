import Foundation
import LanguageServerProtocol
import MesonAnalyze
import MesonAST
import MesonDocs
import Timing

internal func collectHoverInformation(
  _ tree: MesonTree?,
  _ req: Request<HoverRequest>,
  _ mapper: FileMapper,
  _ docs: MesonDocs
) {
  let begin = clock()
  let location = req.params.position
  let file = mapper.fromSubprojectToCache(file: req.params.textDocument.uri.fileURL!.path)
  var content: String?
  var requery = true
  var function: Function?
  var kwargTypes: String?
  hoverFindCallable(file, location.line, location.utf16index, tree, &function, &content)
  hoverFindIdentifier(file, location.line, location.utf16index, docs, tree, &content, &requery)
  if content == nil, let t = tree,
    let tuple = t.metadata!.findKwargAt(file, location.line, location.utf16index)
  {
    let kw = tuple.0
    let f = tuple.1
    var fun: Function?
    if let me = kw.parent!.parent as? MethodExpression {
      fun = me.method
    } else if let fe = kw.parent!.parent as? FunctionExpression {
      fun = fe.function
    }
    if let k = kw.key as? IdExpression {
      content = f.id() + "<" + k.id + ">"
      if fun != nil, let f = fun!.kwargs[k.id] {
        kwargTypes = f.types.map { $0.toString() }.joined(separator: "|")
      }
    }
  }
  if content != nil && requery {
    if function == nil {  // Kwarg docs
      let d = docs.findDocs(id: content!)
      content = (d ?? content!) + "\n\n*Types:*`" + (kwargTypes ?? "???") + "`"
    } else {
      let d = docs.findDocs(id: content!)
      if let mdocs = d { content = callHover(content: content, mdocs: mdocs, function: function) }
    }
  }
  req.reply(
    HoverResponse(
      contents: content == nil
        ? .markedStrings([])
        : .markupContent(
          MarkupContent(
            kind: .markdown,
            value: content!.trimmingCharacters(in: .whitespacesAndNewlines)
          )
        ),
      range: nil
    )
  )
  Timing.INSTANCE.registerMeasurement(name: "hover", begin: begin, end: clock())
}

// swiftlint:disable function_parameter_count
private func hoverFindCallable(
  _ file: String,
  _ line: Int,
  _ column: Int,
  _ tree: MesonTree?,
  _ function: inout Function?,
  _ content: inout String?
) {
  if let t = tree, let m = t.metadata!.findMethodCallAt(file, line, column), let method = m.method {
    function = method
    content = method.parent.toString() + "." + m.method!.name
  }
  if let t = tree, content == nil, let f = t.metadata!.findFunctionCallAt(file, line, column),
    let fn = f.function
  {
    if fn.name == "get_option", let al = f.argumentList as? ArgumentList, !al.args.isEmpty,
      let sl = al.args[0] as? StringLiteral, let opt = t.options,
      let option = opt.opts[sl.contents()]
    {
      function = fn
      content = "Option: \(option.name)\n\nType: \(option.type)\n\n\(option.description ?? "")"
      if let comboOpt = option as? ComboOption, let possibleValues = comboOpt.values {
        let fullStr = possibleValues.sorted().map { "`\($0)`" }.joined(separator: " | ")
        content = content! + "\n\nPossible values: \(fullStr)"
      } else if let arrayOpt = option as? ArrayOption, let possibleValues = arrayOpt.choices {
        let fullStr = possibleValues.sorted().map { "`\($0)`" }.joined(separator: " | ")
        content = content! + "\n\nPossible values: \(fullStr)"
      }
    } else {
      function = fn
      content = fn.name
    }
  }
}

private func hoverFindIdentifier(
  _ file: String,
  _ line: Int,
  _ column: Int,
  _ docs: MesonDocs,
  _ tree: MesonTree?,
  _ content: inout String?,
  _ requery: inout Bool
) {
  if content == nil, let t = tree, let f = t.metadata!.findIdentifierAt(file, line, column) {
    if f.types.count == 1 {
      content = f.types[0].toString()
      if let d = docs.typeDocs[f.types[0].name] { content = "\(content!)\n\n" + d + "\n" }
      requery = false
    } else if !f.types.isEmpty {
      content = f.types.map { $0.toString() }.joined(separator: "|")
      requery = false
    }
  }
}

private func callHover(content: String?, mdocs: String, function: Function?) -> String {
  var str = "`" + content! + "`\n\n" + mdocs + "\n\n"
  if !function!.returnTypes.isEmpty {
    str +=
      "\n**Returns:** `" + function!.returnTypes.map { $0.toString() }.joined(separator: "|") + "`"
  }
  if function!.args.isEmpty { return str }

  str += "\n\n**Parameters:**\n"
  for arg in function!.args {
    if let pa = arg as? PositionalArgument {
      str += "- "
      if pa.opt { str += "\\[" }
      str += "`\(pa.name) "
      str += pa.types.map { $0.toString() }.joined(separator: "|") + "`"
      if pa.varargs { str += "..." }
      if pa.opt { str += "\\]" }
      str += "\n"
    } else if let kw = arg as? Kwarg {
      str += "- "
      if kw.opt { str += "\\[" }
      str += "`\(kw.name): "
      str += kw.types.map({ $0.toString() }).joined(separator: "|") + "`"
      if kw.opt { str += "\\]" }
      str += "\n"
    }
  }
  return str
}  // swiftlint:enable function_parameter_count
