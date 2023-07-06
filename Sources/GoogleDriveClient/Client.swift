import Foundation

public struct Client: Sendable {
  public init(
    auth: Auth,
    listFiles: ListFiles,
    getFile: GetFile,
    getFileData: GetFileData,
    createFile: CreateFile,
    updateFileData: UpdateFileData,
    deleteFile: DeleteFile
  ) {
    self.auth = auth
    self.listFiles = listFiles
    self.getFile = getFile
    self.getFileData = getFileData
    self.createFile = createFile
    self.updateFileData = updateFileData
    self.deleteFile = deleteFile
  }

  public var auth: Auth
  public var listFiles: ListFiles
  public var getFile: GetFile
  public var getFileData: GetFileData
  public var createFile: CreateFile
  public var updateFileData: UpdateFileData
  public var deleteFile: DeleteFile
}

extension Client {
  public static func live(
    config: Config,
    keychain: Keychain,
    httpClient: HTTPClient = .urlSession(),
    openURL: OpenURL = .live,
    dateGenerator: DateGenerator = .live,
    uuidGenerator: UUIDGenerator = .live
  ) -> Client {
    let auth = Auth.live(
      config: config,
      keychain: keychain,
      dateGenerator: dateGenerator,
      openURL: openURL,
      httpClient: httpClient
    )
    let listFiles = ListFiles.live(
      auth: auth,
      keychain: keychain,
      httpClient: httpClient
    )
    let getFile = GetFile.live(
      auth: auth,
      keychain: keychain,
      httpClient: httpClient
    )
    let getFileData = GetFileData.live(
      auth: auth,
      keychain: keychain,
      httpClient: httpClient
    )
    let createFile = CreateFile.live(
      auth: auth,
      keychain: keychain,
      httpClient: httpClient,
      uuidGenerator: uuidGenerator
    )
    let updateFileData = UpdateFileData.live(
      auth: auth,
      keychain: keychain,
      httpClient: httpClient,
      uuidGenerator: uuidGenerator
    )
    let deleteFile = DeleteFile.live(
      auth: auth,
      keychain: keychain,
      httpClient: httpClient
    )
    return Client(
      auth: auth,
      listFiles: listFiles,
      getFile: getFile,
      getFileData: getFileData,
      createFile: createFile,
      updateFileData: updateFileData,
      deleteFile: deleteFile
    )
  }
}
