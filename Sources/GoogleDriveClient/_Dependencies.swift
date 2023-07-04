import Dependencies
import Foundation
import XCTestDynamicOverlay

// MARK: - Auth

extension Auth: DependencyKey {
  public static let liveValue: Auth = {
    @Dependency(\.googleDriveClientConfig) var config
    @Dependency(\.googleDriveClientKeychain) var keychain
    @Dependency(\.googleDriveClientDateGenerator) var dateGenerator
    @Dependency(\.googleDriveClientOpenURL) var openURL
    @Dependency(\.urlSession) var urlSession

    return Auth.live(
      config: config,
      keychain: keychain,
      dateGenerator: dateGenerator,
      openURL: openURL,
      urlSession: urlSession
    )
  }()

  public static let testValue = Auth(
    isSignedIn: unimplemented("\(Self.self).isSignedIn", placeholder: false),
    isSignedInStream: unimplemented("\(Self.self).isSignedInStream", placeholder: .finished),
    signIn: unimplemented("\(Self.self).signIn"),
    handleRedirect: unimplemented("\(Self.self).handleRedirect"),
    refreshToken: unimplemented("\(Self.self).refreshToken"),
    signOut: unimplemented("\(Self.self).signOut")
  )

  private static let previewIsSignedIn = CurrentValueAsyncSequence(false)

  public static let previewValue = Auth(
    isSignedIn: {
      await previewIsSignedIn.value
    },
    isSignedInStream: {
      previewIsSignedIn.eraseToStream()
    },
    signIn: {
      await previewIsSignedIn.setValue(true)
    },
    handleRedirect: { _ in },
    refreshToken: {},
    signOut: {
      await previewIsSignedIn.setValue(false)
    }
  )
}

extension DependencyValues {
  public var googleDriveClientAuth: Auth {
    get { self[Auth.self] }
    set { self[Auth.self] = newValue }
  }
}

// MARK: - Config

extension Config: TestDependencyKey {
  public static var testValue: Config {
    unimplemented("\(Self.self)", placeholder: Config(
      clientID: "unimplemented",
      authScope: "unimplemented",
      redirectURI: "unimplemented"
    ))
  }
}

extension DependencyValues {
  public var googleDriveClientConfig: Config {
    get { self[Config.self] }
    set { self[Config.self] = newValue }
  }
}

// MARK: - DateGenerator

extension DateGenerator: DependencyKey {
  public static var liveValue = DateGenerator.live
}

extension DependencyValues {
  public var googleDriveClientDateGenerator: DateGenerator {
    get { self[DateGenerator.self] }
    set { self[DateGenerator.self] = newValue }
  }
}

// MARK: - CreateFile

extension CreateFile: DependencyKey {
  public static let liveValue: CreateFile = {
    @Dependency(\.googleDriveClientAuth) var auth
    @Dependency(\.googleDriveClientKeychain) var keychain
    @Dependency(\.urlSession) var urlSession
    @Dependency(\.uuid) var uuid

    return CreateFile.live(
      auth: auth,
      keychain: keychain,
      urlSession: urlSession,
      uuidGenerator: { uuid() }
    )
  }()

  public static let testValue = CreateFile(
    run: unimplemented("\(Self.self).run")
  )
}

extension DependencyValues {
  public var googleDriveClientCreateFile: CreateFile {
    get { self[CreateFile.self] }
    set { self[CreateFile.self] = newValue }
  }
}

// MARK: - DeleteFile

extension DeleteFile: DependencyKey {
  public static let liveValue: DeleteFile = {
    @Dependency(\.googleDriveClientAuth) var auth
    @Dependency(\.googleDriveClientKeychain) var keychain
    @Dependency(\.urlSession) var urlSession

    return DeleteFile.live(
      auth: auth,
      keychain: keychain,
      urlSession: urlSession
    )
  }()

  public static let testValue = DeleteFile(
    run: unimplemented("\(Self.self).run")
  )
}

extension DependencyValues {
  public var googleDriveClientDeleteFile: DeleteFile {
    get { self[DeleteFile.self] }
    set { self[DeleteFile.self] = newValue }
  }
}

// MARK: - GetFile

extension GetFile: DependencyKey {
  public static let liveValue: GetFile = {
    @Dependency(\.googleDriveClientAuth) var auth
    @Dependency(\.googleDriveClientKeychain) var keychain
    @Dependency(\.urlSession) var urlSession

    return GetFile.live(
      auth: auth,
      keychain: keychain,
      urlSession: urlSession
    )
  }()

  public static let testValue = GetFile(
    run: unimplemented("\(Self.self).run")
  )
}

extension DependencyValues {
  public var googleDriveClientGetFile: GetFile {
    get { self[GetFile.self] }
    set { self[GetFile.self] = newValue }
  }
}

// MARK: - GetFileData

extension GetFileData: DependencyKey {
  public static let liveValue: GetFileData = {
    @Dependency(\.googleDriveClientAuth) var auth
    @Dependency(\.googleDriveClientKeychain) var keychain
    @Dependency(\.urlSession) var urlSession

    return GetFileData.live(
      auth: auth,
      keychain: keychain,
      urlSession: urlSession
    )
  }()

  public static let testValue = GetFileData(
    run: unimplemented("\(Self.self).run")
  )
}

extension DependencyValues {
  public var googleDriveClientGetFileData: GetFileData {
    get { self[GetFileData.self] }
    set { self[GetFileData.self] = newValue }
  }
}

// MARK: - Keychain

extension Keychain: DependencyKey {
  public static let liveValue = Keychain.live()

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

// MARK: - ListFiles

extension ListFiles: DependencyKey {
  public static let liveValue: ListFiles = {
    @Dependency(\.googleDriveClientAuth) var auth
    @Dependency(\.googleDriveClientKeychain) var keychain
    @Dependency(\.urlSession) var urlSession

    return ListFiles.live(
      auth: auth,
      keychain: keychain,
      urlSession: urlSession
    )
  }()

  public static let previewValue = ListFiles { _ in
    FilesList(
      nextPageToken: nil,
      incompleteSearch: false,
      files: [
        File(
          id: "preview-1",
          mimeType: "preview",
          name: "Preview 1",
          createdTime: Date(),
          modifiedTime: Date()
        ),
        File(
          id: "preview-2",
          mimeType: "preview",
          name: "Preview 2",
          createdTime: Date(),
          modifiedTime: Date()
        ),
        File(
          id: "preview-3",
          mimeType: "preview",
          name: "Preview 3",
          createdTime: Date(),
          modifiedTime: Date()
        ),
      ]
    )
  }

  public static let testValue = ListFiles(
    run: unimplemented("\(Self.self).run")
  )
}

extension DependencyValues {
  public var googleDriveClientListFiles: ListFiles {
    get { self[ListFiles.self] }
    set { self[ListFiles.self] = newValue }
  }
}

// MARK: - OpenURL

extension OpenURL: DependencyKey {
  public static let liveValue = OpenURL.live
}

extension DependencyValues {
  public var googleDriveClientOpenURL: OpenURL {
    get { self[OpenURL.self] }
    set { self[OpenURL.self] = newValue }
  }
}

// MARK: - UpdateFile

extension UpdateFile: DependencyKey {
  public static let liveValue: UpdateFile = {
    @Dependency(\.googleDriveClientAuth) var auth
    @Dependency(\.googleDriveClientKeychain) var keychain
    @Dependency(\.urlSession) var urlSession
    @Dependency(\.uuid) var uuid

    return UpdateFile.live(
      auth: auth,
      keychain: keychain,
      urlSession: urlSession,
      uuidGenerator: { uuid() }
    )
  }()

  public static let testValue = UpdateFile(
    run: unimplemented("\(Self.self).run")
  )
}

extension DependencyValues {
  public var googleDriveClientUpdateFile: UpdateFile {
    get { self[UpdateFile.self] }
    set { self[UpdateFile.self] = newValue }
  }
}
