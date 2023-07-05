import Foundation

public struct HTTPClient: Sendable {
  public typealias DataForRequest = @Sendable (URLRequest) async throws -> (Data, URLResponse)

  public init(dataForRequest: @escaping DataForRequest) {
    self.dataForRequest = dataForRequest
  }

  public var dataForRequest: DataForRequest

  public func data(for urlRequest: URLRequest) async throws -> (Data, URLResponse) {
    try await dataForRequest(urlRequest)
  }
}

extension HTTPClient {
  public static func urlSession(_ urlSession: URLSession = .shared) -> HTTPClient {
    HTTPClient { request in
      try await urlSession.data(for: request)
    }
  }
}
