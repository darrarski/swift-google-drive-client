import Foundation
import GoogleDriveClient
import Security

extension GoogleDriveClient.Keychain {
  public static func live(
    service: String =  "pl.darrarski.GoogleDriveClient"
  ) -> GoogleDriveClient.Keychain {
    let keychain = _Keychain(service: service)
    let credentialsKey = "credentials"
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    return GoogleDriveClient.Keychain(
      loadCredentials: {
        guard let data = try? keychain.loadPassword(for: credentialsKey),
              let credentials = try? decoder.decode(Credentials.self, from: data)
        else { return nil }
        return credentials
      },
      saveCredentials: { credentials in
        guard let data = try? encoder.encode(credentials) else { return }
        try? keychain.savePassword(data, for: credentialsKey)
      },
      deleteCredentials: {
        try? keychain.deletePassword(for: credentialsKey)
      }
    )
  }
}

struct _Keychain {
  enum Error: Swift.Error {
    case itemNotFound
    case duplicateItem
    case invalidItemFormat
    case unexpectedStatus(OSStatus)
  }

  var service: String

  func loadPassword(for account: String) throws -> Data? {
    let query: [String: AnyObject] = [
      kSecAttrService as String: service as AnyObject,
      kSecAttrAccount as String: account as AnyObject,
      kSecClass as String: kSecClassGenericPassword,
      kSecMatchLimit as String: kSecMatchLimitOne,
      kSecReturnData as String: kCFBooleanTrue,
      kSecAttrSynchronizable as String: kCFBooleanTrue,
    ]
    var itemCopy: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &itemCopy)
    guard status != errSecItemNotFound else {
      return nil
    }
    guard status == errSecSuccess else {
      throw Error.unexpectedStatus(status)
    }
    guard let password = itemCopy as? Data else {
      throw Error.invalidItemFormat
    }
    return password
  }

  func savePassword(_ password: Data, for account: String) throws {
    let query: [String: AnyObject] = [
      kSecAttrService as String: service as AnyObject,
      kSecAttrAccount as String: account as AnyObject,
      kSecClass as String: kSecClassGenericPassword,
      kSecMatchLimit as String: kSecMatchLimitOne,
      kSecAttrSynchronizable as String: kCFBooleanTrue,
    ]
    let status = SecItemCopyMatching(query as CFDictionary, nil)
    if status == errSecItemNotFound {
      let query: [String: AnyObject] = [
        kSecAttrService as String: service as AnyObject,
        kSecAttrAccount as String: account as AnyObject,
        kSecClass as String: kSecClassGenericPassword,
        kSecValueData as String: password as AnyObject,
        kSecAttrSynchronizable as String: kCFBooleanTrue,
      ]
      let status = SecItemAdd(query as CFDictionary, nil)
      guard status == errSecSuccess else {
        throw Error.unexpectedStatus(status)
      }
    } else if status == errSecSuccess {
      let query: [String: AnyObject] = [
        kSecAttrService as String: service as AnyObject,
        kSecAttrAccount as String: account as AnyObject,
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrSynchronizable as String: kCFBooleanTrue,
      ]
      let attributes: [String: AnyObject] = [
        kSecValueData as String: password as AnyObject
      ]
      let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
      guard status == errSecSuccess else {
        throw Error.unexpectedStatus(status)
      }
    } else {
      throw Error.unexpectedStatus(status)
    }
  }

  func deletePassword(for account: String) throws {
    let query: [String: AnyObject] = [
      kSecAttrService as String: service as AnyObject,
      kSecAttrAccount as String: account as AnyObject,
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrSynchronizable as String: kCFBooleanTrue,
    ]
    let status = SecItemDelete(query as CFDictionary)
    guard status == errSecSuccess else {
      throw Error.unexpectedStatus(status)
    }
  }
}
