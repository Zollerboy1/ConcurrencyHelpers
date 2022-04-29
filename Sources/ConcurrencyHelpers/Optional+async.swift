//
//  Optional+async.swift
//  ConcurrencyHelpers
//
//  Created by Josef Zoller on 29.04.22.
//

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension Optional {
    /// Evaluates the given closure when this `Optional` instance is not `nil`,
    /// passing the unwrapped value as a parameter.
    ///
    /// Use the `map` method with a closure that returns a non-optional value.
    /// This example performs an arithmetic operation on an
    /// optional integer.
    ///
    ///     let possibleNumber: Int? = Int("42")
    ///     let possibleSquare = possibleNumber.map { $0 * $0 }
    ///     print(possibleSquare)
    ///     // Prints "Optional(1764)"
    ///
    ///     let noNumber: Int? = nil
    ///     let noSquare = noNumber.map { $0 * $0 }
    ///     print(noSquare)
    ///     // Prints "nil"
    ///
    /// - Parameter transform: An asynchronous closure that takes the unwrapped
    ///   value of the instance.
    /// - Returns: The result of the given closure. If this instance is `nil`,
    ///   returns `nil`.
    @inlinable
    public func map<R>(
        _ transform: (Wrapped) async throws -> R
    ) async rethrows -> R? {
        switch self {
        case .some(let y):
            return .some(try await transform(y))
        case .none:
            return .none
        }
    }
    
    /// Evaluates the given closure when this `Optional` instance is not `nil`,
    /// passing the unwrapped value as a parameter.
    ///
    /// Use the `flatMap` method with a closure that returns an optional value.
    /// This example performs an arithmetic operation with an optional result on
    /// an optional integer.
    ///
    ///     let possibleNumber: Int? = Int("42")
    ///     let nonOverflowingSquare = possibleNumber.flatMap { x -> Int? in
    ///         let (result, overflowed) = x.multipliedReportingOverflow(by: x)
    ///         return overflowed ? nil : result
    ///     }
    ///     print(nonOverflowingSquare)
    ///     // Prints "Optional(1764)"
    ///
    /// - Parameter transform: An asynchronous closure that takes the unwrapped
    ///   value of the instance.
    /// - Returns: The result of the given closure. If this instance is `nil`,
    ///   returns `nil`.
    @inlinable
    public func flatMap<R>(
        _ transform: (Wrapped) async throws -> R?
    ) async rethrows -> R? {
        switch self {
        case .some(let y):
            return try await transform(y)
        case .none:
            return .none
        }
    }
}
