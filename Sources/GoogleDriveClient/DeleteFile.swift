import Dependencies
import Foundation
import XCTestDynamicOverlay

public struct DeleteFile: Sendable {
  public struct Params: Sendable, Equatable {
    public init(fileId: String, supportsAllDrives: Bool? = nil) {
      self.fileId = fileId
      self.supportsAllDrives = supportsAllDrives
    }

    public var fileId: String
    public var supportsAllDrives: Bool?
  }

  public enum Error: Swift.Error, Sendable, Equatable {
    case notAuthorized
    case response(statusCode: Int?, data: Data)
  }

  public typealias Run = @Sendable (Params) async throws -> Void

  public init(run: @escaping Run) {
    self.run = run
  }

  public var run: Run

  public func callAsFunction(_ params: Params) async throws {
    try await run(params)
  }
}

extension DeleteFile: DependencyKey {
  public static let liveValue = DeleteFile { params in
    @Dependency(\.googleDriveClientAuth) var auth
    @Dependency(\.googleDriveClientKeychain) var keychain
    @Dependency(\.urlSession) var session

    try await auth.refreshToken()

    guard let credentials = await keychain.loadCredentials() else {
      throw Error.notAuthorized
    }

    let request: URLRequest = {
      var components = URLComponents()
      components.scheme = "https"
      components.host = "www.googleapis.com"
      components.path = "/drive/v3/files/\(params.fileId)"
      var queryItems: [URLQueryItem] = []
      if let supportsAllDrives = params.supportsAllDrives {
        let value = supportsAllDrives ? "true" : "false"
        queryItems.append(URLQueryItem(name: "supportsAllDrives", value: value))
      }
      if !queryItems.isEmpty {
        components.queryItems = queryItems
      }

      var request = URLRequest(url: components.url!)
      request.httpMethod = "DELETE"
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
  }

  public static let testValue = DeleteFile(
    run: unimplemented("\(Self.self).run")
  )
}

extension DependencyValues {
  public var googleDriveClientDeleteFile: DeleteFile {
    get { self[DeleteFile.self] }
    set { self[DeleteFile.self] = newValue }
  }
}
