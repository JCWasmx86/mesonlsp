import Foundation
import LanguageServerProtocol
import MesonAnalyze
import MesonAST
import MesonDocs
import Timing

internal func collectHoverInformation(
  _ tree: MesonTree?,
  _ req: Request<HoverRequest>,
  _ docs: MesonDocs
) {
  let begin = clock()
  let location = req.params.position
  let file = req.params.textDocument.uri.fileURL?.path
  var content: String?
  var requery = true
  var function: Function?
  var kwargTypes: String?
  hoverFindCallable(file!, location.line, location.utf16index, tree, &function, &content)
  hoverFindIdentifier(file!, location.line, location.utf16index, tree, &content, &requery)
  if content == nil, let t = tree,
    let tuple = t.metadata!.findKwargAt(file!, location.line, location.utf16index)
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
        ? .markedStrings([]) : .markupContent(MarkupContent(kind: .markdown, value: content ?? "")),
      range: nil
    )
  )
  Timing.INSTANCE.registerMeasurement(name: "hover", begin: begin, end: clock())
}

private func hoverFindCallable(
  _ file: String,
  _ line: Int,
  _ column: Int,
  _ tree: MesonTree?,
  _ function: inout Function?,
  _ content: inout String?
) {
  if let t = tree, let m = t.metadata!.findMethodCallAt(file, line, column), m.method != nil {
    function = m.method!
    content = m.method!.parent.toString() + "." + m.method!.name
  }
  if let t = tree, content == nil, let f = t.metadata!.findFunctionCallAt(file, line, column),
    f.function != nil
  {
    function = f.function!
    content = f.function!.name
  }
}

private func hoverFindIdentifier(
  _ file: String,
  _ line: Int,
  _ column: Int,
  _ tree: MesonTree?,
  _ content: inout String?,
  _ requery: inout Bool
) {
  if content == nil, let t = tree, let f = t.metadata!.findIdentifierAt(file, line, column) {
    if !f.types.isEmpty {
      content = f.types.map { $0.toString() }.joined(separator: "|")
      requery = false
    }
  }
}

private func callHover(content: String?, mdocs: String, function: Function?) -> String {
  var str = "`" + content! + "`\n\n" + mdocs + "\n\n"
  for arg in function!.args {
    if let pa = arg as? PositionalArgument {
      str += "- "
      if pa.opt { str += "\\[" }
      str += "`" + pa.name + "`"
      str += " "
      str += pa.types.map { $0.toString() }.joined(separator: "|")
      if pa.varargs { str += "..." }
      if pa.opt { str += "\\]" }
      str += "\n"
    } else if let kw = arg as? Kwarg {
      str += "- "
      if kw.opt { str += "\\[" }
      str += "`" + kw.name + "`"
      str += ": "
      str += kw.types.map({ $0.toString() }).joined(separator: "|")
      if kw.opt { str += "\\]" }
      str += "\n"
    }
  }
  if !function!.returnTypes.isEmpty {
    str += "\n*Returns:* " + function!.returnTypes.map { $0.toString() }.joined(separator: "|")
  }
  return str
}
