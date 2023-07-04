// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "swift-google-drive-client",
  platforms: [
    .iOS(.v16),
    .macOS(.v13),
  ],
  products: [
    .library(name: "GoogleDriveClient", targets: ["GoogleDriveClient"]),
    .library(name: "GoogleDriveClientKeychain", targets: ["GoogleDriveClientKeychain"]),
  ],
  dependencies: [
    .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2"),
  ],
  targets: [
    .target(
      name: "GoogleDriveClient"
    ),
    .target(
      name: "GoogleDriveClientKeychain",
      dependencies: [
        .target(name: "GoogleDriveClient"),
        .product(name: "KeychainAccess", package: "KeychainAccess"),
      ]
    ),
  ]
)

//for target in package.targets {
//  target.swiftSettings = target.swiftSettings ?? []
//  target.swiftSettings?.append(
//    .unsafeFlags(
//      [
//        "-Xfrontend", "-strict-concurrency=targeted",
//        "-Xfrontend", "-enable-actor-data-race-checks",
//        "-Xfrontend", "-debug-time-function-bodies",
//        "-Xfrontend", "-debug-time-expression-type-checking",
//      ], .when(configuration: .debug))
//  )
//}
