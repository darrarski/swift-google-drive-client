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
