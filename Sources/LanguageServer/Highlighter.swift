import Foundation
import LanguageServerProtocol
import MesonAnalyze
import Timing

internal func highlightTree(
  _ tree: MesonTree?,
  _ req: DocumentHighlightRequest,
  _ mapper: FileMapper
) -> [DocumentHighlight] {
  let begin = clock()
  let file = mapper.fromSubprojectToCache(file: req.textDocument.uri.fileURL!.path)
  if let t = tree, let mt = t.findSubdirTree(file: file), let ast = mt.ast,
    let id = t.metadata!.findIdentifierAt(file, req.position.line, req.position.utf16index)
  {
    let hs = HighlightSearcher(varname: id.id)
    ast.visit(visitor: hs)
    var ret: [DocumentHighlight] = []
    for a in hs.accesses {
      let accessType: DocumentHighlightKind = a.0 == 2 ? .read : .write
      let si = a.1
      let range =
        Position(
          line: Int(si.startLine),
          utf16index: Int(si.startColumn)
        )..<Position(line: Int(si.endLine), utf16index: Int(si.endColumn))
      ret.append(DocumentHighlight(range: range, kind: accessType))
    }
    Timing.INSTANCE.registerMeasurement(name: "highlight", begin: begin, end: clock())
    return ret
  }
  Timing.INSTANCE.registerMeasurement(name: "highlight", begin: begin, end: clock())
  return []
}
