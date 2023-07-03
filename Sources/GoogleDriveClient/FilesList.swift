public struct FilesList: Sendable, Equatable, Codable {
  public init(
    nextPageToken: String?,
    incompleteSearch: Bool,
    files: [File]
  ) {
    self.nextPageToken = nextPageToken
    self.incompleteSearch = incompleteSearch
    self.files = files
  }

  public var nextPageToken: String?
  public var incompleteSearch: Bool
  public var files: [File]
}

extension FilesList {
  static let apiFields: String = [
    "nextPageToken",
    "incompleteSearch",
    "files(" + File.apiFields + ")",
  ].joined(separator: ",")
}
