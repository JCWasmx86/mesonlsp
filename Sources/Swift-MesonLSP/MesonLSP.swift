import ArgumentParser
import Foundation
import MesonAST
import MesonAnalyze
import SwiftTreeSitter
import TreeSitterMeson

@main
public struct MesonLSP: ParsableCommand {
  public init() {

  }
  @Argument
  var path: String = "./meson.build"

  public mutating func run() throws {
    try MesonTree(file: self.path)
  }
}
