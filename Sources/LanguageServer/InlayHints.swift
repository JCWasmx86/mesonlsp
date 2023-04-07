import Foundation
import LanguageServerProtocol
import MesonAnalyze
import Timing

internal func collectInlayHints(_ tree: MesonTree?, _ req: Request<InlayHintRequest>) {
  let begin = clock()
  let file = req.params.textDocument.uri.fileURL!.path
  if let t = tree, let mt = t.findSubdirTree(file: file), let ast = mt.ast {
    let ih = InlayHintsCollector()
    ast.visit(visitor: ih)
    req.reply(ih.inlays)
    Timing.INSTANCE.registerMeasurement(name: "inlayHints", begin: begin, end: clock())
    return
  }
  Timing.INSTANCE.registerMeasurement(name: "inlayHints", begin: begin, end: clock())
  req.reply([])
}
