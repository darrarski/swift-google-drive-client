import Foundation

@dynamicMemberLookup
actor CurrentValueAsyncSequence<Value>: AsyncSequence where Value: Sendable {
  typealias Element = Value

  init(_ value: Value) {
    self.value = value
  }

  deinit {
    continuations.values.forEach { $0.finish() }
    continuations.removeAll()
  }

  private(set) var value: Value {
    didSet { continuations.values.forEach { $0.yield(value) } }
  }

  subscript<T>(dynamicMember keyPath: KeyPath<Value, T>) -> T {
    self.value[keyPath: keyPath]
  }

  private var continuations = [UUID: AsyncStream<Element>.Continuation]()

  nonisolated func makeAsyncIterator() -> AsyncStream<Value>.Iterator {
    let id = UUID()
    let stream = AsyncStream<Element> { [weak self] continuation in
      Task { [self] in await self?.add(id, continuation) }
      continuation.onTermination = { [self] _ in
        Task { [self] in await self?.remove(id) }
      }
    }
    return stream.makeAsyncIterator()
  }

  func setValue(_ value: Value) {
    self.value = value
  }

  @discardableResult
  func withValue<T>(_ operation: @Sendable (inout Value) throws -> T) rethrows -> T {
    var value = self.value
    defer { self.value = value }
    return try operation(&value)
  }

  private func add(_ id: UUID, _ continuation: AsyncStream<Element>.Continuation) {
    continuations[id] = continuation
    continuation.yield(value)
  }

  private func remove(_ id: UUID) {
    continuations[id] = nil
  }
}
