import Dependencies
import Foundation
import XCTestDynamicOverlay

public struct ListFiles: Sendable {
  public struct Params: Sendable, Equatable {
    public enum Corpora: String, Sendable, Equatable {
      case user, domain, drive, allDrives
    }

    public enum Space: String, Sendable, Equatable {
      case drive, appDataFolder
    }

    public struct OrderBy: Sendable, Equatable, Hashable {
      public static let createdTime = OrderBy("createdTime")
      public static let folder = OrderBy("folder")
      public static let modifiedByMeTime = OrderBy("modifiedByMeTime")
      public static let modifiedTime = OrderBy("modifiedTime")
      public static let name = OrderBy("name")
      public static let name_natural = OrderBy("name_natural")
      public static let quotaBytesUsed = OrderBy("quotaBytesUsed")
      public static let recency = OrderBy("recency")
      public static let sharedWithMeTime = OrderBy("sharedWithMeTime")
      public static let starred = OrderBy("starred")
      public static let viewedByMeTime = OrderBy("viewedByMeTime")

      public init(_ field: String, descending: Bool = false) {
        self.field = field
        self.descending = descending
      }
      
      public var field: String
      public var descending: Bool

      public func desc() -> OrderBy {
        OrderBy(field, descending: true)
      }

      var string: String { "\(field)\(descending ? " desc" : "")" }
    }

    public init(
      corpora: ListFiles.Params.Corpora? = nil,
      driveId: String? = nil,
      includeItemsFromAllDrives: Bool? = nil,
      orderBy: Set<OrderBy> = [],
      pageSize: Int? = nil,
      pageToken: String? = nil,
      query: String? = nil,
      spaces: Set<Space> = [],
      supportsAllDrives: Bool? = nil
    ) {
      self.corpora = corpora
      self.driveId = driveId
      self.includeItemsFromAllDrives = includeItemsFromAllDrives
      self.orderBy = orderBy
      self.pageSize = pageSize
      self.pageToken = pageToken
      self.query = query
      self.spaces = spaces
      self.supportsAllDrives = supportsAllDrives
    }

    public var corpora: Corpora?
    public var driveId: String?
    public var includeItemsFromAllDrives: Bool?
    public var orderBy: Set<OrderBy>
    public var pageSize: Int?
    public var pageToken: String?
    public var query: String?
    public var spaces: Set<Space>
    public var supportsAllDrives: Bool?
  }

  public enum Error: Swift.Error, Sendable, Equatable {
    case notAuthorized
    case response(statusCode: Int?, data: Data)
  }

  public typealias Run = @Sendable (Params) async throws -> FilesList

  public init(run: @escaping Run) {
    self.run = run
  }

  public var run: Run

  public func callAsFunction(_ parameters: Params) async throws -> FilesList {
    try await run(parameters)
  }
}

extension ListFiles: DependencyKey {
  public static let liveValue = ListFiles(
    run: { params in
      @Dependency(\.googleDriveClientKeychain) var keychain
      @Dependency(\.urlSession) var session

      guard let auth = await keychain.loadAuth() else {
        throw Error.notAuthorized
      }

      let request: URLRequest = {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "www.googleapis.com"
        components.path = "/drive/v3/files"

        var queryItems: [URLQueryItem] = []
        if let corpora = params.corpora {
          queryItems.append(URLQueryItem(name: "corpora", value: corpora.rawValue))
        }
        if let driveId = params.driveId {
          queryItems.append(URLQueryItem(name: "driveId", value: driveId))
        }
        if let includeItemsFromAllDrives = params.includeItemsFromAllDrives {
          let value = includeItemsFromAllDrives ? "true" : "false"
          queryItems.append(URLQueryItem(name: "includeItemsFromAllDrives", value: value))
        }
        if !params.orderBy.isEmpty {
          let value = params.orderBy.map(\.string).joined(separator: ",")
          queryItems.append(URLQueryItem(name: "orderBy", value: value))
        }
        if let pageSize = params.pageSize {
          queryItems.append(URLQueryItem(name: "orderBy", value: "\(pageSize)"))
        }
        if let pageToken = params.pageToken {
          queryItems.append(URLQueryItem(name: "pageToken", value: pageToken))
        }
        if let query = params.query {
          queryItems.append(URLQueryItem(name: "q", value: query))
        }
        if !params.spaces.isEmpty {
          let value = params.spaces.map(\.rawValue).joined(separator: ",")
          queryItems.append(URLQueryItem(name: "spaces", value: value))
        }
        if let supportsAllDrives = params.supportsAllDrives {
          let value = supportsAllDrives ? "true" : "false"
          queryItems.append(URLQueryItem(name: "supportsAllDrives", value: value))
        }
        components.queryItems = queryItems

        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.setValue(
          "\(auth.tokenType) \(auth.accessToken)",
          forHTTPHeaderField: "Authorization"
        )
        return request
      }()

      let (responseData, response) = try await session.data(for: request)
      let statusCode = (response as? HTTPURLResponse)?.statusCode

      guard let statusCode, (200..<300).contains(statusCode) else {
        throw Error.response(statusCode: statusCode, data: responseData)
      }

      let decoder = JSONDecoder()
      return try decoder.decode(FilesList.self, from: responseData)
    }
  )

  public static let previewValue = ListFiles(
    run: { _ in 
      FilesList(
        nextPageToken: nil,
        incompleteSearch: false,
        files: [
          File(id: "preview-1", mimeType: "preview", name: "Preview 1"),
          File(id: "preview-2", mimeType: "preview", name: "Preview 2"),
          File(id: "preview-3", mimeType: "preview", name: "Preview 3"),
        ]
      )
    }
  )

  public static let testValue = ListFiles(
    run: unimplemented("\(Self.self).run")
  )
}

extension DependencyValues {
  public var googleDriveClientListFiles: ListFiles {
    get { self[ListFiles.self] }
    set { self[ListFiles.self] = newValue }
  }
}
