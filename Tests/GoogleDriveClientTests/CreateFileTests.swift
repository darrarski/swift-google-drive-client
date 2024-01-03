import XCTest
@testable import GoogleDriveClient

final class CreateFileTests: XCTestCase {
  func testCreateFile() async throws {
    let credentials = Credentials(
      accessToken: "access-token-1",
      expiresAt: Date(),
      refreshToken: "refresh-token-1",
      tokenType: "token-type-1"
    )
    let httpRequests = ActorIsolated<[URLRequest]>([])
    let didRefreshToken = ActorIsolated(0)
    let uuid = UUID()
    let createFile = CreateFile.live(
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
    let params = CreateFile.Params(
      data: "file data".data(using: .utf8)!,
      metadata: .init(
        name: "test.txt",
        spaces: "cosmos",
        mimeType: "text/plain",
        parents: ["parent1", "parent2"]
      )
    )

    let file = try await createFile(params)

    await didRefreshToken.withValue {
      XCTAssertEqual($0, 1)
    }
    await httpRequests.withValue {
      let url = URL(string: "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart&fields=\(File.apiFields)")!
      var expectedRequest = URLRequest(url: url)
      expectedRequest.httpMethod = "POST"
      expectedRequest.allHTTPHeaderFields = [
        "Authorization": "\(credentials.tokenType) \(credentials.accessToken)",
        "Content-Type": "multipart/related; boundary=\(uuid.uuidString)"
      ]
      expectedRequest.httpBody = [
        "",
        "--\(uuid.uuidString)",
        "Content-Type: application/json; charset=UTF-8",
        "",
        #"{"mimeType":"text\/plain","name":"test.txt","parents":["parent1","parent2"],"spaces":"cosmos"}"#,
        "--\(uuid.uuidString)",
        "Content-Type: text/plain",
        "Content-Transfer-Encoding: base64",
        "",
        "ZmlsZSBkYXRh",
        "--\(uuid.uuidString)--"
      ].joined(separator: "\r\n").data(using: .utf8)!

      XCTAssertEqual($0, [expectedRequest])
      XCTAssertEqual($0.first?.httpBody, expectedRequest.httpBody!)
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

  func testCreateFileErrorResponse() async {
    let createFile = CreateFile.live(
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
      _ = try await createFile(
        name: "",
        spaces: "",
        mimeType: "",
        parents: [],
        data: Data()
      )
      XCTFail("Expected to throw, but didn't")
    } catch {
      XCTAssertEqual(
        error as? CreateFile.Error,
        .response(
          statusCode: 500,
          data: "Error!!!".data(using: .utf8)!
        ),
        "Expected to throw response error, got \(error)"
      )
    }
  }

  func testCreateFileWhenNotAuthorized() async {
    let createFile = CreateFile.live(
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
      _ = try await createFile(
        name: "",
        spaces: "",
        mimeType: "",
        parents: [],
        data: Data()
      )
      XCTFail("Expected to throw, but didn't")
    } catch {
      XCTAssertEqual(
        error as? CreateFile.Error, .notAuthorized,
        "Expected to throw .notAuthorized, got \(error)"
      )
    }
  }
}
