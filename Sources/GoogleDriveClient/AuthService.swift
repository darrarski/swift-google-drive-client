import Dependencies
import Foundation
import XCTestDynamicOverlay

public struct AuthService: Sendable {
  public typealias IsSignedIn = @Sendable () async -> Bool
  public typealias IsSignedInStream = @Sendable () -> AsyncStream<Bool>
  public typealias SignIn = @Sendable () async -> Void
  public typealias HandleRedirect = @Sendable (URL) async throws -> Void
  public typealias SignOut = @Sendable () async -> Void

  public enum Error: Swift.Error, Sendable, Equatable {
    case codeError(String)
    case codeNotFoundInRedirectURL
    case tokenError(statusCode: Int?, data: Data)
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

extension AuthService: DependencyKey {
  public static let liveValue = AuthService(
    isSignedIn: {
      await checkAuth()
      return await isSignedIn.value
    },
    isSignedInStream: {
      Task { await checkAuth() }
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
        URLQueryItem(name: "scope", value: "https://www.googleapis.com/auth/drive.appdata"),
        URLQueryItem(name: "redirect_uri", value: config.redirectURI)
      ]
      let url = components.url!

      await openURL(url)
    },
    handleRedirect: { url in
      @Dependency(\.googleDriveClientConfig) var config
      @Dependency(\.urlSession) var session

      guard url.absoluteString.starts(with: config.redirectURI) else {
        return
      }
      let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
      let code = components?.queryItems?.first(where: { $0.name == "code" })?.value
      let error = components?.queryItems?.first(where: { $0.name == "error" })?.value
      if let error {
        throw Error.codeError(error)
      }
      guard let code else {
        throw Error.codeNotFoundInRedirectURL
      }
      let request: URLRequest = {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "www.googleapis.com"
        components.path = "/oauth2/v4/token"
        let url = components.url!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let params = [
          "code": code,
          "client_id": config.clientID,
          "grant_type": "authorization_code",
          "redirect_uri": config.redirectURI
        ]
        let bodyString = params
          .map { key, value in "\(key)=\(value)" }
          .joined(separator: "&")
        let bodyData = bodyString.data(using: .utf8)
        request.httpBody = bodyData
        return request
      }()
      let (responseData, response) = try await session.data(for: request)
      let statusCode = (response as? HTTPURLResponse)?.statusCode
      guard let statusCode = statusCode, (200..<300).contains(statusCode) else {
        throw Error.tokenError(statusCode: statusCode, data: responseData)
      }
      let decoder = JSONDecoder()
      decoder.keyDecodingStrategy = .convertFromSnakeCase
      let auth = try decoder.decode(Auth.self, from: responseData)
      await saveAuth(auth)
    },
    signOut: {
      await saveAuth(nil)
    }
  )

  private static let isSignedIn = CurrentValueAsyncSequence(false)

  private static func checkAuth() async {
    @Dependency(\.googleDriveClientKeychain) var keychain

    let hasAuth = await keychain.loadAuth() != nil
    if await isSignedIn.value != hasAuth {
      await isSignedIn.setValue(hasAuth)
    }
  }

  private static func saveAuth(_ auth: Auth?) async {
    @Dependency(\.googleDriveClientKeychain) var keychain

    if let auth {
      await keychain.saveAuth(auth)
    } else {
      await keychain.deleteAuth()
    }
    await checkAuth()
  }

  public static let testValue = AuthService(
    isSignedIn: unimplemented("\(Self.self).isSignedIn", placeholder: false),
    isSignedInStream: unimplemented("\(Self.self).isSignedInStream", placeholder: .never),
    signIn: unimplemented("\(Self.self).signIn"),
    handleRedirect: unimplemented("\(Self.self).handleRedirect"),
    signOut: unimplemented("\(Self.self).signOut")
  )

  private static let previewIsSignedIn = CurrentValueAsyncSequence(false)
  public static let previewValue = AuthService(
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
  public var googleDriveClientAuthService: AuthService {
    get { self[AuthService.self] }
    set { self[AuthService.self] = newValue }
  }
}
