//
//  Sequence+async.swift
//  ConcurrencyHelpers
//
//  Created by Josef Zoller on 29.04.22.
//

import Foundation

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension Sequence {
    /// Returns an array containing the results of mapping the given
    /// asynchronous closure over the sequence's elements.
    ///
    /// In this example, ``map(_:)`` is used to download photos for the
    /// given names.
    ///
    ///     let photoNames = ["IMG001", "IMG99", "IMG0404"]
    ///     let photos = await photoNames.asyncMap { name in
    ///         await downloadPhoto(named: name)
    ///     }
    ///
    /// - Parameter transform: An asynchronous mapping closure. `transform`
    ///   accepts an element of this sequence as its parameter and returns a
    ///   transformed value of the same or of a different type.
    /// - Returns: An array containing the transformed elements of this
    ///   sequence.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the sequence.
    @inlinable
    public func map<R>(
        _ transform: (Element) async throws -> R
    ) async rethrows -> [R] {
        let initialCapacity = underestimatedCount
        var result = ContiguousArray<R>()
        result.reserveCapacity(initialCapacity)

        var iterator = self.makeIterator()

        for _ in 0..<initialCapacity {
            result.append(try await transform(iterator.next()!))
        }
        
        while let element = iterator.next() {
            result.append(try await transform(element))
        }
        
        return Array(result)
    }
    
    /// Returns an array containing, in order, the elements of the sequence
    /// that satisfy the given predicate.
    ///
    /// In this example, ``filter(_:)`` is used to include only names of
    /// photos that are smaller than one MiB.
    ///
    ///     let photoNames = ["IMG001", "IMG99", "IMG0404"]
    ///     let smallPhotoNames = await photoNames.asyncFilter { name in
    ///         await sizeOfPhoto(named: name) < 1_048_576
    ///     }
    ///
    /// - Parameter isIncluded: An asynchronous closure that takes an element
    ///   of the sequence as its argument and returns a Boolean value
    ///   indicating whether the element should be included in the returned
    ///   array.
    /// - Returns: An array of the elements that `isIncluded` allowed.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the sequence.
    @inlinable
    public __consuming func filter(
        _ isIncluded: (Element) async throws -> Bool
    ) async rethrows -> [Element] {
        var result = ContiguousArray<Element>()

        var iterator = self.makeIterator()

        while let element = iterator.next() {
            if try await isIncluded(element) {
                result.append(element)
            }
        }

        return Array(result)
    }
    
    /// Calls the given asynchronous closure on each element in the sequence in
    /// the same order as a `for`-`in` loop.
    ///
    /// The two loops in the following example produce the same output:
    ///
    ///     let photoNames = ["IMG001", "IMG99", "IMG0404"]
    ///     for name in photoNames {
    ///         print(await sizeOfPhoto(named: name))
    ///     }
    ///     // Prints the sizes of the three photos
    ///
    ///     await photoNames.forEach { name in
    ///         print(await sizeOfPhoto(named: name))
    ///     }
    ///     // Same as above
    ///
    /// Using the `forEach` method is distinct from a `for`-`in` loop in two
    /// important ways:
    ///
    /// 1. You cannot use a `break` or `continue` statement to exit the current
    ///    call of the `body` closure or skip subsequent calls.
    /// 2. Using the `return` statement in the `body` closure will exit only
    ///    from the current call to `body`, not from any outer scope, and won't
    ///    skip subsequent calls.
    ///
    /// - Parameter body: An asynchronous closure that takes an element of the
    ///   sequence as a parameter.
    @inlinable
    public func forEach(
        _ body: (Element) async throws -> ()
    ) async rethrows {
        for element in self {
            try await body(element)
        }
    }
    
    /// Returns the first element of the sequence that satisfies the given
    /// predicate.
    ///
    /// The following example uses the ``first(where:)`` method to find the
    /// name of the first photo smaller than one MiB:
    ///
    ///     let photoNames = ["IMG001", "IMG99", "IMG0404"]
    ///     if let smallPhotoName = await photoNames.first(where: { name in
    ///         await sizeOfPhoto(named: name) < 1_048_576
    ///     }) {
    ///         print("The first small photo is named '\(smallPhotoName)'.")
    ///     }
    ///     // Prints e.g. "The first negative number is 'IMG99'."
    ///
    /// - Parameter predicate: An asynchronous closure that takes an element of
    ///   the sequence as its argument and returns a Boolean value indicating
    ///   whether the element is a match.
    /// - Returns: The first element of the sequence that satisfies `predicate`,
    ///   or `nil` if there is no element that satisfies `predicate`.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the sequence.
    @inlinable
    public func first(
        where predicate: (Element) async throws -> Bool
    ) async rethrows -> Element? {
        for element in self {
            if try await predicate(element) {
                return element
            }
        }
        return nil
    }
    
    /// Returns the longest possible subsequences of the sequence, in order, that
    /// don't contain elements satisfying the given predicate. Elements that are
    /// used to split the sequence are not returned as part of any subsequence.
    ///
    /// The following examples show the effects of the `maxSplits` and
    /// `omittingEmptySubsequences` parameters when splitting a string using a
    /// closure that matches spaces. The first use of `split` returns each word
    /// that was originally separated by one or more spaces.
    ///
    ///     let line = "BLANCHE:   I don't want realism. I want magic!"
    ///     print(line.split(whereSeparator: { $0 == " " })
    ///               .map(String.init))
    ///     // Prints "["BLANCHE:", "I", "don\'t", "want", "realism.", "I", "want", "magic!"]"
    ///
    /// The second example passes `1` for the `maxSplits` parameter, so the
    /// original string is split just once, into two new strings.
    ///
    ///     print(
    ///        line.split(maxSplits: 1, whereSeparator: { $0 == " " })
    ///                       .map(String.init))
    ///     // Prints "["BLANCHE:", "  I don\'t want realism. I want magic!"]"
    ///
    /// The final example passes `true` for the `allowEmptySlices` parameter, so
    /// the returned array contains empty strings where spaces were repeated.
    ///
    ///     print(
    ///         line.split(
    ///             omittingEmptySubsequences: false,
    ///             whereSeparator: { $0 == " " }
    ///         ).map(String.init))
    ///     // Prints "["BLANCHE:", "", "", "I", "don\'t", "want", "realism.", "I", "want", "magic!"]"
    ///
    /// - Parameters:
    ///   - maxSplits: The maximum number of times to split the sequence, or one
    ///     less than the number of subsequences to return. If `maxSplits + 1`
    ///     subsequences are returned, the last one is a suffix of the original
    ///     sequence containing the remaining elements. `maxSplits` must be
    ///     greater than or equal to zero. The default value is `Int.max`.
    ///   - omittingEmptySubsequences: If `false`, an empty subsequence is
    ///     returned in the result for each pair of consecutive elements
    ///     satisfying the `isSeparator` predicate and for each element at the
    ///     start or end of the sequence satisfying the `isSeparator` predicate.
    ///     If `true`, only nonempty subsequences are returned. The default
    ///     value is `true`.
    ///   - isSeparator: An asynchronous closure that returns `true` if its
    ///     argument should be used to split the sequence; otherwise, `false`.
    /// - Returns: An array of subsequences, split from this sequence's elements.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the sequence.
    @inlinable
    public __consuming func split(
        maxSplits: Int = Int.max,
        omittingEmptySubsequences: Bool = true,
        whereSeparator isSeparator: (Element) async throws -> Bool
    ) async rethrows -> [ArraySlice<Element>] {
        precondition(maxSplits >= 0, "Must take zero or more splits")
        let whole = Array(self)
        return try await whole.split(
                            maxSplits: maxSplits,
                            omittingEmptySubsequences: omittingEmptySubsequences,
                            whereSeparator: isSeparator)
    }
    
    /// Returns a sequence by skipping the initial, consecutive elements that
    /// satisfy the given predicate.
    ///
    /// The following example uses the ``drop(while:)`` method to skip over the
    /// positive numbers at the beginning of the `numbers` array. The result
    /// begins with the first element of `numbers` that does not satisfy
    /// `predicate`.
    ///
    ///     let numbers = [3, 7, 4, -2, 9, -6, 10, 1]
    ///     let startingWithNegative = numbers.drop(while: { $0 > 0 })
    ///     // startingWithNegative == [-2, 9, -6, 10, 1]
    ///
    /// If `predicate` matches every element in the sequence, the result is an
    /// empty sequence.
    ///
    /// - Parameter predicate: An asynchronous closure that takes an element of
    ///   the sequence as its argument and returns a Boolean value indicating
    ///   whether the element should be included in the result.
    /// - Returns: A sequence starting after the initial, consecutive elements
    ///   that satisfy `predicate`.
    ///
    /// - Complexity: O(*k*), where *k* is the number of elements to drop from
    ///   the beginning of the sequence.
    @inlinable
    public __consuming func drop(
        while predicate: (Element) async throws -> Bool
    ) async rethrows -> DropWhileSequenceAsync<Self> {
        return try await DropWhileSequenceAsync(self, predicate: predicate)
    }
    
    /// Returns a sequence containing the initial, consecutive elements that
    /// satisfy the given predicate.
    ///
    /// The following example uses the `prefix(while:)` method to find the
    /// positive numbers at the beginning of the `numbers` array. Every element
    /// of `numbers` up to, but not including, the first negative value is
    /// included in the result.
    ///
    ///     let numbers = [3, 7, 4, -2, 9, -6, 10, 1]
    ///     let positivePrefix = numbers.prefix(while: { $0 > 0 })
    ///     // positivePrefix == [3, 7, 4]
    ///
    /// If `predicate` matches every element in the sequence, the resulting
    /// sequence contains every element of the sequence.
    ///
    /// - Parameter predicate: An asynchronous closure that takes an element of
    ///   the sequence as its argument and returns a Boolean value indicating
    ///   whether the element should be included in the result.
    /// - Returns: A sequence of the initial, consecutive elements that
    ///   satisfy `predicate`.
    ///
    /// - Complexity: O(*k*), where *k* is the length of the result.
    @inlinable
    public __consuming func prefix(
        while predicate: (Element) async throws -> Bool
    ) async rethrows -> [Element] {
        var result = ContiguousArray<Element>()

        for element in self {
            guard try await predicate(element) else {
                break
            }
            result.append(element)
        }
        return Array(result)
    }
    
    /// Returns the minimum element in the sequence, using the given predicate as
    /// the comparison between elements.
    ///
    /// The predicate must be a *strict weak ordering* over the elements. That
    /// is, for any elements `a`, `b`, and `c`, the following conditions must
    /// hold:
    ///
    /// - `areInIncreasingOrder(a, a)` is always `false`. (Irreflexivity)
    /// - If `areInIncreasingOrder(a, b)` and `areInIncreasingOrder(b, c)` are
    ///   both `true`, then `areInIncreasingOrder(a, c)` is also
    ///   `true`. (Transitive comparability)
    /// - Two elements are *incomparable* if neither is ordered before the other
    ///   according to the predicate. If `a` and `b` are incomparable, and `b`
    ///   and `c` are incomparable, then `a` and `c` are also incomparable.
    ///   (Transitive incomparability)
    ///
    /// This example shows how to use the `min(by:)` method on a
    /// dictionary to find the key-value pair with the lowest value.
    ///
    ///     let hues = ["Heliotrope": 296, "Coral": 16, "Aquamarine": 156]
    ///     let leastHue = hues.min { a, b in a.value < b.value }
    ///     print(leastHue)
    ///     // Prints "Optional((key: "Coral", value: 16))"
    ///
    /// - Parameter areInIncreasingOrder: An asynchronous predicate that
    ///   returns `true` if its first argument should be ordered before its
    ///   second argument; otherwise, `false`.
    /// - Returns: The sequence's minimum element, according to
    ///   `areInIncreasingOrder`. If the sequence has no elements, returns
    ///   `nil`.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the sequence.
    @inlinable // protocol-only
    @warn_unqualified_access
    public func min(
        by areInIncreasingOrder: (Element, Element) async throws -> Bool
    ) async rethrows -> Element? {
        var it = self.makeIterator()
        guard var result = it.next() else { return nil }
        while let e = it.next() {
            if try await areInIncreasingOrder(e, result) { result = e }
        }
        return result
    }
    
    /// Returns the maximum element in the sequence, using the given predicate
    /// as the comparison between elements.
    ///
    /// The predicate must be a *strict weak ordering* over the elements. That
    /// is, for any elements `a`, `b`, and `c`, the following conditions must
    /// hold:
    ///
    /// - `areInIncreasingOrder(a, a)` is always `false`. (Irreflexivity)
    /// - If `areInIncreasingOrder(a, b)` and `areInIncreasingOrder(b, c)` are
    ///   both `true`, then `areInIncreasingOrder(a, c)` is also
    ///   `true`. (Transitive comparability)
    /// - Two elements are *incomparable* if neither is ordered before the other
    ///   according to the predicate. If `a` and `b` are incomparable, and `b`
    ///   and `c` are incomparable, then `a` and `c` are also incomparable.
    ///   (Transitive incomparability)
    ///
    /// This example shows how to use the `max(by:)` method on a
    /// dictionary to find the key-value pair with the highest value.
    ///
    ///     let hues = ["Heliotrope": 296, "Coral": 16, "Aquamarine": 156]
    ///     let greatestHue = hues.max { a, b in a.value < b.value }
    ///     print(greatestHue)
    ///     // Prints "Optional((key: "Heliotrope", value: 296))"
    ///
    /// - Parameter areInIncreasingOrder: An asynchronous predicate that
    ///   returns `true` if its first argument should be ordered before its
    ///   second argument; otherwise, `false`.
    /// - Returns: The sequence's maximum element if the sequence is not empty;
    ///   otherwise, `nil`.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the sequence.
    @inlinable // protocol-only
    @warn_unqualified_access
    public func max(
        by areInIncreasingOrder: (Element, Element) async throws -> Bool
    ) async rethrows -> Element? {
        var it = makeIterator()
        guard var result = it.next() else { return nil }
        while let e = it.next() {
            if try await areInIncreasingOrder(result, e) { result = e }
        }
        return result
    }
    
    /// Returns a Boolean value indicating whether the initial elements of the
    /// sequence are equivalent to the elements in another sequence, using
    /// the given predicate as the equivalence test.
    ///
    /// The predicate must be a *equivalence relation* over the elements. That
    /// is, for any elements `a`, `b`, and `c`, the following conditions must
    /// hold:
    ///
    /// - `areEquivalent(a, a)` is always `true`. (Reflexivity)
    /// - `areEquivalent(a, b)` implies `areEquivalent(b, a)`. (Symmetry)
    /// - If `areEquivalent(a, b)` and `areEquivalent(b, c)` are both `true`, then
    ///   `areEquivalent(a, c)` is also `true`. (Transitivity)
    ///
    /// - Parameters:
    ///   - possiblePrefix: A sequence to compare to this sequence.
    ///   - areEquivalent: An asynchronous predicate that returns `true` if its
    ///     two arguments are equivalent; otherwise, `false`.
    /// - Returns: `true` if the initial elements of the sequence are equivalent
    ///   to the elements of `possiblePrefix`; otherwise, `false`. If
    ///   `possiblePrefix` has no elements, the return value is `true`.
    ///
    /// - Complexity: O(*m*), where *m* is the lesser of the length of the
    ///   sequence and the length of `possiblePrefix`.
    @inlinable
    public func starts<PossiblePrefix: Sequence>(
        with possiblePrefix: PossiblePrefix,
        by areEquivalent: (Element, PossiblePrefix.Element) async throws -> Bool
    ) async rethrows -> Bool {
        var possiblePrefixIterator = possiblePrefix.makeIterator()
        for e0 in self {
            if let e1 = possiblePrefixIterator.next() {
                if try await !areEquivalent(e0, e1) {
                    return false
                }
            }
            else {
                return true
            }
        }
        return possiblePrefixIterator.next() == nil
    }
    
    /// Returns a Boolean value indicating whether this sequence and another
    /// sequence contain equivalent elements in the same order, using the given
    /// predicate as the equivalence test.
    ///
    /// At least one of the sequences must be finite.
    ///
    /// The predicate must be a *equivalence relation* over the elements. That
    /// is, for any elements `a`, `b`, and `c`, the following conditions must
    /// hold:
    ///
    /// - `areEquivalent(a, a)` is always `true`. (Reflexivity)
    /// - `areEquivalent(a, b)` implies `areEquivalent(b, a)`. (Symmetry)
    /// - If `areEquivalent(a, b)` and `areEquivalent(b, c)` are both `true`, then
    ///   `areEquivalent(a, c)` is also `true`. (Transitivity)
    ///
    /// - Parameters:
    ///   - other: A sequence to compare to this sequence.
    ///   - areEquivalent: An asynchronous predicate that returns `true` if its
    ///     two arguments are equivalent; otherwise, `false`.
    /// - Returns: `true` if this sequence and `other` contain equivalent items,
    ///   using `areEquivalent` as the equivalence test; otherwise, `false.`
    ///
    /// - Complexity: O(*m*), where *m* is the lesser of the length of the
    ///   sequence and the length of `other`.
    @inlinable
    public func elementsEqual<OtherSequence: Sequence>(
        _ other: OtherSequence,
        by areEquivalent: (Element, OtherSequence.Element) async throws -> Bool
    ) async rethrows -> Bool {
        var iter1 = self.makeIterator()
        var iter2 = other.makeIterator()
        while true {
            switch (iter1.next(), iter2.next()) {
            case let (e1?, e2?):
                if try await !areEquivalent(e1, e2) {
                    return false
                }
            case (_?, nil), (nil, _?): return false
            case (nil, nil):           return true
            }
        }
    }
    
    /// Returns a Boolean value indicating whether the sequence precedes another
    /// sequence in a lexicographical (dictionary) ordering, using the given
    /// predicate to compare elements.
    ///
    /// The predicate must be a *strict weak ordering* over the elements. That
    /// is, for any elements `a`, `b`, and `c`, the following conditions must
    /// hold:
    ///
    /// - `areInIncreasingOrder(a, a)` is always `false`. (Irreflexivity)
    /// - If `areInIncreasingOrder(a, b)` and `areInIncreasingOrder(b, c)` are
    ///   both `true`, then `areInIncreasingOrder(a, c)` is also
    ///   `true`. (Transitive comparability)
    /// - Two elements are *incomparable* if neither is ordered before the other
    ///   according to the predicate. If `a` and `b` are incomparable, and `b`
    ///   and `c` are incomparable, then `a` and `c` are also incomparable.
    ///   (Transitive incomparability)
    ///
    /// - Parameters:
    ///   - other: A sequence to compare to this sequence.
    ///   - areInIncreasingOrder: An asynchronous predicate that returns `true`
    ///     if its first argument should be ordered before its second argument;
    ///     otherwise, `false`.
    /// - Returns: `true` if this sequence precedes `other` in a dictionary
    ///   ordering as ordered by `areInIncreasingOrder`; otherwise, `false`.
    ///
    /// - Note: This method implements the mathematical notion of lexicographical
    ///   ordering, which has no connection to Unicode.  If you are sorting
    ///   strings to present to the end user, use `String` APIs that perform
    ///   localized comparison instead.
    ///
    /// - Complexity: O(*m*), where *m* is the lesser of the length of the
    ///   sequence and the length of `other`.
    @inlinable
    public func lexicographicallyPrecedes<OtherSequence: Sequence>(
        _ other: OtherSequence,
        by areInIncreasingOrder: (Element, Element) async throws -> Bool
    ) async rethrows -> Bool
    where OtherSequence.Element == Element {
        var iter1 = self.makeIterator()
        var iter2 = other.makeIterator()
        while true {
            if let e1 = iter1.next() {
                if let e2 = iter2.next() {
                    if try await areInIncreasingOrder(e1, e2) {
                        return true
                    }
                    if try await areInIncreasingOrder(e2, e1) {
                        return false
                    }
                    continue // Equivalent
                }
                return false
            }

            return iter2.next() != nil
        }
    }
    
    /// Returns a Boolean value indicating whether the sequence contains an
    /// element that satisfies the given predicate.
    ///
    /// You can use the predicate to check for an element of a type that
    /// doesn't conform to the `Equatable` protocol, such as the
    /// `HTTPResponse` enumeration in this example.
    ///
    ///     enum HTTPResponse {
    ///         case ok
    ///         case error(Int)
    ///     }
    ///
    ///     let lastThreeResponses: [HTTPResponse] = [.ok, .ok, .error(404)]
    ///     let hadError = lastThreeResponses.contains { element in
    ///         if case .error = element {
    ///             return true
    ///         } else {
    ///             return false
    ///         }
    ///     }
    ///     // 'hadError' == true
    ///
    /// Alternatively, a predicate can be satisfied by a range of `Equatable`
    /// elements or a general condition. This example shows how you can check an
    /// array for an expense greater than $100.
    ///
    ///     let expenses = [21.37, 55.21, 9.32, 10.18, 388.77, 11.41]
    ///     let hasBigPurchase = expenses.contains { $0 > 100 }
    ///     // 'hasBigPurchase' == true
    ///
    /// - Parameter predicate: An asynchronous closure that takes an element of
    ///   the sequence as its argument and returns a Boolean value that
    ///   indicates whether the passed element represents a match.
    /// - Returns: `true` if the sequence contains an element that satisfies
    ///   `predicate`; otherwise, `false`.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the sequence.
    @inlinable
    public func contains(
        where predicate: (Element) async throws -> Bool
    ) async rethrows -> Bool {
        for e in self {
            if try await predicate(e) {
                return true
            }
        }
        return false
    }

    /// Returns a Boolean value indicating whether every element of a sequence
    /// satisfies a given predicate.
    ///
    /// The following code uses this method to test whether all the names in an
    /// array have at least five characters:
    ///
    ///     let names = ["Sofia", "Camilla", "Martina", "Mateo", "Nicolás"]
    ///     let allHaveAtLeastFive = names.allSatisfy({ $0.count >= 5 })
    ///     // allHaveAtLeastFive == true
    ///
    /// If the sequence is empty, this method returns `true`.
    ///
    /// - Parameter predicate: An asynchronous closure that takes an element of
    ///   the sequence as its argument and returns a Boolean value that
    ///   indicates whether the passed element satisfies a condition.
    /// - Returns: `true` if the sequence contains only elements that satisfy
    ///   `predicate`; otherwise, `false`.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the sequence.
    @inlinable
    public func allSatisfy(
        _ predicate: (Element) async throws -> Bool
    ) async rethrows -> Bool {
        return try await !contains { try await !predicate($0) }
    }
    
    /// Returns the result of combining the elements of the sequence using the
    /// given closure.
    ///
    /// Use the `reduce(_:_:)` method to produce a single value from the elements
    /// of an entire sequence. For example, you can use this method on an array
    /// of numbers to find their sum or product.
    ///
    /// The `nextPartialResult` closure is called sequentially with an
    /// accumulating value initialized to `initialResult` and each element of
    /// the sequence. This example shows how to find the sum of an array of
    /// numbers.
    ///
    ///     let numbers = [1, 2, 3, 4]
    ///     let numberSum = numbers.reduce(0, { x, y in
    ///         x + y
    ///     })
    ///     // numberSum == 10
    ///
    /// When `numbers.reduce(_:_:)` is called, the following steps occur:
    ///
    /// 1. The `nextPartialResult` closure is called with `initialResult`---`0`
    ///    in this case---and the first element of `numbers`, returning the sum:
    ///    `1`.
    /// 2. The closure is called again repeatedly with the previous call's return
    ///    value and each element of the sequence.
    /// 3. When the sequence is exhausted, the last value returned from the
    ///    closure is returned to the caller.
    ///
    /// If the sequence has no elements, `nextPartialResult` is never executed
    /// and `initialResult` is the result of the call to `reduce(_:_:)`.
    ///
    /// - Parameters:
    ///   - initialResult: The value to use as the initial accumulating value.
    ///     `initialResult` is passed to `nextPartialResult` the first time the
    ///     closure is executed.
    ///   - nextPartialResult: An asynchronous closure that combines an
    ///     accumulating value and an element of the sequence into a new
    ///     accumulating value, to be used in the next call of the
    ///     `nextPartialResult` closure or returned to the caller.
    /// - Returns: The final accumulated value. If the sequence has no elements,
    ///   the result is `initialResult`.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the sequence.
    @inlinable
    public func reduce<Result>(
        _ initialResult: Result,
        _ nextPartialResult:
            (_ partialResult: Result, Element) async throws -> Result
    ) async rethrows -> Result {
        var accumulator = initialResult
        for element in self {
            accumulator = try await nextPartialResult(accumulator, element)
        }
        return accumulator
    }
    
    /// Returns the result of combining the elements of the sequence using the
    /// given closure.
    ///
    /// Use the `reduce(into:_:)` method to produce a single value from the
    /// elements of an entire sequence. For example, you can use this method on an
    /// array of integers to filter adjacent equal entries or count frequencies.
    ///
    /// This method is preferred over `reduce(_:_:)` for efficiency when the
    /// result is a copy-on-write type, for example an Array or a Dictionary.
    ///
    /// The `updateAccumulatingResult` closure is called sequentially with a
    /// mutable accumulating value initialized to `initialResult` and each element
    /// of the sequence. This example shows how to build a dictionary of letter
    /// frequencies of a string.
    ///
    ///     let letters = "abracadabra"
    ///     let letterCount = letters.reduce(into: [:]) { counts, letter in
    ///         counts[letter, default: 0] += 1
    ///     }
    ///     // letterCount == ["a": 5, "b": 2, "r": 2, "c": 1, "d": 1]
    ///
    /// When `letters.reduce(into:_:)` is called, the following steps occur:
    ///
    /// 1. The `updateAccumulatingResult` closure is called with the initial
    ///    accumulating value---`[:]` in this case---and the first character of
    ///    `letters`, modifying the accumulating value by setting `1` for the key
    ///    `"a"`.
    /// 2. The closure is called again repeatedly with the updated accumulating
    ///    value and each element of the sequence.
    /// 3. When the sequence is exhausted, the accumulating value is returned to
    ///    the caller.
    ///
    /// If the sequence has no elements, `updateAccumulatingResult` is never
    /// executed and `initialResult` is the result of the call to
    /// `reduce(into:_:)`.
    ///
    /// - Parameters:
    ///   - initialResult: The value to use as the initial accumulating value.
    ///   - updateAccumulatingResult: An asynchronous closure that updates the
    ///     accumulating value with an element of the sequence.
    /// - Returns: The final accumulated value. If the sequence has no elements,
    ///   the result is `initialResult`.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the sequence.
    @inlinable
    public func reduce<Result>(
        into initialResult: __owned Result,
        _ updateAccumulatingResult:
            (_ partialResult: inout Result, Element) async throws -> ()
    ) async rethrows -> Result {
        var accumulator = initialResult
        for element in self {
            try await updateAccumulatingResult(&accumulator, element)
        }
        return accumulator
    }
    
    /// Returns an array containing the concatenated results of calling the
    /// given transformation with each element of this sequence.
    ///
    /// Use this method to receive a single-level collection when your
    /// transformation produces a sequence or collection for each element.
    ///
    /// In this example, note the difference in the result of using `map` and
    /// `flatMap` with a transformation that returns an array.
    ///
    ///     let numbers = [1, 2, 3, 4]
    ///
    ///     let mapped = numbers.map { Array(repeating: $0, count: $0) }
    ///     // [[1], [2, 2], [3, 3, 3], [4, 4, 4, 4]]
    ///
    ///     let flatMapped = numbers.flatMap { Array(repeating: $0, count: $0) }
    ///     // [1, 2, 2, 3, 3, 3, 4, 4, 4, 4]
    ///
    /// In fact, `s.flatMap(transform)`  is equivalent to
    /// `Array(s.map(transform).joined())`.
    ///
    /// - Parameter transform: An asynchronous closure that accepts an element
    ///   of this sequence as its argument and returns a sequence or
    ///   collection.
    /// - Returns: The resulting flattened array.
    ///
    /// - Complexity: O(*m* + *n*), where *n* is the length of this sequence
    ///   and *m* is the length of the result.
    @inlinable
    public func flatMap<SegmentOfResult: Sequence>(
        _ transform: (Element) async throws -> SegmentOfResult
    ) async rethrows -> [SegmentOfResult.Element] {
        var result: [SegmentOfResult.Element] = []
        for element in self {
            result.append(contentsOf: try await transform(element))
        }
        return result
    }
    
    /// Returns an array containing the non-`nil` results of calling the given
    /// transformation with each element of this sequence.
    ///
    /// Use this method to receive an array of non-optional values when your
    /// transformation produces an optional value.
    ///
    /// In this example, note the difference in the result of using `map` and
    /// `compactMap` with a transformation that returns an optional `Int` value.
    ///
    ///     let possibleNumbers = ["1", "2", "three", "///4///", "5"]
    ///
    ///     let mapped: [Int?] = possibleNumbers.map { str in Int(str) }
    ///     // [1, 2, nil, nil, 5]
    ///
    ///     let compactMapped: [Int] = possibleNumbers.compactMap { str in Int(str) }
    ///     // [1, 2, 5]
    ///
    /// - Parameter transform: An asynchronous closure that accepts an element
    ///   of this sequence as its argument and returns an optional value.
    /// - Returns: An array of the non-`nil` results of calling `transform`
    ///   with each element of the sequence.
    ///
    /// - Complexity: O(*m* + *n*), where *n* is the length of this sequence
    ///   and *m* is the length of the result.
    @inlinable // protocol-only
    public func compactMap<ElementOfResult>(
        _ transform: (Element) async throws -> ElementOfResult?
    ) async rethrows -> [ElementOfResult] {
        var result: [ElementOfResult] = []
        for element in self {
          if let newElement = try await transform(element) {
              result.append(newElement)
          }
        }
        return result
    }
}
