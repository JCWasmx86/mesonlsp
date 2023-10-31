import Foundation
import LanguageServerProtocol
import MesonAnalyze
import Timing

internal func collectInlayHints(_ tree: MesonTree?, _ req: InlayHintRequest, _ mapper: FileMapper)
  -> [InlayHint]
{
  let begin = clock()
  let file = mapper.fromSubprojectToCache(file: req.textDocument.uri.fileURL!.path)
  if let t = tree, let mt = t.findSubdirTree(file: file), let ast = mt.ast {
    let ih = InlayHintsCollector()
    ast.visit(visitor: ih)
    Timing.INSTANCE.registerMeasurement(name: "inlayHints", begin: begin, end: clock())
    return ih.inlays
  }
  Timing.INSTANCE.registerMeasurement(name: "inlayHints", begin: begin, end: clock())
  return []
}
