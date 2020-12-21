//
//  Index.swift
//  Crush
//
//  Created by 沈昱佐 on 2020/1/2.
//  Copyright © 2020 ezou. All rights reserved.
//

import CoreData

public protocol ConstraintSet: NSObject { }

protocol IndexProtocol {
    func fetchIndexDescription<R: Entity>(name: String, in object: R) -> NSFetchIndexDescription
}

protocol TargetedIndexProtocol: IndexProtocol {
    associatedtype Target: RuntimeObject

    var indexes: [IndexElement<Target>] { get }
}

public protocol IndexElementProtocol {
    var isAscending: Bool { get }
    var keyPath: AnyKeyPath? { get set }
    var type: NSFetchIndexElementType { get set }
    func fetchIndexElementDescription(property: NSPropertyDescription) -> NSFetchIndexElementDescription
}

extension IndexElementProtocol {
    public func fetchIndexElementDescription(property: NSPropertyDescription) -> NSFetchIndexElementDescription {
        let description = NSFetchIndexElementDescription(property: property, collationType: type)
        description.isAscending = isAscending
        
        return description
    }
}

public class IndexElement<Target: RuntimeObject>: IndexElementProtocol {
    public var isAscending: Bool {
        fatalError("Do not use abstract directly")
    }
    
    public var keyPath: AnyKeyPath?
    
    public var type: NSFetchIndexElementType
    
    public init<Value: NullableProperty>(_ keyPath: KeyPath<Target, Value>, type: NSFetchIndexElementType = .binary) {
        self.keyPath = keyPath
        self.type = type
    }
}

public class AscendingIndex<Target: RuntimeObject>: IndexElement<Target> {
    public override var isAscending: Bool { true }
}

public class DescendingIndex<Target: RuntimeObject>: IndexElement<Target> {
    public override var isAscending: Bool { false }
}

@propertyWrapper
public struct CompositeFetchIndex<Target: RuntimeObject>: TargetedIndexProtocol {
    private let _indexes: [IndexElement<Target>]
    
    public var indexes: [IndexElement<Target>] {
        return _indexes
    
    }
    public init(wrappedValue: [IndexElement<Target>]) {
        self._indexes = wrappedValue
    }

    public var wrappedValue: [IndexElement<Target>] {
        _indexes
    }
}

@propertyWrapper
public struct FetchIndex<Target: RuntimeObject>: TargetedIndexProtocol {
    
    private let _index: IndexElement<Target>
    
    var indexes: [IndexElement<Target>] {
        return [_index]
    }
    
    public var wrappedValue: IndexElement<Target> {
        _index
    }
    
    public init(wrappedValue: IndexElement<Target>) {
        self._index = wrappedValue
    }
}

extension TargetedIndexProtocol {
    func fetchIndexDescription<R: Entity>(name: String, in object: R) -> NSFetchIndexDescription {
        let indcies = indexes.compactMap{ index -> (IndexElementProtocol, AnyKeyPath)? in
            guard let keyPath = index.keyPath else { return nil }
            return (index, keyPath)
        }.compactMap{ (index, keyPath) -> (IndexElementProtocol, NSPropertyDescription)? in
            let coordinator = CacheCoordinator.shared
            guard let property = object[keyPath: keyPath] as? PropertyProtocol,
                  let description = coordinator.get(R.createPropertyCacheKey(name: property.name), in: CacheType.property) else { return nil }
            return (index, description)
        }.map{ (index, description) -> NSFetchIndexElementDescription in
            return index.fetchIndexElementDescription(property: description)
        }
        return NSFetchIndexDescription(name: String(name.dropFirst()), elements: indcies)
    }
}
