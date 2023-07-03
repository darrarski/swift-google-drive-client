public struct File: Sendable, Equatable, Identifiable, Codable {
  public init(
    id: String,
    mimeType: String,
    name: String
  ) {
    self.id = id
    self.mimeType = mimeType
    self.name = name
  }

  public var id: String
  public var mimeType: String
  public var name: String
}

extension File {
  static var apiFields: String = [
    "id",
    "mimeType",
    "name",
  ].joined(separator: ",")
}
