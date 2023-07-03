import Dependencies
import Foundation
import KeychainAccess
import XCTestDynamicOverlay

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

extension Keychain: DependencyKey {
  private static var service = "pl.darrarski.GoogleDriveClient"
  private static let credentialsKey = "credentials"

  public static var liveValue = Keychain(
    loadCredentials: {
      let keychain = KeychainAccess.Keychain(service: service)
      guard let data = keychain[data: credentialsKey],
            let credentials = try? JSONDecoder().decode(Credentials.self, from: data)
      else { return nil }
      return credentials
    },
    saveCredentials: { credentials in
      let keychain = KeychainAccess.Keychain(service: service)
      let encoder = JSONEncoder()
      guard let data = try? encoder.encode(credentials)
      else { return }
      keychain[data: credentialsKey] = data
    },
    deleteCredentials: {
      let keychain = KeychainAccess.Keychain(service: service)
      keychain[data: credentialsKey] = nil
    }
  )

  public static let testValue = Keychain(
    loadCredentials: unimplemented("\(Self.self).loadCredentials"),
    saveCredentials: unimplemented("\(Self.self).saveCredentials"),
    deleteCredentials: unimplemented("\(Self.self).deleteCredentials")
  )

  private static let previewCredentials = ActorIsolated<Credentials?>(nil)

  public static let previewValue = Keychain(
    loadCredentials: { await previewCredentials.value },
    saveCredentials: { await previewCredentials.setValue($0) },
    deleteCredentials: { await previewCredentials.setValue(nil) }
  )
}

extension DependencyValues {
  public var googleDriveClientKeychain: Keychain {
    get { self[Keychain.self] }
    set { self[Keychain.self] = newValue }
  }
}
