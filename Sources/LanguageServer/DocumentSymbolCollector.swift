import Foundation
import LanguageServerProtocol
import MesonAnalyze
import Timing

internal func collectDocumentSymbols(
  _ tree: MesonTree?,
  _ req: DocumentSymbolRequest,
  _ mapper: FileMapper
) -> DocumentSymbolResponse? {
  let begin = clock()
  if let t = tree,
    let mt = t.findSubdirTree(
      file: mapper.fromSubprojectToCache(file: req.textDocument.uri.fileURL!.path)
    ), let ast = mt.ast
  {
    let sv = SymbolCodeVisitor()
    var rep: [SymbolInformation] = []
    ast.visit(visitor: sv)
    for si in sv.symbols {
      let name = si.name
      let range =
        Position(
          line: Int(si.startLine),
          utf16index: Int(si.startColumn)
        )..<Position(line: Int(si.endLine), utf16index: Int(si.endColumn))
      let kind = SymbolKind(rawValue: Int(si.kind))
      rep.append(
        SymbolInformation(
          name: name,
          kind: kind,
          location: Location(uri: req.textDocument.uri, range: range)
        )
      )
    }
    Timing.INSTANCE.registerMeasurement(name: "documentSymbol", begin: begin, end: clock())
    return .symbolInformation(rep)
  }
  Timing.INSTANCE.registerMeasurement(name: "documentSymbol", begin: begin, end: clock())
  return nil
}
