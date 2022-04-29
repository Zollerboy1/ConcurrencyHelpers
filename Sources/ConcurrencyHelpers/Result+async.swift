//
//  Result+async.swift
//  ConcurrencyHelpers
//
//  Created by Josef Zoller on 29.04.22.
//

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension Result {
    /// Returns a new result, mapping any success value using the given
    /// transformation.
    ///
    /// Use this method when you need to transform the value of a `Result`
    /// instance when it represents a success. The following example transforms
    /// the integer success value of a result into a string:
    ///
    ///     func getNextInteger() -> Result<Int, Error> { /* ... */ }
    ///
    ///     let integerResult = getNextInteger()
    ///     // integerResult == .success(5)
    ///     let stringResult = integerResult.map({ String($0) })
    ///     // stringResult == .success("5")
    ///
    /// - Parameter transform: An asynchronous closure that takes the success
    ///   value of this instance.
    /// - Returns: A `Result` instance with the result of evaluating `transform`
    ///   as the new success value if this instance represents a success.
    @inlinable
    public func map<NewSuccess>(
        _ transform: (Success) async -> NewSuccess
    ) async -> Result<NewSuccess, Failure> {
        switch self {
        case let .success(success):
            return .success(await transform(success))
        case let .failure(failure):
            return .failure(failure)
        }
    }
    
    /// Returns a new result, mapping any failure value using the given
    /// transformation.
    ///
    /// Use this method when you need to transform the value of a `Result`
    /// instance when it represents a failure. The following example transforms
    /// the error value of a result by wrapping it in a custom `Error` type:
    ///
    ///     struct DatedError: Error {
    ///         var error: Error
    ///         var date: Date
    ///
    ///         init(_ error: Error) {
    ///             self.error = error
    ///             self.date = Date()
    ///         }
    ///     }
    ///
    ///     let result: Result<Int, Error> = // ...
    ///     // result == .failure(<error value>)
    ///     let resultWithDatedError = result.mapError({ e in DatedError(e) })
    ///     // result == .failure(DatedError(error: <error value>, date: <date>))
    ///
    /// - Parameter transform: An asynchronous closure that takes the failure
    ///   value of the instance.
    /// - Returns: A `Result` instance with the result of evaluating `transform`
    ///   as the new failure value if this instance represents a failure.
    @inlinable
    public func mapError<NewFailure>(
        _ transform: (Failure) async -> NewFailure
    ) async -> Result<Success, NewFailure> {
        switch self {
        case let .success(success):
            return .success(success)
        case let .failure(failure):
            return .failure(await transform(failure))
        }
    }
    
    /// Returns a new result, mapping any success value using the given
    /// transformation and unwrapping the produced result.
    ///
    /// Use this method to avoid a nested result when your transformation
    /// produces another `Result` type.
    ///
    /// In this example, note the difference in the result of using `map` and
    /// `flatMap` with a transformation that returns an result type.
    ///
    ///     func getNextInteger() -> Result<Int, Error> {
    ///         .success(4)
    ///     }
    ///     func getNextAfterInteger(_ n: Int) -> Result<Int, Error> {
    ///         .success(n + 1)
    ///     }
    ///
    ///     let result = getNextInteger().map({ getNextAfterInteger($0) })
    ///     // result == .success(.success(5))
    ///
    ///     let result = getNextInteger().flatMap({ getNextAfterInteger($0) })
    ///     // result == .success(5)
    ///
    /// - Parameter transform: An asynchronous closure that takes the success
    ///   value of the instance.
    /// - Returns: A `Result` instance, either from the closure or the previous
    ///   `.failure`.
    @inlinable
    public func flatMap<NewSuccess>(
        _ transform: (Success) async -> Result<NewSuccess, Failure>
    ) async -> Result<NewSuccess, Failure> {
        switch self {
        case let .success(success):
            return await transform(success)
        case let .failure(failure):
            return .failure(failure)
        }
    }
    
    /// Returns a new result, mapping any failure value using the given
    /// transformation and unwrapping the produced result.
    ///
    /// - Parameter transform: An asynchronous closure that takes the failure
    ///   value of the instance.
    /// - Returns: A `Result` instance, either from the closure or the previous
    ///   `.success`.
    @inlinable
    public func flatMapError<NewFailure>(
        _ transform: (Failure) async -> Result<Success, NewFailure>
    ) async -> Result<Success, NewFailure> {
        switch self {
        case let .success(success):
            return .success(success)
        case let .failure(failure):
            return await transform(failure)
        }
    }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension Result where Failure == Swift.Error {
    /// Creates a new result by evaluating a throwing closure, capturing the
    /// returned value as a success, or any thrown error as a failure.
    ///
    /// - Parameter body: An asynchronous throwing closure to evaluate.
    @_transparent
    public init(catching body: () async throws -> Success) async {
        do {
            self = .success(try await body())
        } catch {
            self = .failure(error)
        }
    }
}
