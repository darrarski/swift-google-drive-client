import Foundation

public struct UpdateFile: Sendable {
  public struct Params: Sendable, Equatable {
    public struct Metadata: Sendable, Equatable, Encodable {
      public init(
        mimeType: String
      ) {
        self.mimeType = mimeType
      }

      public var mimeType: String
    }

    public init(
      fileId: String,
      data: Data,
      metadata: Metadata
    ) {
      self.fileId = fileId
      self.data = data
      self.metadata = metadata
    }

    public var fileId: String
    public var data: Data
    public var metadata: Metadata
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

  public func callAsFunction(
    fileId: String,
    data: Data,
    mimeType: String
  ) async throws -> File {
    try await run(.init(
      fileId: fileId,
      data: data,
      metadata: .init(
        mimeType: mimeType
      )
    ))
  }
}

extension UpdateFile {
  public static func live(
    auth: Auth,
    keychain: Keychain,
    urlSession: URLSession,
    uuidGenerator uuid: @escaping () -> UUID
  ) -> UpdateFile {
    UpdateFile { params in
      try await auth.refreshToken()

      guard let credentials = await keychain.loadCredentials() else {
        throw Error.notAuthorized
      }

      let request: URLRequest = try {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "www.googleapis.com"
        components.path = "/upload/drive/v3/files/\(params.fileId)"
        components.queryItems = [
          URLQueryItem(name: "uploadType", value: "multipart"),
          URLQueryItem(name: "fields", value: File.apiFields),
        ]

        let encoder = JSONEncoder()
        let metadataData = try encoder.encode(params.metadata)

        var formData = Data()
        let formBoundary = uuid().uuidString
        formData.append("\r\n--\(formBoundary)".data(using: .utf8)!)
        formData.append("\r\nContent-Type: application/json; charset=UTF-8".data(using: .utf8)!)
        formData.append("\r\n\r\n".data(using: .utf8)!)
        formData.append(metadataData)
        formData.append("\r\n--\(formBoundary)".data(using: .utf8)!)
        formData.append("\r\nContent-Type: \(params.metadata.mimeType)".data(using: .utf8)!)
        formData.append("\r\nContent-Transfer-Encoding: base64".data(using: .utf8)!)
        formData.append("\r\n\r\n".data(using: .utf8)!)
        formData.append(params.data.base64EncodedData())
        formData.append("\r\n--\(formBoundary)--".data(using: .utf8)!)

        var request = URLRequest(url: components.url!)
        request.httpMethod = "PATCH"
        request.setValue(
          "\(credentials.tokenType) \(credentials.accessToken)",
          forHTTPHeaderField: "Authorization"
        )
        request.setValue(
          "multipart/related; boundary=\(formBoundary)",
          forHTTPHeaderField: "Content-Type"
        )
        request.httpBody = formData

        return request
      }()

      let (responseData, response) = try await urlSession.data(for: request)
      let statusCode = (response as? HTTPURLResponse)?.statusCode

      guard let statusCode, (200..<300).contains(statusCode) else {
        throw Error.response(statusCode: statusCode, data: responseData)
      }

      return try JSONDecoder.api.decode(File.self, from: responseData)
    }
  }
}
