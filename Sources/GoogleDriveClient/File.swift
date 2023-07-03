import Foundation

public struct File: Sendable, Equatable, Identifiable, Codable {
  public init(
    id: String,
    mimeType: String,
    name: String,
    createdTime: Date,
    modifiedTime: Date
  ) {
    self.id = id
    self.mimeType = mimeType
    self.name = name
    self.createdTime = createdTime
    self.modifiedTime = modifiedTime
  }

  public var id: String
  public var mimeType: String
  public var name: String
  public var createdTime: Date
  public var modifiedTime: Date
}

extension File {
  static var apiFields: String = [
    "id",
    "mimeType",
    "name",
    "createdTime",
    "modifiedTime",
  ].joined(separator: ",")
}
