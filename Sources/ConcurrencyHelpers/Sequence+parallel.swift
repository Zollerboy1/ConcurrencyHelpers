//
//  Sequence+concurrent.swift
//  ConcurrencyHelpers
//
//  Created by Josef Zoller on 29.04.22.
//

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension Sequence where Element: Sendable {
    @inlinable
    public func parallelMap<R>(
        _ transform: @escaping @Sendable (Element) async throws -> R
    ) async rethrows -> [R] where R: Sendable {
        try await withThrowingTaskGroup(of: R.self) { group in
            for element in self {
                group.addTask {
                    try await transform(element)
                }
            }
            
            return try await group.collected()
        }
    }
    
    @inlinable
    public func parallelCompactMap<R>(
        _ transform: @escaping @Sendable (Element) async throws -> R?
    ) async rethrows -> [R] where R: Sendable {
        try await withThrowingTaskGroup(of: R?.self) { group in
            for element in self {
                group.addTask {
                    try await transform(element)
                }
            }
            
            return try await group.collected().compactMap { $0 }
        }
    }
    
    @inlinable
    public func parallelForEach(
        _ body: @escaping @Sendable (Element) async throws -> ()
    ) async rethrows {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for element in self {
                group.addTask {
                    try await body(element)
                }
            }
            
            try await group.waitForAll()
        }
    }
}
