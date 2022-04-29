//
//  DropWhileSequenceAsync.swift
//  ConcurrencyHelpers
//
//  Created by Josef Zoller on 29.04.22.
//

/// A sequence that lazily consumes and drops elements from an underlying
/// `Base` iterator while an asynchronous predicate returns true before
/// possibly returning the first available element.
///
/// The underlying iterator's sequence may be infinite.
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
@frozen
public struct DropWhileSequenceAsync<Base: Sequence> {
    public typealias Element = Base.Element

    @usableFromInline
    internal var _iterator: Base.Iterator
    @usableFromInline
    internal var _nextElement: Element?
    
    @inlinable
    internal init(
        iterator: Base.Iterator,
        predicate: (Element) throws -> Bool
    ) rethrows {
        self._iterator = iterator
        self._nextElement = self._iterator.next()

        while let x = self._nextElement, try predicate(x) {
            self._nextElement = self._iterator.next()
        }
    }

    @inlinable
    internal init(
        iterator: Base.Iterator,
        predicate: (Element) async throws -> Bool
    ) async rethrows {
        self._iterator = iterator
        self._nextElement = self._iterator.next()

        while let x = self._nextElement, try await predicate(x) {
            self._nextElement = self._iterator.next()
        }
    }

    @inlinable
    internal init(
        _ base: Base,
        predicate: (Element) async throws -> Bool
    ) async rethrows {
        self = try await .init(iterator: base.makeIterator(),
                               predicate: predicate)
    }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension DropWhileSequenceAsync {
    @frozen
    public struct Iterator {
        @usableFromInline
        internal var _iterator: Base.Iterator
        @usableFromInline
        internal var _nextElement: Element?

        @inlinable
        internal init(_ iterator: Base.Iterator, nextElement: Element?) {
            self._iterator = iterator
            self._nextElement = nextElement
        }
    }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension DropWhileSequenceAsync.Iterator: IteratorProtocol {
    public typealias Element = Base.Element

    @inlinable
    public mutating func next() -> Element? {
        guard let next = self._nextElement else { return nil }
        self._nextElement = self._iterator.next()
        return next
    }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension DropWhileSequenceAsync: Sequence {
    @inlinable
    public func makeIterator() -> Iterator {
        return Iterator(self._iterator, nextElement: self._nextElement)
    }
    
    @inlinable
    public __consuming func drop(
        while predicate: (Element) throws -> Bool
    ) rethrows -> DropWhileSequenceAsync<Base> {
        guard let x = self._nextElement, try predicate(x) else { return self }
        return try .init(iterator: self._iterator, predicate: predicate)
    }

    @inlinable
    public __consuming func drop(
        while predicate: (Element) async throws -> Bool
    ) async rethrows -> DropWhileSequenceAsync<Base> {
        guard let x = self._nextElement,
              try await predicate(x) else { return self }
        return try await .init(iterator: self._iterator, predicate: predicate)
    }
}
