//
//  BidirectionalCollection+async.swift
//  ConcurrencyHelpers
//
//  Created by Josef Zoller on 29.04.22.
//

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension BidirectionalCollection {
    /// Returns the last element of the sequence that satisfies the given
    /// predicate.
    ///
    /// This example uses the `last(where:)` method to find the last
    /// negative number in an array of integers:
    ///
    ///     let numbers = [3, 7, 4, -2, 9, -6, 10, 1]
    ///     if let lastNegative = numbers.last(where: { $0 < 0 }) {
    ///         print("The last negative number is \(lastNegative).")
    ///     }
    ///     // Prints "The last negative number is -6."
    ///
    /// - Parameter predicate: An asynchronous closure that takes an element of
    ///   the sequence as its argument and returns a Boolean value indicating
    ///   whether the element is a match.
    /// - Returns: The last element of the sequence that satisfies `predicate`,
    ///   or `nil` if there is no element that satisfies `predicate`.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the collection.
    @inlinable
    public func last(
        where predicate: (Element) async throws -> Bool
    ) async rethrows -> Element? {
        return try await self.lastIndex(where: predicate).map { self[$0] }
    }

    /// Returns the index of the last element in the collection that matches the
    /// given predicate.
    ///
    /// You can use the predicate to find an element of a type that doesn't
    /// conform to the `Equatable` protocol or to find an element that matches
    /// particular criteria. This example finds the index of the last name that
    /// begins with the letter *A:*
    ///
    ///     let students = ["Kofi", "Abena", "Peter", "Kweku", "Akosua"]
    ///     if let i = students.lastIndex(where: { $0.hasPrefix("A") }) {
    ///         print("\(students[i]) starts with 'A'!")
    ///     }
    ///     // Prints "Akosua starts with 'A'!"
    ///
    /// - Parameter predicate: An asynchronous closure that takes an element as
    ///   its argument and returns a Boolean value that indicates whether the
    ///   passed element represents a match.
    /// - Returns: The index of the last element in the collection that matches
    ///   `predicate`, or `nil` if no elements match.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the collection.
    @inlinable
    public func lastIndex(
        where predicate: (Element) async throws -> Bool
    ) async rethrows -> Index? {
        var i = self.endIndex
        while i != self.startIndex {
            self.formIndex(before: &i)
            if try await predicate(self[i]) {
                return i
            }
        }
        return nil
    }
}
