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
  ],
  dependencies: [
    .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2"),
    .package(url: "https://github.com/pointfreeco/swift-dependencies.git", from: "0.5.1"),
  ],
  targets: [
    .target(
      name: "GoogleDriveClient",
      dependencies: [
        .product(name: "Dependencies", package: "swift-dependencies"),
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
