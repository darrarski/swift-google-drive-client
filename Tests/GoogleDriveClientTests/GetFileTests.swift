import XCTest
@testable import GoogleDriveClient

final class GetFileTests: XCTestCase {
  func testGetFile() async throws {
    let fileId = "1234"
    let credentials = Credentials(
      accessToken: "access-token-1",
      expiresAt: Date(),
      refreshToken: "refresh-token-1",
      tokenType: "token-type-1"
    )
    let httpRequests = ActorIsolated<[URLRequest]>([])
    let didRefreshToken = ActorIsolated(0)
    let getFile = GetFile.live(
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
          """
          {
            "id": "1234",
            "mimeType": "text/plain",
            "name": "test.txt",
            "createdTime": "2023-07-06T01:00:00.000Z",
            "modifiedTime": "2023-07-06T02:00:00.000Z"
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

    let file = try await getFile(fileId: fileId)

    await didRefreshToken.withValue {
      XCTAssertEqual($0, 1)
    }
    await httpRequests.withValue {
      let url = URL(string: "https://www.googleapis.com/drive/v3/files/\(fileId)?fields=\(File.apiFields)")!
      var expectedRequest = URLRequest(url: url)
      expectedRequest.httpMethod = "GET"
      expectedRequest.allHTTPHeaderFields = [
        "Authorization": "\(credentials.tokenType) \(credentials.accessToken)"
      ]
      XCTAssertEqual($0, [expectedRequest])
    }
    XCTAssertEqual(file, File(
      id: "1234",
      mimeType: "text/plain",
      name: "test.txt",
      createdTime: Calendar(identifier: .gregorian)
        .date(from: DateComponents(
          timeZone: TimeZone(secondsFromGMT: 0),
          year: 2023, month: 7, day: 6, hour: 1
        ))!,
      modifiedTime: Calendar(identifier: .gregorian)
        .date(from: DateComponents(
          timeZone: TimeZone(secondsFromGMT: 0),
          year: 2023, month: 7, day: 6, hour: 2
        ))!
    ))
  }

  func testGetFileErrorResponse() async {
    let getFile = GetFile.live(
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
      _ = try await getFile(fileId: "1234")
      XCTFail("Expected to throw, but didn't")
    } catch {
      XCTAssertEqual(
        error as? GetFile.Error,
        .response(
          statusCode: 500,
          data: "Error!!!".data(using: .utf8)!
        ),
        "Expected to throw response error, got \(error)"
      )
    }
  }

  func testGetFileWhenNotAuthorized() async {
    let getFile = GetFile.live(
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
      _ = try await getFile(.init(fileId: "1234"))
      XCTFail("Expected to throw, but didn't")
    } catch {
      XCTAssertEqual(
        error as? GetFile.Error, .notAuthorized,
        "Expected to throw .notAuthorized, got \(error)"
      )
    }
  }
}
