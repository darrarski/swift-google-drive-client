import Dependencies

public struct Config: Equatable, Sendable {
  public init(
    clientID: String,
    authScope: String,
    redirectURI: String
  ) {
    self.clientID = clientID
    self.authScope = authScope
    self.redirectURI = redirectURI
  }

  public var clientID: String
  public var authScope: String
  public var redirectURI: String
}

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
