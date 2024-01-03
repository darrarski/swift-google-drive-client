// swift-tools-version: 5.8

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
  targets: [
    .target(
      name: "GoogleDriveClient"
    ),
    .testTarget(
      name: "GoogleDriveClientTests",
      dependencies: [
        .target(name: "GoogleDriveClient"),
      ]
    ),
  ]
)

//for target in package.targets {
//  target.swiftSettings = target.swiftSettings ?? []
//  target.swiftSettings?.append(
//    .unsafeFlags(
//      [
//        "-Xfrontend", "-strict-concurrency=complete",
//        "-Xfrontend", "-enable-actor-data-race-checks",
//        "-Xfrontend", "-debug-time-function-bodies",
//        "-Xfrontend", "-debug-time-expression-type-checking",
//      ], .when(configuration: .debug))
//  )
//}
