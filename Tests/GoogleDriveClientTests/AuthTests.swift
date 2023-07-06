import XCTest
@testable import GoogleDriveClient

final class AuthTests: XCTestCase {
  func testSignIn() async {
    let didOpenURL = ActorIsolated<[URL]>([])
    let auth = Auth.live(
      config: .test,
      keychain: .unimplemented(),
      dateGenerator: .unimplemented(),
      openURL: .init { url in
        await didOpenURL.withValue {
          $0.append(url)
          return true
        }
      },
      httpClient: .unimplemented()
    )

    await auth.signIn()

    let expectedURL: URL = {
      var components = URLComponents()
      components.scheme = "https"
      components.host = "accounts.google.com"
      components.path = "/o/oauth2/v2/auth"
      components.queryItems = [
        URLQueryItem(name: "client_id", value: Config.test.clientID),
        URLQueryItem(name: "response_type", value: "code"),
        URLQueryItem(name: "scope", value: Config.test.authScope),
        URLQueryItem(name: "redirect_uri", value: Config.test.redirectURI)
      ]
      return components.url!
    }()
    await didOpenURL.withValue {
      XCTAssertEqual($0, [expectedURL])
    }
  }

  func testIgnoreUnrelatedRedirects() async throws {
    let auth = Auth.live(
      config: .test,
      keychain: .unimplemented(),
      dateGenerator: .unimplemented(),
      openURL: .unimplemented(),
      httpClient: .unimplemented()
    )

    try await auth.handleRedirect(URL(string: "https://darrarski.pl")!)
  }

  func testHandleRedirectWithError() async throws {
    let url = URL(string: "\(Config.test.redirectURI)test?error=Failure")!
    let auth = Auth.live(
      config: .test,
      keychain: .unimplemented(),
      dateGenerator: .unimplemented(),
      openURL: .unimplemented(),
      httpClient: .unimplemented()
    )

    do {
      try await auth.handleRedirect(url)
      XCTFail("Expected to throw, but didn't")
    } catch {
      XCTAssertEqual(
        error as? Auth.Error, .codeError("Failure"),
        "Expected to throw .codeError, got \(error)"
      )
    }
  }

  func testHandleRedirectWithoutCode() async {
    let url = URL(string: "\(Config.test.redirectURI)test")!
    let auth = Auth.live(
      config: .test,
      keychain: .unimplemented(),
      dateGenerator: .unimplemented(),
      openURL: .unimplemented(),
      httpClient: .unimplemented()
    )

    do {
      try await auth.handleRedirect(url)
      XCTFail("Expected to throw, but didn't")
    } catch {
      XCTAssertEqual(
        error as? Auth.Error, .codeNotFoundInRedirectURL,
        "Expected to throw codeError, got \(error)"
      )
    }
  }

  func testHandleRedirect() async throws {
    let httpRequests = ActorIsolated<[URLRequest]>([])
    let credentials = ActorIsolated<Credentials?>(nil)
    let date = Date(timeIntervalSince1970: 1_000_000)
    let code = "1234"
    let url = URL(string: "\(Config.test.redirectURI)test?code=\(code)")!
    let auth = Auth.live(
      config: .test,
      keychain: {
        var keychain = Keychain.unimplemented()
        keychain.loadCredentials = { await credentials.value }
        keychain.saveCredentials = { await credentials.setValue($0) }
        return keychain
      }(),
      dateGenerator: .init { date },
      openURL: .unimplemented(),
      httpClient: .init { request in
        await httpRequests.withValue { $0.append(request) }
        return (
          """
          {
            "access_token": "access-token-1",
            "expires_in": 1234,
            "refresh_token": "refresh-token-1",
            "token_type": "token-type-1"
          }
          """.data(using: .utf8)!,
          HTTPURLResponse(
            url: URL(filePath: "/"),
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
          )!
        )
      }
    )

    try await auth.handleRedirect(url)

    await httpRequests.withValue {
      let url = URL(string: "https://www.googleapis.com/oauth2/v4/token")!
      var expectedRequest = URLRequest(url: url)
      expectedRequest.httpMethod = "POST"
      expectedRequest.allHTTPHeaderFields = [
        "Content-Type": "application/x-www-form-urlencoded"
      ]
      expectedRequest.httpBody = [
        "code=\(code)",
        "client_id=\(Config.test.clientID)",
        "grant_type=authorization_code",
        "redirect_uri=\(Config.test.redirectURI)",
      ].joined(separator: "&").data(using: .utf8)!

      XCTAssertEqual($0, [expectedRequest])
    }
    await credentials.withValue {
      XCTAssertEqual($0, Credentials(
        accessToken: "access-token-1",
        expiresAt: date.addingTimeInterval(1234),
        refreshToken: "refresh-token-1",
        tokenType: "token-type-1"
      ))
    }
    let isSignedIn = await auth.isSignedIn()
    XCTAssertTrue(isSignedIn)
  }

  func testHandleRedirectErrorResponse() async {
    let date = Date(timeIntervalSince1970: 1_000_000)
    let url = URL(string: "\(Config.test.redirectURI)test?code=1234")!
    let auth = Auth.live(
      config: .test,
      keychain: {
        var keychain = Keychain.unimplemented()
        keychain.loadCredentials = {
          Credentials(
            accessToken: "",
            expiresAt: Date(),
            refreshToken: "",
            tokenType: ""
          )
        }
        return keychain
      }(),
      dateGenerator: .init { date },
      openURL: .unimplemented(),
      httpClient: .init { request in
        (
          "Error!!!".data(using: .utf8)!,
          HTTPURLResponse(
            url: URL(filePath: "/"),
            statusCode: 500,
            httpVersion: nil,
            headerFields: nil
          )!
        )
      }
    )

    do {
      try await auth.handleRedirect(url)
      XCTFail("Expected to throw, but didn't")
    } catch {
      XCTAssertEqual(
        error as? Auth.Error,
        .response(
          statusCode: 500,
          data: "Error!!!".data(using: .utf8)!
        ),
        "Expected to throw response error, got \(error)"
      )
    }
  }

  func testDontRefreshTokenWithoutCredentials() async throws {
    let auth = Auth.live(
      config: .test,
      keychain: {
        var keychain = Keychain.unimplemented()
        keychain.loadCredentials = { nil }
        return keychain
      }(),
      dateGenerator: .unimplemented(),
      openURL: .unimplemented(),
      httpClient: .unimplemented()
    )

    try await auth.refreshToken()
  }

  func testDontRefreshTokenIfNotExpired() async throws {
    let date = Date(timeIntervalSince1970: 1_000_000)
    let credentials = ActorIsolated<Credentials?>(Credentials(
      accessToken: "",
      expiresAt: date.addingTimeInterval(1),
      refreshToken: "",
      tokenType: ""
    ))
    let auth = Auth.live(
      config: .test,
      keychain: {
        var keychain = Keychain.unimplemented()
        keychain.loadCredentials = { await credentials.value }
        return keychain
      }(),
      dateGenerator: .init { date },
      openURL: .unimplemented(),
      httpClient: .unimplemented()
    )

    try await auth.refreshToken()
  }

  func testRefreshExpiredToken() async throws {
    let httpRequests = ActorIsolated<[URLRequest]>([])
    let date = Date(timeIntervalSince1970: 1_000_000)
    let credentials = ActorIsolated<Credentials?>(Credentials(
      accessToken: "access-token-1",
      expiresAt: date.addingTimeInterval(-1),
      refreshToken: "refresh-token-1",
      tokenType: "token-type-1"
    ))
    let auth = Auth.live(
      config: .test,
      keychain: {
        var keychain = Keychain.unimplemented()
        keychain.loadCredentials = { await credentials.value }
        keychain.saveCredentials = { await credentials.setValue($0) }
        return keychain
      }(),
      dateGenerator: .init { date },
      openURL: .unimplemented(),
      httpClient: .init { request in
        await httpRequests.withValue { $0.append(request) }
        return (
          """
          {
            "access_token": "access-token-2",
            "expires_in": 4321,
            "token_type": "token-type-2"
          }
          """.data(using: .utf8)!,
          HTTPURLResponse(
            url: URL(filePath: "/"),
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
          )!
        )
      }
    )

    try await auth.refreshToken()

    await httpRequests.withValue {
      let url = URL(string: "https://oauth2.googleapis.com/token")!
      var expectedRequest = URLRequest(url: url)
      expectedRequest.httpMethod = "POST"
      expectedRequest.allHTTPHeaderFields = [
        "Content-Type": "application/x-www-form-urlencoded"
      ]
      expectedRequest.httpBody = [
        "client_id=\(Config.test.clientID)",
        "grant_type=refresh_token",
        "refresh_token=refresh-token-1",
      ].joined(separator: "&").data(using: .utf8)!

      XCTAssertEqual($0, [expectedRequest])
    }
    await credentials.withValue {
      XCTAssertEqual($0, Credentials(
        accessToken: "access-token-2",
        expiresAt: date.addingTimeInterval(4321),
        refreshToken: "refresh-token-1",
        tokenType: "token-type-2"
      ))
    }
  }

  func testRefreshTokenErrorResponse() async {
    let date = Date(timeIntervalSince1970: 1_000_000)
    let credentials = ActorIsolated<Credentials?>(Credentials(
      accessToken: "",
      expiresAt: date.addingTimeInterval(-1),
      refreshToken: "refresh-token-1",
      tokenType: "token-type-1"
    ))
    let auth = Auth.live(
      config: .test,
      keychain: {
        var keychain = Keychain.unimplemented()
        keychain.loadCredentials = { await credentials.value }
        keychain.saveCredentials = { await credentials.setValue($0) }
        return keychain
      }(),
      dateGenerator: .init { date },
      openURL: .unimplemented(),
      httpClient: .init { _ in
        (
          "Error!!!".data(using: .utf8)!,
          HTTPURLResponse(
            url: URL(filePath: "/"),
            statusCode: 500,
            httpVersion: nil,
            headerFields: nil
          )!
        )
      }
    )

    do {
      try await auth.refreshToken()
      XCTFail("Expected to throw, but didn't")
    } catch {
      XCTAssertEqual(
        error as? Auth.Error,
        .response(
          statusCode: 500,
          data: "Error!!!".data(using: .utf8)!
        ),
        "Expected to throw response error, got \(error)"
      )
    }
  }

  func testSignOut() async {
    let credentials = ActorIsolated<Credentials?>(Credentials(
      accessToken: "",
      expiresAt: Date(),
      refreshToken: "",
      tokenType: ""
    ))
    let auth = Auth.live(
      config: .test,
      keychain: {
        var keychain = Keychain.unimplemented()
        keychain.loadCredentials = { await credentials.value }
        keychain.deleteCredentials = { await credentials.setValue(nil) }
        return keychain
      }(),
      dateGenerator: .unimplemented(),
      openURL: .unimplemented(),
      httpClient: .unimplemented()
    )

    await auth.signOut()

    await credentials.withValue { XCTAssertNil($0) }
    let isSignedIn = await auth.isSignedIn()
    XCTAssertFalse(isSignedIn)
  }
}
