import Foundation
import IOUtils
import LanguageServerProtocol
import Logging
import MesonAnalyze
import Timing

internal func findDefinition(
  _ tree: MesonTree?,
  _ req: DefinitionRequest,
  _ mapper: FileMapper,
  _ logger: Logger
) -> LocationsOrLocationLinksResponse {
  let begin = clock()
  let location = req.position
  let file = mapper.fromSubprojectToCache(file: req.textDocument.uri.fileURL!.path)
  if let t = tree, let i = t.metadata!.findIdentifierAt(file, location.line, location.utf16index),
    let t = t.findDeclaration(node: i)
  {
    let newFile = t.0
    let line = t.1[0]
    let column = t.1[1]
    let range = Range(LanguageServerProtocol.Position(line: Int(line), utf16index: Int(column)))
    logger.info("Found definition: \(newFile)[\(line):\(column)]")
    Timing.INSTANCE.registerMeasurement(name: "definition", begin: begin, end: clock())
    return .locations([
      .init(
        uri: DocumentURI(URL(fileURLWithPath: mapper.fromCacheToSubproject(file: newFile))),
        range: range
      )
    ])
  }

  if let t = tree, let sd = t.metadata!.findSubdirCallAt(file, location.line, location.utf16index) {
    let path = Path(
      Path(file).parent().description + Path.separator + sd.subdirname
        + "\(Path.separator)meson.build"
    ).description
    let range = Range(LanguageServerProtocol.Position(line: Int(0), utf16index: Int(0)))
    Timing.INSTANCE.registerMeasurement(name: "definition", begin: begin, end: clock())
    logger.info("Found definition: \(path):\(range)")
    return .locations([
      .init(
        uri: DocumentURI(URL(fileURLWithPath: mapper.fromCacheToSubproject(file: path))),
        range: range
      )
    ])
  }
  logger.warning("Found no declaration")
  Timing.INSTANCE.registerMeasurement(name: "definition", begin: begin, end: clock())
  return .locations([])
}
