import Crypto
import Foundation
import INIParser
import IOUtils

public class WrapFileParser {
  private let path: String

  public init(path: String) { self.path = path }

  public func parse() throws -> Wrap {
    #if !os(Windows)
      let ini = try INIParser(self.path)
    #else
      let wincontents = try Path(self.path).read().replacingOccurrences(of: "\r\n", with: "\n")
      let ini = try INIParser(string: wincontents)
    #endif
    let contents = try Path(self.path).read()
    let hash = Data(SHA256.hash(data: contents)).hexStringEncoded()
    let provides = parseProvideSection(ini)
    let mapped = ini.sections.map { ($0, $1) }
    guard let firstSectionKV = mapped.first(where: { $0.0.hasPrefix("wrap-") }) else {
      throw WrapError.noWrapSectionFound("Unable to find ini section starting with wrap- in \(self.path)")
    }
    let name = firstSectionKV.0
    let firstSection = firstSectionKV.1
    let directory = firstSection["directory"]
    let patchURL = firstSection["patch_url"]
    let patchFallbackURL = firstSection["patch_fallback_url"]
    let patchFilename = firstSection["patch_filename"]
    let patchHash = firstSection["patch_hash"]
    let patchDirectory = firstSection["patch_directory"]
    var diffFiles: [String] = []
    if let df = firstSection["diff_files"] {
      diffFiles = Array(df.split(separator: ",").map { $0.description })
    }
    var ret: Wrap?
    if name == "wrap-file" {
      let sourceURL = firstSection["source_url"]
      let sourceFallbackURL = firstSection["source_fallback_url"]
      let sourceFilename = firstSection["source_filename"]
      let sourceHash = firstSection["source_hash"]
      var leadDirectoryMissing = false
      if let ldm = firstSection["lead_directory_missing"] { leadDirectoryMissing = ldm == "true" }
      ret = FileWrap(
        wrapHash: hash,
        directory: directory ?? Path(self.path).lastComponentWithoutExtension,
        patchURL: patchURL,
        patchFallbackURL: patchFallbackURL,
        patchFilename: patchFilename,
        patchHash: patchHash,
        patchDirectory: patchDirectory,
        diffFiles: diffFiles,
        sourceURL: sourceURL,
        sourceFallbackURL: sourceFallbackURL,
        sourceFilename: sourceFilename,
        sourceHash: sourceHash,
        leadDirectoryMissing: leadDirectoryMissing
      )
    } else {
      let url = firstSection["url"]
      let revision = firstSection["revision"]
      if name == "wrap-git" {
        var depth: Int = Int.max
        if let d = firstSection["depth"] { depth = Int(d) ?? depth }
        let pushURL = firstSection["push-url"]
        var cloneRecursive = false
        if let cr = firstSection["clone-recursive"] { cloneRecursive = cr == "true" }
        ret = GitWrap(
          wrapHash: hash,
          directory: directory ?? Path(self.path).lastComponentWithoutExtension,
          patchURL: patchURL,
          patchFallbackURL: patchFallbackURL,
          patchFilename: patchFilename,
          patchHash: patchHash,
          patchDirectory: patchDirectory,
          diffFiles: diffFiles,
          url: url,
          revision: revision,
          depth: depth,
          pushURL: pushURL,
          cloneRecursive: cloneRecursive
        )
      } else if name == "wrap-svn" {
        ret = SvnWrap(
          wrapHash: hash,
          directory: directory ?? Path(self.path).lastComponentWithoutExtension,
          patchURL: patchURL,
          patchFallbackURL: patchFallbackURL,
          patchFilename: patchFilename,
          patchHash: patchHash,
          patchDirectory: patchDirectory,
          diffFiles: diffFiles,
          url: url,
          revision: revision
        )
      } else if name == "wrap-hg" {
        ret = HgWrap(
          wrapHash: hash,
          directory: directory ?? Path(self.path).lastComponentWithoutExtension,
          patchURL: patchURL,
          patchFallbackURL: patchFallbackURL,
          patchFilename: patchFilename,
          patchHash: patchHash,
          patchDirectory: patchDirectory,
          diffFiles: diffFiles,
          url: url,
          revision: revision
        )
      }
    }
    if let r = ret {
      r.applyProvides(provides)
      r.setFile(Path(self.path).normalize().description)
      return r
    }
    throw WrapError.unknownWrapType("Unknown wrap type \(name)")
  }

  func parseProvideSection(_ ini: INIParser) -> Provides {
    let provides = Provides()
    if let provideSection = ini.sections["provide"] {
      for kv in provideSection {
        if kv.0 == "dependency_names" {
          let depnames = kv.1.split(separator: ",").map { $0.description.lowercased() }
          provides.updateDependencyNames(names: depnames)
        } else if kv.0 == "program_names" {
          let programnames = kv.1.split(separator: ",").map { $0.description.lowercased() }
          provides.updateProgramNames(names: programnames)
        } else {
          provides.updateDependencies(name: kv.0, varname: kv.1)
        }
      }
    }
    return provides
  }
}
