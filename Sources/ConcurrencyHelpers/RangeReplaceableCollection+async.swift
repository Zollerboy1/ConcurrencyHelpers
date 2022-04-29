//
//  RangeReplaceableCollection+async.swift
//  ConcurrencyHelpers
//
//  Created by Josef Zoller on 29.04.22.
//

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension RangeReplaceableCollection {
    /// Returns a new collection of the same type containing, in order, the
    /// elements of the original collection that satisfy the given predicate.
    ///
    /// In this example, `filter(_:)` is used to include only names shorter than
    /// five characters.
    ///
    ///     let cast = ["Vivien", "Marlon", "Kim", "Karl"]
    ///     let shortNames = cast.filter { $0.count < 5 }
    ///     print(shortNames)
    ///     // Prints "["Kim", "Karl"]"
    ///
    /// - Parameter isIncluded: An asynchronous closure that takes an element of
    ///   the sequence as its argument and returns a Boolean value indicating
    ///   whether the element should be included in the returned collection.
    /// - Returns: A collection of the elements that `isIncluded` allowed.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the collection.
    @inlinable
    public __consuming func filter(
        _ isIncluded: (Element) async throws -> Bool
    ) async rethrows -> Self {
        var result = Self()
        for element in self where try await isIncluded(element) {
            result.append(element)
        }
        return result
    }
    
    /// Removes all the elements that satisfy the given predicate.
    ///
    /// Use this method to remove every element in a collection that meets
    /// particular criteria. The order of the remaining elements is preserved.
    /// This example removes all the vowels from a string:
    ///
    ///     var phrase = "The rain in Spain stays mainly in the plain."
    ///
    ///     let vowels: Set<Character> = ["a", "e", "i", "o", "u"]
    ///     phrase.removeAll(where: { vowels.contains($0) })
    ///     // phrase == "Th rn n Spn stys mnly n th pln."
    ///
    /// - Parameter shouldBeRemoved: An asynchronous closure that takes an
    ///   element of the sequence as its argument and returns a Boolean
    ///   value indicating whether the element should be removed from the
    ///   collection.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the collection.
    @inlinable
    public mutating func removeAll(
        where shouldBeRemoved: (Element) async throws -> Bool
    ) async rethrows {
        self = try await self.filter { try await !shouldBeRemoved($0) }
    }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension RangeReplaceableCollection where Self: MutableCollection {
    /// Removes all the elements that satisfy the given predicate.
    ///
    /// Use this method to remove every element in a collection that meets
    /// particular criteria. The order of the remaining elements is preserved.
    /// This example removes all the odd values from an
    /// array of numbers:
    ///
    ///     var numbers = [5, 6, 7, 8, 9, 10, 11]
    ///     numbers.removeAll(where: { $0 % 2 != 0 })
    ///     // numbers == [6, 8, 10]
    ///
    /// - Parameter shouldBeRemoved: An asynchronous closure that takes an
    ///   element of the sequence as its argument and returns a Boolean value
    ///   indicating whether the element should be removed from the collection.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the collection.
    @inlinable
    public mutating func removeAll(
        where shouldBeRemoved: (Element) async throws -> Bool
    ) async rethrows {
        let suffixStart = try await self.partition(by: shouldBeRemoved)
        self.removeSubrange(suffixStart...)
    }
}
