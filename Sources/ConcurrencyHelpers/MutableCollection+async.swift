//
//  MutableCollection+async.swift
//  ConcurrencyHelpers
//
//  Created by Josef Zoller on 29.04.22.
//

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension MutableCollection {
    /// Reorders the elements of the collection such that all the elements
    /// that match the given predicate are after all the elements that don't
    /// match.
    ///
    /// After partitioning a collection, there is a pivot index `p` where
    /// no element before `p` satisfies the `belongsInSecondPartition`
    /// predicate and every element at or after `p` satisfies
    /// `belongsInSecondPartition`. This operation isn't guaranteed to be
    /// stable, so the relative ordering of elements within the partitions might
    /// change.
    ///
    /// In the following example, an array of numbers is partitioned by a
    /// predicate that matches elements greater than 30.
    ///
    ///     var numbers = [30, 40, 20, 30, 30, 60, 10]
    ///     let p = numbers.partition(by: { $0 > 30 })
    ///     // p == 5
    ///     // numbers == [30, 10, 20, 30, 30, 60, 40]
    ///
    /// The `numbers` array is now arranged in two partitions. The first
    /// partition, `numbers[..<p]`, is made up of the elements that
    /// are not greater than 30. The second partition, `numbers[p...]`,
    /// is made up of the elements that *are* greater than 30.
    ///
    ///     let first = numbers[..<p]
    ///     // first == [30, 10, 20, 30, 30]
    ///     let second = numbers[p...]
    ///     // second == [60, 40]
    ///
    /// Note that the order of elements in both partitions changed.
    /// That is, `40` appears before `60` in the original collection,
    /// but, after calling `partition(by:)`, `60` appears before `40`.
    ///
    /// - Parameter belongsInSecondPartition: An asynchronous predicate used to
    ///   partition the collection. All elements satisfying this predicate are
    ///   ordered after all elements not satisfying it.
    /// - Returns: The index of the first element in the reordered collection
    ///   that matches `belongsInSecondPartition`. If no elements in the
    ///   collection match `belongsInSecondPartition`, the returned index is
    ///   equal to the collection's `endIndex`.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the collection.
    @inlinable
    public mutating func partition(
        by belongsInSecondPartition: (Element) async throws -> Bool
    ) async rethrows -> Index {
        guard var i = try await self.firstIndex(where: belongsInSecondPartition) else {
            return self.endIndex
        }

        var j = self.index(after: i)
        while j != self.endIndex {
            if try await !belongsInSecondPartition(self[j]) {
                self.swapAt(i, j)
                self.formIndex(after: &i)
            }
            self.formIndex(after: &j)
        }
        return i
    }
}
