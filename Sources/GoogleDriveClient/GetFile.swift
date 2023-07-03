import Dependencies
import Foundation
import XCTestDynamicOverlay

public struct GetFile: Sendable {
  public struct Params: Sendable, Equatable {
    public init(fileId: String) {
      self.fileId = fileId
    }

    public var fileId: String
  }

  public enum Error: Swift.Error, Sendable, Equatable {
    case notAuthorized
    case response(statusCode: Int?, data: Data)
  }

  public typealias Run = @Sendable (Params) async throws -> File

  public init(run: @escaping Run) {
    self.run = run
  }

  public var run: Run

  public func callAsFunction(_ params: Params) async throws -> File {
    try await run(params)
  }

  public func callAsFunction(fileId: String) async throws -> File {
    try await run(.init(fileId: fileId))
  }
}

extension GetFile: DependencyKey {
  public static let liveValue: GetFile = {
    @Dependency(\.googleDriveClientAuth) var auth
    @Dependency(\.googleDriveClientKeychain) var keychain
    @Dependency(\.urlSession) var session

    return GetFile { params in
      try await auth.refreshToken()

      guard let credentials = await keychain.loadCredentials() else {
        throw Error.notAuthorized
      }

      let request: URLRequest = {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "www.googleapis.com"
        components.path = "/drive/v3/files/\(params.fileId)"
        components.queryItems = [
          URLQueryItem(name: "fields", value: File.apiFields),
        ]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.setValue(
          "\(credentials.tokenType) \(credentials.accessToken)",
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
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
      decoder.dateDecodingStrategy = .formatted(dateFormatter)
      return try decoder.decode(File.self, from: responseData)
    }
  }()

  public static let testValue = GetFile(
    run: unimplemented("\(Self.self).run")
  )
}

extension DependencyValues {
  public var googleDriveClientGetFile: GetFile {
    get { self[GetFile.self] }
    set { self[GetFile.self] = newValue }
  }
}
