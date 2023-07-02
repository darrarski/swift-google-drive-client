public struct Auth: Sendable, Equatable, Codable {
  public init(
    accessToken: String,
    expiresIn: Int,
    refreshToken: String,
    tokenType: String
  ) {
    self.accessToken = accessToken
    self.expiresIn = expiresIn
    self.refreshToken = refreshToken
    self.tokenType = tokenType
  }

  public let accessToken: String
  public let expiresIn: Int
  public let refreshToken: String
  public let tokenType: String
}
