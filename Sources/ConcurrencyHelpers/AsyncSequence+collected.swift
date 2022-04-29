//
//  AsyncSequence+collected.swift
//  ConcurrencyHelpers
//
//  Created by Josef Zoller on 29.04.22.
//

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension AsyncSequence {
    @inlinable
    public func collected() async rethrows -> [Element] {
        try await self.reduce(into: .init()) { $0.append($1) }
    }
}
