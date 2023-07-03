import Foundation

public struct Credentials: Sendable, Equatable, Codable {
  public init(
    accessToken: String,
    expiresAt: Date,
    refreshToken: String,
    tokenType: String
  ) {
    self.accessToken = accessToken
    self.expiresAt = expiresAt
    self.refreshToken = refreshToken
    self.tokenType = tokenType
  }

  public let accessToken: String
  public let expiresAt: Date
  public let refreshToken: String
  public let tokenType: String
}
