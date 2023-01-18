import MesonAST

public protocol MesonChecker { func check(node: Node, metadata: MesonMetadata) }
