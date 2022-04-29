//
//  Collection+concurrent.swift
//  ConcurrencyHelpers
//
//  Created by Josef Zoller on 29.04.22.
//

import Foundation


@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension Collection where Element: Sendable, SubSequence: Sendable {
    @inlinable
    public func parallelMap<R>(
        numberOfPartitions: Int = ProcessInfo.processInfo.processorCount,
        _ transform: @escaping @Sendable (Element) async throws -> R
    ) async rethrows -> [R] where R : Sendable {
        try await withThrowingTaskGroup(of: [R].self) { group in
            for chunk in self.splitEvenly(numberOfPartitions: numberOfPartitions) {
                group.addTask {
                    try await chunk.map(transform)
                }
            }
            
            return try await group.collected().flatMap { $0 }
        }
    }
    
    @inlinable
    public func parallelCompactMap<R>(
        numberOfPartitions: Int = ProcessInfo.processInfo.processorCount,
        _ transform: @escaping @Sendable (Element) async throws -> R?
    ) async rethrows -> [R] where R: Sendable {
        try await withThrowingTaskGroup(of: [R].self) { group in
            for chunk in self.splitEvenly(numberOfPartitions: numberOfPartitions) {
                group.addTask {
                    try await chunk.compactMap(transform)
                }
            }
            
            return try await group.collected().flatMap { $0 }
        }
    }
    
    @inlinable
    public func parallelForEach(
        numberOfPartitions: Int = ProcessInfo.processInfo.processorCount,
        _ body: @escaping @Sendable (Element) async throws -> ()
    ) async rethrows {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for chunk in self.splitEvenly(numberOfPartitions: numberOfPartitions) {
                group.addTask {
                    try await chunk.forEach(body)
                }
            }
            
            try await group.waitForAll()
        }
    }
}
