# Swift Google Drive Client

![Swift v5.8](https://img.shields.io/badge/swift-v5.8-orange.svg)
![platforms iOS, macOS](https://img.shields.io/badge/platforms-iOS,_macOS-blue.svg)

Basic Google Drive HTTP API client that does not depend on Google's SDK.

- Authorize access
- List files
- Get file info
- Get file (download)
- Create file (upload)
- Update file (upload)
- Delete file

## 📖 Usage

Use [Swift Package Manager](https://swift.org/package-manager/) to add the `GoogleDriveClient` library as a dependency to your project.

Configure OAuth 2.0 Client ID using [Google Cloud Console](https://console.cloud.google.com/). Use `iOS` application type.

Configure your application so that it can handle sign-in redirects. For an iOS app, you can do it by adding or modifying `CFBundleURLTypes` in `Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLName</key>
    <string></string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.1234-abcd</string>
    </array>
  </dict>
</array>
```

Create the client:

```swift
import GoogleDriveClient

let config = GoogleDriveClient.Config(
  clientID: "1234-abcd.apps.googleusercontent.com",
  authScope: "https://www.googleapis.com/auth/drive",
  redirectURI: "com.googleusercontent.apps.1234-abcd://"
)
let client = GoogleDriveClient.Client.live(config: config)
```

Make sure the `redirectURI` contains the scheme defined earlier.

The library provides a basic implementation for storing vulnerable data securely in the keychain. Optionally, you can overwrite the default implementation with your own, custom one:

```swift
import GoogleDriveClient

let config = GoogleDriveClient.Config(...)
let keychain = GoogleDriveClient.Keychain(
  loadCredentials: { () async -> Credentials? in
    // load from secure storage and return
  },
  saveCredentials: { (Credentials) async -> Void in
    // save in secure storage
  },
  deleteCredentials: { () async -> Void in
    // delete from secure storage
  }
)
let client = GoogleDriveClient.Client.live(
  config: config,
  keychain: keychain
)
``` 

### ▶️ Example

This repository contains an [example iOS application](Example/GoogleDriveClientExampleApp) built with SwiftUI.

- Open `GoogleDriveClient.xcworkspace` in Xcode.
- Example source code is contained in the `Example` Xcode project.
- Run the app using the `GoogleDriveClientExampleApp` build scheme.
- The "Example" tab provides UI that uses `GoogleDriveClient` library.
- The "Console" tab provides UI for browsing application logs and HTTP requests.

The example app uses [Dependencies](https://github.com/pointfreeco/swift-dependencies) to manage its own internal dependencies. For more information about the `Dependencies` library check out [official documentation](https://pointfreeco.github.io/swift-dependencies/main/documentation/dependencies).

## 🏛 Project structure

```
GoogleDriveClient (Xcode Workspace)
 ├─ swift-google-drive-client (Swift Package)
 |   └─ GoogleDriveClient (Library)
 └─ Example (Xcode Project)
     └─ GoogleDriveClientExampleApp (iOS Application)
```

## 🛠 Develop

- Use Xcode (version ≥ 14.3.1).
- Clone the repository or create a fork & clone it.
- Open `GoogleDriveClient.xcworkspace` in Xcode.
- Use the `GoogleDriveClient` scheme for building the library.
- If you want to contribute, create a pull request containing your changes or bug fixes.

## ☕️ Do you like the project?

<a href="https://www.buymeacoffee.com/darrarski" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" height="60" width="217" style="height: 60px !important;width: 217px !important;" ></a>

## 📄 License

Copyright © 2023 Dariusz Rybicki Darrarski

License: [MIT](LICENSE)
