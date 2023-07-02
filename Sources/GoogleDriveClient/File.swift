public struct File: Sendable, Equatable, Identifiable, Codable {
  public init(
    id: String,
    name: String
  ) {
    self.id = id
    self.name = name
  }

  public var id: String
  public var name: String
}
