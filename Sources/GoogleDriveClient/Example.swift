import Dependencies
import XCTestDynamicOverlay

public struct Example: Sendable {
  public typealias Run = @Sendable () -> String

  public init(run: @escaping Run) {
    self.run = run
  }

  public var run: Run

  public func callAsFunction() -> String {
    run()
  }
}

extension Example: DependencyKey {
  public static let liveValue = Example { "Live" }
  public static let previewValue = Example { "Preview" }
  public static let testValue = Example(
    run: unimplemented("\(Self.self).run", placeholder: "Unimplemented")
  )
}

extension DependencyValues {
  public var googleDriveExample: Example {
    get { self[Example.self] }
    set { self[Example.self] = newValue }
  }
}
