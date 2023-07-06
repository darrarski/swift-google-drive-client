import GoogleDriveClient
import XCTest

struct UnimplementedError: Error {}

extension Config {
  static let test = Config(
    clientID: "test-client-id",
    authScope: "test-auth-scope",
    redirectURI: "test-redirect-uri://"
  )
}

extension Auth {
  static func unimplemented(
    file: StaticString = #filePath,
    line: UInt = #line
  ) -> Auth {
    Auth(
      isSignedIn: {
        XCTFail("Unimplemented: \(Self.self).isSignedIn", file: file, line: line)
        return false
      },
      isSignedInStream: {
        XCTFail("Unimplemented: \(Self.self).isSignedInStream", file: file, line: line)
        return AsyncStream { nil }
      },
      signIn: {
        XCTFail("Unimplemented: \(Self.self).signIn", file: file, line: line)
      },
      handleRedirect: { _ in
        XCTFail("Unimplemented: \(Self.self).handleRedirect", file: file, line: line)
        throw UnimplementedError()
      },
      refreshToken: {
        XCTFail("Unimplemented: \(Self.self).refreshToken", file: file, line: line)
        throw UnimplementedError()
      },
      signOut: {
        XCTFail("Unimplemented: \(Self.self).signOut", file: file, line: line)
      }
    )
  }
}

extension Keychain {
  static func unimplemented(
    file: StaticString = #filePath,
    line: UInt = #line
  ) -> Keychain {
    Keychain(
      loadCredentials: {
        XCTFail("Unimplemented: \(Self.self).loadCredentials", file: file, line: line)
        return nil
      },
      saveCredentials: { _ in
        XCTFail("Unimplemented: \(Self.self).saveCredentials", file: file, line: line)
      },
      deleteCredentials: {
        XCTFail("Unimplemented: \(Self.self).deleteCredentials", file: file, line: line)
      }
    )
  }
}

extension DateGenerator {
  static func unimplemented(
    file: StaticString = #filePath,
    line: UInt = #line
  ) -> DateGenerator {
    DateGenerator {
      XCTFail("Unimplemented: \(Self.self)", file: file, line: line)
      return .distantPast
    }
  }
}

extension UUIDGenerator {
  static func unimplemented(
    file: StaticString = #filePath,
    line: UInt = #line
  ) -> UUIDGenerator {
    UUIDGenerator {
      XCTFail("Unimplemented: \(Self.self)", file: file, line: line)
      return UUID()
    }
  }
}

extension HTTPClient {
  static func unimplemented(
    file: StaticString = #filePath,
    line: UInt = #line
  ) -> HTTPClient {
    HTTPClient { _ in
      XCTFail("Unimplemented: \(Self.self)", file: file, line: line)
      throw UnimplementedError()
    }
  }
}

extension OpenURL {
  static func unimplemented(
    file: StaticString = #filePath,
    line: UInt = #line
  ) -> OpenURL {
    OpenURL { _ in
      XCTFail("Unimplemented: \(Self.self)", file: file, line: line)
      return false
    }
  }
}
