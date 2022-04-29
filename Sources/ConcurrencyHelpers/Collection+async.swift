//
//  Collection+async.swift
//  ConcurrencyHelpers
//
//  Created by Josef Zoller on 29.04.22.
//

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension Collection {
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
        let n = self.count
        if n == 0 {
            return []
        }

        var result = ContiguousArray<R>()
        result.reserveCapacity(n)

        var i = self.startIndex

        for _ in 0..<n {
            result.append(try await transform(self[i]))
            self.formIndex(after: &i)
        }

        return Array(result)
    }
    
    /// Returns a subsequence by skipping elements while `predicate` returns
    /// `true` and returning the remaining elements.
    ///
    /// - Parameter predicate: An asynchronous closure that takes an element of
    ///   the sequence as its argument and returns `true` if the element should
    ///   be skipped or `false` if it should be included. Once the predicate
    ///   returns `false` it will not be called again.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the collection.
    @inlinable
    public __consuming func drop(
        while predicate: (Element) async throws -> Bool
    ) async rethrows -> SubSequence {
        var start = self.startIndex
        while start != self.endIndex {
            guard try await predicate(self[start]) else { break }
            
            self.formIndex(after: &start)
        }
        return self[start..<self.endIndex]
    }
    
    /// Returns a subsequence containing the initial elements until `predicate`
    /// returns `false` and skipping the remaining elements.
    ///
    /// - Parameter predicate: An asynchronous closure that takes an element of
    ///   the sequence as its argument and returns `true` if the element should
    ///   be included or `false` if it should be excluded. Once the predicate
    ///   returns `false` it will not be called again.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the collection.
    @inlinable
    public __consuming func prefix(
        while predicate: (Element) async throws -> Bool
    ) async rethrows -> SubSequence {
        var end = self.startIndex
        while end != self.endIndex {
            guard try await predicate(self[end]) else { break }
            
            self.formIndex(after: &end)
        }
        return self[startIndex..<end]
    }
    
    /// Returns the longest possible subsequences of the collection, in order,
    /// that don't contain elements satisfying the given predicate.
    ///
    /// The resulting array consists of at most `maxSplits + 1` subsequences.
    /// Elements that are used to split the sequence are not returned as part of
    /// any subsequence.
    ///
    /// The following examples show the effects of the `maxSplits` and
    /// `omittingEmptySubsequences` parameters when splitting a string using a
    /// closure that matches spaces. The first use of `split` returns each word
    /// that was originally separated by one or more spaces.
    ///
    ///     let line = "BLANCHE:   I don't want realism. I want magic!"
    ///     print(line.split(whereSeparator: { $0 == " " }))
    ///     // Prints "["BLANCHE:", "I", "don\'t", "want", "realism.", "I", "want", "magic!"]"
    ///
    /// The second example passes `1` for the `maxSplits` parameter, so the
    /// original string is split just once, into two new strings.
    ///
    ///     print(line.split(maxSplits: 1, whereSeparator: { $0 == " " }))
    ///     // Prints "["BLANCHE:", "  I don\'t want realism. I want magic!"]"
    ///
    /// The final example passes `false` for the `omittingEmptySubsequences`
    /// parameter, so the returned array contains empty strings where spaces
    /// were repeated.
    ///
    ///     print(line.split(omittingEmptySubsequences: false, whereSeparator: { $0 == " " }))
    ///     // Prints "["BLANCHE:", "", "", "I", "don\'t", "want", "realism.", "I", "want", "magic!"]"
    ///
    /// - Parameters:
    ///   - maxSplits: The maximum number of times to split the collection, or
    ///     one less than the number of subsequences to return. If
    ///     `maxSplits + 1` subsequences are returned, the last one is a suffix
    ///     of the original collection containing the remaining elements.
    ///     `maxSplits` must be greater than or equal to zero. The default value
    ///     is `Int.max`.
    ///   - omittingEmptySubsequences: If `false`, an empty subsequence is
    ///     returned in the result for each pair of consecutive elements
    ///     satisfying the `isSeparator` predicate and for each element at the
    ///     start or end of the collection satisfying the `isSeparator`
    ///     predicate. The default value is `true`.
    ///   - isSeparator: An asynchronous closure that takes an element as an
    ///     argument and returns a Boolean value indicating whether the
    ///     collection should be split at that element.
    /// - Returns: An array of subsequences, split from this collection's
    ///   elements.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the collection.
    @inlinable
    public __consuming func split(
        maxSplits: Int = Int.max,
        omittingEmptySubsequences: Bool = true,
        whereSeparator isSeparator: (Element) async throws -> Bool
    ) async rethrows -> [SubSequence] {
        precondition(maxSplits >= 0, "Must take zero or more splits")
        
        var result: [SubSequence] = []
        var subSequenceStart: Index = self.startIndex
        
        func appendSubsequence(end: Index) -> Bool {
            if subSequenceStart == end && omittingEmptySubsequences {
                return false
            }
            result.append(self[subSequenceStart..<end])
            return true
        }
        
        if maxSplits == 0 || self.isEmpty {
            _ = appendSubsequence(end: self.endIndex)
            return result
        }
        
        var subSequenceEnd = subSequenceStart
        let cachedEndIndex = self.endIndex
        while subSequenceEnd != cachedEndIndex {
            if try await isSeparator(self[subSequenceEnd]) {
                let didAppend = appendSubsequence(end: subSequenceEnd)
                self.formIndex(after: &subSequenceEnd)
                subSequenceStart = subSequenceEnd
                if didAppend && result.count == maxSplits {
                    break
                }
                continue
            }
            self.formIndex(after: &subSequenceEnd)
        }
        
        if subSequenceStart != cachedEndIndex || !omittingEmptySubsequences {
            result.append(self[subSequenceStart..<cachedEndIndex])
        }
        
        return result
    }
    
    /// Returns the first index in which an element of the collection satisfies
    /// the given predicate.
    ///
    /// You can use the predicate to find an element of a type that doesn't
    /// conform to the `Equatable` protocol or to find an element that matches
    /// particular criteria. Here's an example that finds a student name that
    /// begins with the letter "A":
    ///
    ///     let students = ["Kofi", "Abena", "Peter", "Kweku", "Akosua"]
    ///     if let i = students.firstIndex(where: { $0.hasPrefix("A") }) {
    ///         print("\(students[i]) starts with 'A'!")
    ///     }
    ///     // Prints "Abena starts with 'A'!"
    ///
    /// - Parameter predicate: An asynchronous closure that takes an element as
    ///   its argument and returns a Boolean value that indicates whether the
    ///   passed element represents a match.
    /// - Returns: The index of the first element for which `predicate` returns
    ///   `true`. If no elements in the collection satisfy the given predicate,
    ///   returns `nil`.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the collection.
    @inlinable
    public func firstIndex(
        where predicate: (Element) async throws -> Bool
    ) async rethrows -> Index? {
        var i = self.startIndex
        while i != self.endIndex {
            if try await predicate(self[i]) {
                return i
            }
            self.formIndex(after: &i)
        }
        return nil
    }
}
