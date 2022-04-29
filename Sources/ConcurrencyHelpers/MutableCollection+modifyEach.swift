//
//  MutableCollection+modifyEach.swift
//  ConcurrencyHelpers
//
//  Created by Josef Zoller on 29.04.22.
//

import Foundation


extension MutableCollection {
    @inlinable
    public mutating func modifyEach(
        _ body: (inout Element) throws -> ()
    ) rethrows {
        var index = self.startIndex
        while index != self.endIndex {
            try body(&self[index])
            self.formIndex(after: &index)
        }
    }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension MutableCollection {
    @inlinable
    public mutating func modifyEach(
        _ body: (inout Element) async throws -> ()
    ) async rethrows {
        var index = self.startIndex
        while index != self.endIndex {
            try await body(&self[index])
            self.formIndex(after: &index)
        }
    }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension MutableCollection where Self: RangeReplaceableCollection, Element: Sendable, SubSequence: Sendable {
    @inlinable
    public mutating func parallelModifyEach(
        numberOfPartitions: Int = ProcessInfo.processInfo.processorCount,
        _ body: @escaping @Sendable (inout Element) async throws -> ()
    ) async rethrows {
        try await withThrowingTaskGroup(of: SubSequence.self) { group in
            for chunk in self.splitEvenly(numberOfPartitions: numberOfPartitions) {
                group.addTask {
                    var chunk = chunk
                    try await chunk.modifyEach(body)
                    return chunk
                }
            }
            
            for try await modifiedChunk in group {
                self[modifiedChunk.startIndex..<modifiedChunk.endIndex] = modifiedChunk
            }
        }
    }
}
