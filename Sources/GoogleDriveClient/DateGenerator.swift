import Foundation

public struct DateGenerator: Sendable {
  public typealias Run = @Sendable () -> Date

  public init(run: @escaping Run) {
    self.run = run
  }

  public var run: Run

  public func callAsFunction() -> Date {
    run()
  }
}

extension DateGenerator {
  public static let live = DateGenerator { Date() }
}
