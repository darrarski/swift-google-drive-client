import Dependencies
import Foundation
import GoogleDriveClient
import GoogleDriveClientKeychain

extension GoogleDriveClient.Client: DependencyKey {
  public static let liveValue = Client.live(
    config: Config(
      clientID: "437442953929-vk9agcivr59cldl92jqaiqdvlncpuh2v.apps.googleusercontent.com",
      authScope: "https://www.googleapis.com/auth/drive.appdata",
      redirectURI: "com.googleusercontent.apps.437442953929-vk9agcivr59cldl92jqaiqdvlncpuh2v://"
    ),
    keychain: .live()
  )

  public static let previewValue: Client = {
    let isSignedIn = CurrentValueAsyncSequence(false)
    let files = ActorIsolated<[File]>([
      File(
        id: "preview-1",
        mimeType: "text/plain",
        name: "preview1.txt",
        createdTime: Date(),
        modifiedTime: Date()
      ),
      File(
        id: "preview-2",
        mimeType: "text/plain",
        name: "preview2.txt",
        createdTime: Date(),
        modifiedTime: Date()
      ),
      File(
        id: "preview-3",
        mimeType: "text/plain",
        name: "preview3.txt",
        createdTime: Date(),
        modifiedTime: Date()
      ),
    ])

    return Client(
      auth: .init(
        isSignedIn: { await isSignedIn.value },
        isSignedInStream: { isSignedIn.eraseToStream() },
        signIn: { await isSignedIn.setValue(true) },
        handleRedirect: { _ in },
        refreshToken: {},
        signOut: { await isSignedIn.setValue(false) }
      ),
      listFiles: .init { _ in
        FilesList(
          nextPageToken: nil,
          incompleteSearch: false,
          files: await files.value
        )
      },
      getFile: .init { params in
        guard let file = await files.value.first(where: { $0.id == params.fileId })
        else { throw GetFile.Error.response(statusCode: 404, data: Data()) }
        return file
      },
      getFileData: .init { params in
        "Content of file: \(params.fileId)".data(using: .utf8)!
      },
      createFile: .init { params in
        let file = File(
          id: "preview-\(UUID().uuidString)",
          mimeType: "text/plain",
          name: "preview\(Int.random(in: 100...999))",
          createdTime: Date(),
          modifiedTime: Date()
        )
        await files.withValue { $0.insert(file, at: $0.startIndex) }
        return file
      },
      updateFileData: .init { params in
        guard var file = await files.value.first(where: { $0.id == params.fileId })
        else { throw UpdateFileData.Error.response(statusCode: 404, data: Data()) }
        file.modifiedTime = Date()
        await files.withValue { [file] in $0 = $0.map { $0.id == file.id ? file : $0 } }
        return file
      },
      deleteFile: .init { params in
        await files.withValue { $0 = $0.filter { $0.id != params.fileId } }
      }
    )
  }()
}

extension DependencyValues {
  var googleDriveClient: GoogleDriveClient.Client {
    get { self[GoogleDriveClient.Client.self] }
    set { self[GoogleDriveClient.Client.self] = newValue }
  }
}
