import XCTest
@testable import GoogleDriveClient

final class DeleteFileTests: XCTestCase {
  func testDeleteFile() async throws {
    let fileId = "1234"
    let credentials = Credentials(
      accessToken: "access-token-1",
      expiresAt: Date(),
      refreshToken: "refresh-token-1",
      tokenType: "token-type-1"
    )
    let httpRequests = ActorIsolated<[URLRequest]>([])
    let didRefreshToken = ActorIsolated(0)
    let deleteFile = DeleteFile.live(
      auth: {
        var auth = Auth.unimplemented()
        auth.refreshToken = {
          await didRefreshToken.withValue { $0 += 1 }
        }
        return auth
      }(),
      keychain: {
        var keychain = Keychain.unimplemented()
        keychain.loadCredentials = { credentials }
        return keychain
      }(),
      httpClient: .init { request in
        await httpRequests.withValue { $0.append(request) }
        return (
          Data(),
          HTTPURLResponse(
            url: URL(filePath: "/"),
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
          )!
        )
      }
    )

    try await deleteFile(.init(
      fileId: fileId,
      supportsAllDrives: true
    ))

    await didRefreshToken.withValue {
      XCTAssertEqual($0, 1)
    }
    await httpRequests.withValue {
      let url = URL(string: "https://www.googleapis.com/drive/v3/files/\(fileId)?supportsAllDrives=true")!
      var expectedRequest = URLRequest(url: url)
      expectedRequest.httpMethod = "DELETE"
      expectedRequest.allHTTPHeaderFields = [
        "Authorization": "\(credentials.tokenType) \(credentials.accessToken)"
      ]
      XCTAssertEqual($0, [expectedRequest])
      XCTAssertNil($0.first?.httpBody)
    }
  }

  func testDeleteFileErrorResponse() async {
    let deleteFile = DeleteFile.live(
      auth: {
        var auth = Auth.unimplemented()
        auth.refreshToken = {}
        return auth
      }(),
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
      try await deleteFile(fileId: "1234")
      XCTFail("Expected to throw, but didn't")
    } catch {
      XCTAssertEqual(
        error as? DeleteFile.Error,
        .response(
          statusCode: 500,
          data: "Error!!!".data(using: .utf8)!
        ),
        "Expected to throw response error, got \(error)"
      )
    }
  }

  func testDeleteFileWhenNotAuthorized() async {
    let deleteFile = DeleteFile.live(
      auth: {
        var auth = Auth.unimplemented()
        auth.refreshToken = {}
        return auth
      }(),
      keychain: {
        var keychain = Keychain.unimplemented()
        keychain.loadCredentials = { nil }
        return keychain
      }(),
      httpClient: .unimplemented()
    )

    do {
      try await deleteFile(.init(fileId: "1234"))
      XCTFail("Expected to throw, but didn't")
    } catch {
      XCTAssertEqual(
        error as? DeleteFile.Error, .notAuthorized,
        "Expected to throw .notAuthorized, got \(error)"
      )
    }
  }
}
