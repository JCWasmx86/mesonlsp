import Foundation
import LanguageServerProtocol
import Logging

func formatFile(content: String, params: FormattingOptions, muonPath: String?) throws -> String? {
  if let cfgFile = writeCfgFile(params: params), let muon = findMuon(muonPath) {
    Logger(label: "formatting").info("muon path: \(muon)")
    let task = Process()
    let pipe = Pipe()
    let inPipe = Pipe()
    let errorPipe = Pipe()
    task.standardOutput = pipe
    task.standardError = errorPipe
    task.arguments = ["fmt", "-c", cfgFile, "-"]
    task.standardInput = inPipe
    task.executableURL = URL(fileURLWithPath: muon)
    try task.run()
    for i in stride(from: 0, to: content.count, by: 4096) {
      let chunkEnd = min(i + 4096, content.count)
      let chunk = content[i..<chunkEnd]
      inPipe.fileHandleForWriting.write(Data(chunk.utf8))
    }
    inPipe.fileHandleForWriting.closeFile()
    var resultData = Data()
    while task.isRunning {
      let readData = pipe.fileHandleForReading.readData(ofLength: 128)
      resultData.append(readData)
    }
    task.waitUntilExit()
    if task.terminationStatus != 0 {
      let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
      Logger(label: "formatting").error(
        "Formatting failed:\n\(String(data: errorData, encoding: .utf8) ?? "<<>>")"
      )
      return nil
    }
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    resultData.append(data)
    return String(data: resultData, encoding: .utf8)
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
