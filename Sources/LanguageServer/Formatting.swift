import Foundation
import LanguageServerProtocol
import Logging

func formatFile(content: String, params: FormattingOptions, muonPath: String?) throws -> String? {
  if let cfgFile = writeCfgFile(params: params), let muon = findMuon(muonPath) {
    Logger(label: "formatting").info("muon path: \(muon)")
    let task = Process()
    let pipe = Pipe()
    let inPipe = Pipe()
    task.standardOutput = pipe
    task.arguments = ["fmt", "-c", cfgFile, "-"]
    inPipe.fileHandleForWriting.write(Data(content.utf8))
    inPipe.fileHandleForWriting.closeFile()
    task.standardInput = inPipe
    task.executableURL = URL(fileURLWithPath: muon)
    try task.run()
    task.waitUntilExit()
    if task.terminationStatus != 0 { return nil }
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    return String(data: data, encoding: .utf8)
  }
  return nil
}

private func findMuon(_ muonPath: String?) -> String? {
  if muonPath != nil {
    Logger(label: "formatting").info("Using user-provided muon path: \(muonPath!)")
    return muonPath!
  }
  if let path = ProcessInfo.processInfo.environment["PATH"] {
    let fileManager = FileManager.default
    #if os(Windows)
      let parts = path.split(separator: ";")
      for p in parts where fileManager.fileExists(atPath: p + "\\muon.exe") {
        return p + "\\muon.exe"
      }
    #else
      let parts = path.split(separator: ":")
      for p in parts where fileManager.fileExists(atPath: p + "/muon") { return p + "/muon" }
    #endif
  }
  return nil
}

private func writeCfgFile(params: FormattingOptions) -> String? {
  var str = ""
  str += "max_line_len = 100\n"
  str += "space_array = false\n"
  str += "kwargs_force_multiline = true\n"
  str += "wide_colon = false\n"
  str += "no_single_comma_function = false\n"
  let indentstr = params.insertSpaces ? String(repeating: " ", count: params.tabSize) : "\t"
  str += "indent_by = '\(indentstr)'\n"
  let fileManager = FileManager.default
  let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
  let fileName = UUID().uuidString
  let fileURL = cacheDir!.appendingPathComponent(fileName)
  fileManager.createFile(atPath: fileURL.path, contents: Data(str.utf8))
  return fileURL.path
}
