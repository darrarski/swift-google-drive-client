import Foundation
import GoogleDriveClient
import KeychainAccess

extension GoogleDriveClient.Keychain {
  public static func live(
    service: String =  "pl.darrarski.GoogleDriveClient"
  ) -> GoogleDriveClient.Keychain {
    let keychain = KeychainAccess.Keychain(service: service)
    let credentialsKey = "credentials"
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    return GoogleDriveClient.Keychain(
      loadCredentials: {
        guard let data = keychain[data: credentialsKey],
              let credentials = try? decoder.decode(Credentials.self, from: data)
        else { return nil }
        return credentials
      },
      saveCredentials: { credentials in
        guard let data = try? encoder.encode(credentials) else { return }
        keychain[data: credentialsKey] = data
      },
      deleteCredentials: {
        keychain[data: credentialsKey] = nil
      }
    )
  }
}
