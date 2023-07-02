import Dependencies
import Foundation
import KeychainAccess
import XCTestDynamicOverlay

public struct Keychain: Sendable {
  public typealias LoadAuth = @Sendable () async -> Auth?
  public typealias SaveAuth = @Sendable (Auth) async -> Void
  public typealias DeleteAuth = @Sendable () async -> Void

  public init(
    loadAuth: @escaping Keychain.LoadAuth,
    saveAuth: @escaping Keychain.SaveAuth,
    deleteAuth: @escaping Keychain.DeleteAuth
  ) {
    self.loadAuth = loadAuth
    self.saveAuth = saveAuth
    self.deleteAuth = deleteAuth
  }

  public var loadAuth: LoadAuth
  public var saveAuth: SaveAuth
  public var deleteAuth: DeleteAuth
}

extension Keychain: DependencyKey {
  private static var service = "pl.darrarski.GoogleDriveClient"
  private static let authKey = "auth"
  public static var liveValue = Keychain(
    loadAuth: {
      let keychain = KeychainAccess.Keychain(service: service)
      guard let data = keychain[data: authKey],
            let auth = try? JSONDecoder().decode(Auth.self, from: data)
      else { return nil }
      return auth
    },
    saveAuth: { auth in
      let keychain = KeychainAccess.Keychain(service: service)
      let encoder = JSONEncoder()
      guard let data = try? encoder.encode(auth)
      else { return }
      keychain[data: authKey] = data
    },
    deleteAuth: {
      let keychain = KeychainAccess.Keychain(service: service)
      keychain[data: authKey] = nil
    }
  )

  public static let testValue = Keychain(
    loadAuth: unimplemented("\(Self.self).loadAuth"),
    saveAuth: unimplemented("\(Self.self).saveAuth"),
    deleteAuth: unimplemented("\(Self.self).deleteAuth")
  )

  private static let previewAuth = ActorIsolated<Auth?>(nil)
  public static let previewValue = Keychain(
    loadAuth: { await previewAuth.value },
    saveAuth: { await previewAuth.setValue($0) },
    deleteAuth: { await previewAuth.setValue(nil) }
  )
}

extension DependencyValues {
  public var googleDriveClientKeychain: Keychain {
    get { self[Keychain.self] }
    set { self[Keychain.self] = newValue }
  }
}
