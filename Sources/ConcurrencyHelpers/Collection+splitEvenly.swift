//
//  Collection+splitEvenly.swift
//  ConcurrencyHelpers
//
//  Created by Josef Zoller on 29.04.22.
//

extension Collection {
    @inlinable
    public func splitEvenly(numberOfPartitions: Int) -> [SubSequence] {
        var currentIndex = self.startIndex
        
        if numberOfPartitions >= self.count {
            return (0..<numberOfPartitions).map { _ in
                let startIndex = currentIndex
                
                if currentIndex < self.endIndex {
                    self.formIndex(after: &currentIndex)
                }
                
                return self[startIndex..<currentIndex]
            }
        }
        
        let partitionCount = self.count / numberOfPartitions
        let remainder = self.count % numberOfPartitions
        
        return (0..<numberOfPartitions).map { i in
            let startIndex = currentIndex
            
            currentIndex = self.index(currentIndex, offsetBy: partitionCount + (i < remainder ? 1 : 0))
            
            return self[startIndex..<currentIndex]
        }
    }
}
