import Dependencies

public struct Config: Equatable, Sendable {
  public init(
    clientID: String,
    redirectURI: String
  ) {
    self.clientID = clientID
    self.redirectURI = redirectURI
  }

  public var clientID: String
  public var redirectURI: String
}

extension Config: TestDependencyKey {
  public static var testValue: Config {
    unimplemented("\(Self.self)", placeholder: Config(
      clientID: "unimplemented",
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
