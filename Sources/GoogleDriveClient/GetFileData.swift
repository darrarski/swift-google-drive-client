import Dependencies
import Foundation
import XCTestDynamicOverlay

public struct GetFileData: Sendable {
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

  public typealias Run = @Sendable (Params) async throws -> Data

  public init(run: @escaping Run) {
    self.run = run
  }

  public var run: Run

  public func callAsFunction(_ params: Params) async throws -> Data {
    try await run(params)
  }

  public func callAsFunction(fileId: String) async throws -> Data {
    try await run(.init(fileId: fileId))
  }
}

extension GetFileData: DependencyKey {
  public static let liveValue: GetFileData = {
    @Dependency(\.googleDriveClientAuth) var auth
    @Dependency(\.googleDriveClientKeychain) var keychain
    @Dependency(\.urlSession) var session

    return GetFileData { params in
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
          URLQueryItem(name: "alt", value: "media")
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

      return responseData
    }
  }()

  public static let testValue = GetFileData(
    run: unimplemented("\(Self.self).run")
  )
}

extension DependencyValues {
  public var googleDriveClientGetFileData: GetFileData {
    get { self[GetFileData.self] }
    set { self[GetFileData.self] = newValue }
  }
}
