import Dependencies
import Foundation
import XCTestDynamicOverlay

public struct Auth: Sendable {
  public typealias IsSignedIn = @Sendable () async -> Bool
  public typealias IsSignedInStream = @Sendable () -> AsyncStream<Bool>
  public typealias SignIn = @Sendable () async -> Void
  public typealias HandleRedirect = @Sendable (URL) async throws -> Void
  public typealias SignOut = @Sendable () async -> Void

  public enum Error: Swift.Error, Sendable, Equatable {
    case codeError(String)
    case codeNotFoundInRedirectURL
    case response(statusCode: Int?, data: Data)
  }

  public init(
    isSignedIn: @escaping IsSignedIn,
    isSignedInStream: @escaping IsSignedInStream,
    signIn: @escaping SignIn,
    handleRedirect: @escaping HandleRedirect,
    signOut: @escaping SignOut
  ) {
    self.isSignedIn = isSignedIn
    self.isSignedInStream = isSignedInStream
    self.signIn = signIn
    self.handleRedirect = handleRedirect
    self.signOut = signOut
  }

  public var isSignedIn: IsSignedIn
  public var isSignedInStream: IsSignedInStream
  public var signIn: SignIn
  public var handleRedirect: HandleRedirect
  public var signOut: SignOut
}

extension Auth: DependencyKey {
  public static let liveValue = Auth(
    isSignedIn: {
      await checkSignedIn()
      return await isSignedIn.value
    },
    isSignedInStream: {
      Task { await checkSignedIn() }
      return isSignedIn.eraseToStream()
    },
    signIn: {
      @Dependency(\.googleDriveClientConfig) var config
      @Dependency(\.openURL) var openURL

      var components = URLComponents()
      components.scheme = "https"
      components.host = "accounts.google.com"
      components.path = "/o/oauth2/v2/auth"
      components.queryItems = [
        URLQueryItem(name: "client_id", value: config.clientID),
        URLQueryItem(name: "response_type", value: "code"),
        URLQueryItem(name: "scope", value: config.authScope),
        URLQueryItem(name: "redirect_uri", value: config.redirectURI)
      ]
      let url = components.url!

      await openURL(url)
    },
    handleRedirect: { url in
      @Dependency(\.googleDriveClientConfig) var config
      @Dependency(\.urlSession) var session

      guard url.absoluteString.starts(with: config.redirectURI) else { return }

      let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
      let code = components?.queryItems?.first(where: { $0.name == "code" })?.value
      let error = components?.queryItems?.first(where: { $0.name == "error" })?.value

      if let error { throw Error.codeError(error) }
      guard let code else { throw Error.codeNotFoundInRedirectURL }

      let request: URLRequest = {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "www.googleapis.com"
        components.path = "/oauth2/v4/token"

        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue(
          "application/x-www-form-urlencoded",
          forHTTPHeaderField: "Content-Type"
        )
        request.httpBody = [
          "code": code,
          "client_id": config.clientID,
          "grant_type": "authorization_code",
          "redirect_uri": config.redirectURI
        ].map { key, value in "\(key)=\(value)" }
          .joined(separator: "&")
          .data(using: .utf8)

        return request
      }()

      let (responseData, response) = try await session.data(for: request)
      let statusCode = (response as? HTTPURLResponse)?.statusCode

      guard let statusCode, (200..<300).contains(statusCode) else {
        throw Error.response(statusCode: statusCode, data: responseData)
      }

      let decoder = JSONDecoder()
      decoder.keyDecodingStrategy = .convertFromSnakeCase
      let credentials = try decoder.decode(Credentials.self, from: responseData)

      await saveCredentials(credentials)
    },
    signOut: {
      await saveCredentials(nil)
    }
  )

  private static let isSignedIn = CurrentValueAsyncSequence(false)

  private static func checkSignedIn() async {
    @Dependency(\.googleDriveClientKeychain) var keychain

    let isSignedIn = await keychain.loadCredentials() != nil
    if await Self.isSignedIn.value != isSignedIn {
      await Self.isSignedIn.setValue(isSignedIn)
    }
  }

  private static func saveCredentials(_ credentials: Credentials?) async {
    @Dependency(\.googleDriveClientKeychain) var keychain

    if let credentials {
      await keychain.saveCredentials(credentials)
    } else {
      await keychain.deleteCredentials()
    }
    await checkSignedIn()
  }

  public static let testValue = Auth(
    isSignedIn: unimplemented("\(Self.self).isSignedIn", placeholder: false),
    isSignedInStream: unimplemented("\(Self.self).isSignedInStream", placeholder: .finished),
    signIn: unimplemented("\(Self.self).signIn"),
    handleRedirect: unimplemented("\(Self.self).handleRedirect"),
    signOut: unimplemented("\(Self.self).signOut")
  )

  private static let previewIsSignedIn = CurrentValueAsyncSequence(false)

  public static let previewValue = Auth(
    isSignedIn: {
      await previewIsSignedIn.value
    },
    isSignedInStream: {
      previewIsSignedIn.eraseToStream()
    },
    signIn: {
      await previewIsSignedIn.setValue(true)
    },
    handleRedirect: { _ in },
    signOut: {
      await previewIsSignedIn.setValue(false)
    }
  )
}

extension DependencyValues {
  public var googleDriveClientAuth: Auth {
    get { self[Auth.self] }
    set { self[Auth.self] = newValue }
  }
}
