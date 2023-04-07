import Foundation
import IOUtils
import LanguageServerProtocol
import Logging
import MesonAnalyze
import Timing

internal func findDefinition(
  _ tree: MesonTree?,
  _ req: Request<DefinitionRequest>,
  _ logger: Logger
) {
  let begin = clock()
  let location = req.params.position
  let file = req.params.textDocument.uri.fileURL?.path
  if let t = tree, let i = t.metadata!.findIdentifierAt(file!, location.line, location.utf16index),
    let t = t.findDeclaration(node: i)
  {
    let newFile = t.0
    let line = t.1[0]
    let column = t.1[1]
    let range = Range(LanguageServerProtocol.Position(line: Int(line), utf16index: Int(column)))
    logger.info("Found declaration")
    req.reply(.locations([.init(uri: DocumentURI(URL(fileURLWithPath: newFile)), range: range)]))
    Timing.INSTANCE.registerMeasurement(name: "definition", begin: begin, end: clock())
    return
  }

  if let t = tree, let sd = t.metadata!.findSubdirCallAt(file!, location.line, location.utf16index)
  {
    let path = Path(
      Path(file!).parent().description + Path.separator + sd.subdirname
        + "\(Path.separator)meson.build"
    ).description
    let range = Range(LanguageServerProtocol.Position(line: Int(0), utf16index: Int(0)))
    req.reply(.locations([.init(uri: DocumentURI(URL(fileURLWithPath: path)), range: range)]))
    logger.info("Found declaration")
    Timing.INSTANCE.registerMeasurement(name: "definition", begin: begin, end: clock())
    return
  }
  logger.warning("Found no declaration")
  req.reply(.locations([]))
  Timing.INSTANCE.registerMeasurement(name: "definition", begin: begin, end: clock())
}
