import XCTest
@testable import GoogleDriveClient

final class ListFilesTests: XCTestCase {
  func testListFiles() async throws {
    let credentials = Credentials(
      accessToken: "access-token-1",
      expiresAt: Date(),
      refreshToken: "refresh-token-1",
      tokenType: "token-type-1"
    )
    let httpRequests = ActorIsolated<[URLRequest]>([])
    let didRefreshToken = ActorIsolated(0)
    let listFiles = ListFiles.live(
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
            "nextPageToken": "next-page-token",
            "incompleteSearch": false,
            "files": [
              {
                "id": "1234",
                "mimeType": "text/plain",
                "name": "test.txt",
                "createdTime": "2023-07-06T01:00:00.000Z",
                "modifiedTime": "2023-07-06T02:00:00.000Z"
              }
            ]
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
    let params = ListFiles.Params(
      corpora: .user,
      driveId: "drive-id",
      includeItemsFromAllDrives: true,
      orderBy: [.createdTime, .modifiedTime.desc()],
      pageSize: 100,
      pageToken: "page-token",
      query: "query",
      spaces: [.drive],
      supportsAllDrives: true
    )

    let filesList = try await listFiles(params)

    await didRefreshToken.withValue {
      XCTAssertEqual($0, 1)
    }
    await httpRequests.withValue {
      var urlComponents = URLComponents()
      urlComponents.scheme = "https"
      urlComponents.host = "www.googleapis.com"
      urlComponents.path = "/drive/v3/files"
      urlComponents.queryItems = [
        URLQueryItem(name: "fields", value: FilesList.apiFields),
        URLQueryItem(name: "corpora", value: params.corpora?.rawValue),
        URLQueryItem(name: "driveId", value: params.driveId),
        URLQueryItem(name: "includeItemsFromAllDrives", value: "true"),
        URLQueryItem(name: "orderBy", value: params.orderBy.map { $0.string }.joined(separator: ",")),
        URLQueryItem(name: "pageSize", value: "\(params.pageSize!)"),
        URLQueryItem(name: "pageToken", value: params.pageToken),
        URLQueryItem(name: "q", value: params.query),
        URLQueryItem(name: "spaces", value: params.spaces.map(\.rawValue).joined(separator: ",")),
        URLQueryItem(name: "supportsAllDrives", value: "true"),
      ]

      var expectedRequest = URLRequest(url: urlComponents.url!)
      expectedRequest.httpMethod = "GET"
      expectedRequest.allHTTPHeaderFields = [
        "Authorization": "\(credentials.tokenType) \(credentials.accessToken)"
      ]

      XCTAssertEqual($0, [expectedRequest])
      XCTAssertNil($0.first?.httpBody)
    }
    XCTAssertEqual(filesList, FilesList(
      nextPageToken: "next-page-token",
      incompleteSearch: false,
      files: [
        File(
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
        ),
      ]
    ))
  }

  func testListFilesErrorResponse() async {
    let listFiles = ListFiles.live(
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
      _ = try await listFiles { $0.query = "" }
      XCTFail("Expected to throw, but didn't")
    } catch {
      XCTAssertEqual(
        error as? ListFiles.Error,
        .response(
          statusCode: 500,
          data: "Error!!!".data(using: .utf8)!
        ),
        "Expected to throw response error, got \(error)"
      )
    }
  }

  func testListFilesWhenNotAuthorized() async {
    let listFiles = ListFiles.live(
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
      _ = try await listFiles(.init())
      XCTFail("Expected to throw, but didn't")
    } catch {
      XCTAssertEqual(
        error as? ListFiles.Error, .notAuthorized,
        "Expected to throw .notAuthorized, got \(error)"
      )
    }
  }
}
