import Foundation

public struct UUIDGenerator: Sendable {
  public typealias Run = @Sendable () -> UUID

  public init(run: @escaping Run) {
    self.run = run
  }

  public var run: Run

  public func callAsFunction() -> UUID {
    run()
  }
}

extension UUIDGenerator {
  public static let live = UUIDGenerator { UUID() }
}
