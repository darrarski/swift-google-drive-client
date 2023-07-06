import XCTest
@testable import GoogleDriveClient

final class UpdateFileDataTests: XCTestCase {
  func testUpdateFileData() async throws {
    let credentials = Credentials(
      accessToken: "access-token-1",
      expiresAt: Date(),
      refreshToken: "refresh-token-1",
      tokenType: "token-type-1"
    )
    let httpRequests = ActorIsolated<[URLRequest]>([])
    let didRefreshToken = ActorIsolated(0)
    let uuid = UUID()
    let updateFileData = UpdateFileData.live(
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
      },
      uuidGenerator: .init { uuid }
    )
    let params = UpdateFileData.Params(
      fileId: "file-id",
      data: "file data".data(using: .utf8)!,
      metadata: .init(
        mimeType: "text/plain"
      )
    )

    let file = try await updateFileData(params)

    await didRefreshToken.withValue {
      XCTAssertEqual($0, 1)
    }
    await httpRequests.withValue {
      let url = URL(string: "https://www.googleapis.com/upload/drive/v3/files/\(params.fileId)?uploadType=multipart&fields=\(File.apiFields)")!
      var expectedRequest = URLRequest(url: url)
      expectedRequest.httpMethod = "PATCH"
      expectedRequest.allHTTPHeaderFields = [
        "Authorization": "\(credentials.tokenType) \(credentials.accessToken)",
        "Content-Type": "multipart/related; boundary=\(uuid.uuidString)"
      ]
      expectedRequest.httpBody = [
        "",
        "--\(uuid.uuidString)",
        "Content-Type: application/json; charset=UTF-8",
        "",
        #"{"mimeType":"text\/plain"}"#,
        "--\(uuid.uuidString)",
        "Content-Type: text/plain",
        "Content-Transfer-Encoding: base64",
        "",
        "ZmlsZSBkYXRh",
        "--\(uuid.uuidString)--"
      ].joined(separator: "\r\n").data(using: .utf8)!

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

  func testUpdateFileDataErrorResponse() async {
    let updateFileData = UpdateFileData.live(
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
      },
      uuidGenerator: .init { UUID() }
    )

    do {
      _ = try await updateFileData(
        fileId: "",
        data: Data(),
        mimeType: ""
      )
      XCTFail("Expected to throw, but didn't")
    } catch {
      XCTAssertEqual(
        error as? UpdateFileData.Error,
        .response(
          statusCode: 500,
          data: "Error!!!".data(using: .utf8)!
        ),
        "Expected to throw response error, got \(error)"
      )
    }
  }

  func testUpdateFileDataWhenNotAuthorized() async {
    let updateFileData = UpdateFileData.live(
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
      httpClient: .unimplemented(),
      uuidGenerator: .unimplemented()
    )

    do {
      _ = try await updateFileData(
        fileId: "",
        data: Data(),
        mimeType: ""
      )
      XCTFail("Expected to throw, but didn't")
    } catch {
      XCTAssertEqual(
        error as? UpdateFileData.Error, .notAuthorized,
        "Expected to throw .notAuthorized, got \(error)"
      )
    }
  }
}
