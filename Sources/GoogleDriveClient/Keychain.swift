public struct Keychain: Sendable {
  public typealias LoadCredentials = @Sendable () async -> Credentials?
  public typealias SaveCredentials = @Sendable (Credentials) async -> Void
  public typealias DeleteCredentials = @Sendable () async -> Void

  public init(
    loadCredentials: @escaping Keychain.LoadCredentials,
    saveCredentials: @escaping Keychain.SaveCredentials,
    deleteCredentials: @escaping Keychain.DeleteCredentials
  ) {
    self.loadCredentials = loadCredentials
    self.saveCredentials = saveCredentials
    self.deleteCredentials = deleteCredentials
  }

  public var loadCredentials: LoadCredentials
  public var saveCredentials: SaveCredentials
  public var deleteCredentials: DeleteCredentials
}
