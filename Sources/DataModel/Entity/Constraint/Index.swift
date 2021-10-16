//
//  Index.swift
//  Crush
//
//  Created by 沈昱佐 on 2020/1/2.
//  Copyright © 2020 ezou. All rights reserved.
//

import CoreData

public protocol IndexProtocol {
    func createIndexDescription(
        for entityDescription: NSEntityDescription) -> NSFetchIndexDescription
}

typealias IncompleteIndexDescription = (NSEntityDescription) -> NSFetchIndexElementDescription

public struct IndexElement<T: Entity>: Hashable {
    
    let inCompleteIndexDescription: IncompleteIndexDescription
    
    let hasher: Hasher
    
    public static func == (
        lhs: IndexElement<T>,
        rhs: IndexElement<T>) -> Bool
    {
        lhs.hasher.finalize() == rhs.hasher.finalize()
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.hasher.finalize())
    }
    
    public init<S: ValuedProperty>(
        _ keyPath: KeyPath<T, S>,
        isAscending: Bool = true,
        collationType: NSFetchIndexElementType = .binary)
    {
        let name = keyPath.propertyName
        
        hasher = {
            var hasher = Hasher()
            hasher.combine(name)
            hasher.combine(isAscending)
            hasher.combine(collationType)
            return hasher
        }()
        
        inCompleteIndexDescription = {
            let property = $0.propertiesByName[name]!
            let description = NSFetchIndexElementDescription(
                property: property,
                collationType: collationType)
            description.isAscending = isAscending
            return description
        }
    }
}

public struct Index<T: Entity>: IndexProtocol, Hashable {
    
    let name: String
    
    let partialIndexPredicate: PropertyCondition?
    
    let incompletes: [IndexElement<T>]
    
    public init(
        _ name: String,
        partialIndexPredicate: PropertyCondition? = nil,
        elements: IndexElement<T>...)
    {
        self.name = name
        self.partialIndexPredicate = partialIndexPredicate
        self.incompletes = elements
    }
    
    public func createIndexDescription(
        for entityDescription: NSEntityDescription) -> NSFetchIndexDescription
    {
        let elements = incompletes
            .map(\.inCompleteIndexDescription)
            .map { $0(entityDescription) }
        let description = NSFetchIndexDescription(name: name, elements: elements)
        description.partialIndexPredicate = partialIndexPredicate
        return description
    }
}
