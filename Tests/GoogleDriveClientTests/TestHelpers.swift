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

extension Client {
  static func unimplemented(
    file: StaticString = #filePath,
    line: UInt = #line
  ) -> Client {
    Client(
      auth: .unimplemented(file: file, line: line),
      listFiles: .unimplemented(file: file, line: line),
      getFile: .unimplemented(file: file, line: line),
      getFileData: .unimplemented(file: file, line: line),
      createFile: .unimplemented(file: file, line: line),
      updateFile: .unimplemented(file: file, line: line),
      deleteFile: .unimplemented(file: file, line: line)
    )
  }
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

extension ListFiles {
  static func unimplemented(
    file: StaticString = #filePath,
    line: UInt = #line
  ) -> ListFiles {
    ListFiles { _ in
      XCTFail("Unimplemented: \(Self.self)", file: file, line: line)
      throw UnimplementedError()
    }
  }
}

extension GetFile {
  static func unimplemented(
    file: StaticString = #filePath,
    line: UInt = #line
  ) -> GetFile {
    GetFile { _ in
      XCTFail("Unimplemented: \(Self.self)", file: file, line: line)
      throw UnimplementedError()
    }
  }
}

extension GetFileData {
  static func unimplemented(
    file: StaticString = #filePath,
    line: UInt = #line
  ) -> GetFileData {
    GetFileData { _ in
      XCTFail("Unimplemented: \(Self.self)", file: file, line: line)
      throw UnimplementedError()
    }
  }
}

extension CreateFile {
  static func unimplemented(
    file: StaticString = #filePath,
    line: UInt = #line
  ) -> CreateFile {
    CreateFile { _ in
      XCTFail("Unimplemented: \(Self.self)", file: file, line: line)
      throw UnimplementedError()
    }
  }
}

extension UpdateFile {
  static func unimplemented(
    file: StaticString = #filePath,
    line: UInt = #line
  ) -> UpdateFile {
    UpdateFile { _ in
      XCTFail("Unimplemented: \(Self.self)", file: file, line: line)
      throw UnimplementedError()
    }
  }
}

extension DeleteFile {
  static func unimplemented(
    file: StaticString = #filePath,
    line: UInt = #line
  ) -> DeleteFile {
    DeleteFile { _ in
      XCTFail("Unimplemented: \(Self.self)", file: file, line: line)
      throw UnimplementedError()
    }
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
