import CMesonDocs
import Foundation

public class MesonDocs {
  public let docs: [String: String]
  public let typeDocs: [String: String]

  public init() {
    let cstring = meson_docs_get_as_str()!
    let string = String(cString: cstring)
    let data = string.data(using: .utf8)
    let decoder = JSONDecoder()
    let map = try! decoder.decode([String: [String: String]].self, from: data!)
    self.docs = map["docs"]!
    self.typeDocs = map["typeDocs"]!
  }

  public func findDocs(id: String) -> String? { return self.docs[id] }
}
