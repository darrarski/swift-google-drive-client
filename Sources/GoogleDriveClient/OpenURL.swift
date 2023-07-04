import Foundation
import SwiftUI

public struct OpenURL: Sendable {
  public typealias Run = @Sendable (URL) async -> Bool

  public init(run: @escaping Run) {
    self.run = run
  }

  public var run: Run

  @discardableResult
  public func callAsFunction(_ url: URL) async -> Bool {
    await run(url)
  }
}

extension OpenURL {
  public static let live = OpenURL { url in
    let stream = AsyncStream<Bool> { continuation in
      let task = Task { @MainActor in
        EnvironmentValues().openURL(url) { canOpen in
          continuation.yield(canOpen)
          continuation.finish()
        }
      }
      continuation.onTermination = { @Sendable _ in
        task.cancel()
      }
    }
    return await stream.first(where: { _ in true }) ?? false
  }
}
