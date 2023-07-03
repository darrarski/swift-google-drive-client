import Dependencies
import Foundation
import XCTestDynamicOverlay

public struct Auth: Sendable {
  public typealias IsSignedIn = @Sendable () async -> Bool
  public typealias IsSignedInStream = @Sendable () -> AsyncStream<Bool>
  public typealias SignIn = @Sendable () async -> Void
  public typealias HandleRedirect = @Sendable (URL) async throws -> Void
  public typealias RefreshToken = @Sendable () async throws -> Void
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
    refreshToken: @escaping RefreshToken,
    signOut: @escaping SignOut
  ) {
    self.isSignedIn = isSignedIn
    self.isSignedInStream = isSignedInStream
    self.signIn = signIn
    self.handleRedirect = handleRedirect
    self.refreshToken = refreshToken
    self.signOut = signOut
  }

  public var isSignedIn: IsSignedIn
  public var isSignedInStream: IsSignedInStream
  public var signIn: SignIn
  public var handleRedirect: HandleRedirect
  public var refreshToken: RefreshToken
  public var signOut: SignOut
}

extension Auth: DependencyKey {
  public static let liveValue: Auth = {
    @Dependency(\.googleDriveClientKeychain) var keychain
    @Dependency(\.googleDriveClientConfig) var config
    @Dependency(\.date) var date
    @Dependency(\.openURL) var openURL
    @Dependency(\.urlSession) var session

    let isSignedIn = CurrentValueAsyncSequence(false)

    @Sendable
    func checkSignedIn() async {
      let value = await keychain.loadCredentials() != nil
      if await isSignedIn.value != value {
        await isSignedIn.setValue(value)
      }
    }

    @Sendable
    func loadCredentials() async -> Credentials? {
      await keychain.loadCredentials()
    }

    @Sendable
    func saveCredentials(_ credentials: Credentials?) async {
      if let credentials {
        await keychain.saveCredentials(credentials)
      } else {
        await keychain.deleteCredentials()
      }
      await checkSignedIn()
    }

    return Auth(
      isSignedIn: {
        await checkSignedIn()
        return await isSignedIn.value
      },
      isSignedInStream: {
        Task { await checkSignedIn() }
        return isSignedIn.eraseToStream()
      },
      signIn: {
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

        struct ResponseBody: Decodable {
          var accessToken: String
          var expiresIn: Int
          var refreshToken: String
          var tokenType: String
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let responseBody = try decoder.decode(ResponseBody.self, from: responseData)
        let credentials = Credentials(
          accessToken: responseBody.accessToken,
          expiresAt: Date(
            timeInterval: TimeInterval(responseBody.expiresIn),
            since: date.now
          ),
          refreshToken: responseBody.refreshToken,
          tokenType: responseBody.tokenType
        )

        await saveCredentials(credentials)
      },
      refreshToken: {
        guard let credentials = await loadCredentials() else { return }
        guard credentials.expiresAt <= date.now else { return }

        let request: URLRequest = {
          var components = URLComponents()
          components.scheme = "https"
          components.host = "oauth2.googleapis.com"
          components.path = "/token"

          var request = URLRequest(url: components.url!)
          request.httpMethod = "POST"
          request.setValue(
            "application/x-www-form-urlencoded",
            forHTTPHeaderField: "Content-Type"
          )
          request.httpBody = [
            "client_id": config.clientID,
            "grant_type": "refresh_token",
            "refresh_token": credentials.refreshToken
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

        struct ResponseBody: Decodable {
          var accessToken: String
          var expiresIn: Int
          var tokenType: String
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let responseBody = try decoder.decode(ResponseBody.self, from: responseData)
        let newCredentials = Credentials(
          accessToken: responseBody.accessToken,
          expiresAt: Date(
            timeInterval: TimeInterval(responseBody.expiresIn),
            since: date.now
          ),
          refreshToken: credentials.refreshToken,
          tokenType: responseBody.tokenType
        )

        await saveCredentials(newCredentials)
      },
      signOut: {
        await saveCredentials(nil)
      }
    )
  }()

  public static let testValue = Auth(
    isSignedIn: unimplemented("\(Self.self).isSignedIn", placeholder: false),
    isSignedInStream: unimplemented("\(Self.self).isSignedInStream", placeholder: .finished),
    signIn: unimplemented("\(Self.self).signIn"),
    handleRedirect: unimplemented("\(Self.self).handleRedirect"),
    refreshToken: unimplemented("\(Self.self).refreshToken"),
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
    refreshToken: {},
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
