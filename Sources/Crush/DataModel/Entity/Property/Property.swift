//
//  Property.swift
//  Crush
//
//  Created by 沈昱佐 on 2019/9/21.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

// MARK: - UserInfoKey

enum UserInfoKey: Hashable {
    case relationshipDestination
    case inverseRelationship
    case inverseUnidirectional
    case propertyMappingKeyPath
    case propertyMappingSource
    case propertyMappingDestination
    case propertyMappingRoot
    case propertyMappingValue
    case version
}

// MARK: - EntityOption

public protocol PropertyOptionProtocol {
    func updatePropertyDescription<D: NSPropertyDescription>(_ description: D)
}

public protocol MutablePropertyOptionProtocol: PropertyOptionProtocol {
    associatedtype Description: NSPropertyDescription
}

public enum PropertyOption {
    case name(String)
    case mapping(RootTracableKeyPathProtocol)
    case isIndexedBySpotlight(Bool)
    case validationPredicatesWithWarnings([(NSPredicate, String)])
}

extension PropertyOption: MutablePropertyOptionProtocol {

    public typealias Description = NSPropertyDescription
    
    public func updatePropertyDescription<D: NSPropertyDescription>(_ description: D) {
        switch self {
        case .isIndexedBySpotlight(let flag): description.isIndexedBySpotlight = flag
        case .validationPredicatesWithWarnings(let tuples):
            description.setValidationPredicates(tuples.map{$0.0}, withValidationWarnings: tuples.map{$0.1})
        case .name(let name): description.name = name
        case .mapping(let keyPath):
            description.userInfo = (description.userInfo ?? [:])
            description.userInfo?[UserInfoKey.propertyMappingKeyPath] = keyPath
        }
    }
}

public protocol PropertyProtocol {
    var defaultName: String { get set }
    var proxy: PropertyProxy! { get set }
    var value: Any { get }
    var propertyCacheKey: String { get set }
    
    func emptyPropertyDescription() -> NSPropertyDescription
}

extension PropertyProtocol {
    public var isTransient: Bool { false }
    
    var description: NSPropertyDescription {
        DescriptionCacheCoordinator.shared.getDescription(propertyCacheKey, type: PropertyCacheType.self)!
    }
}

// MARK: - Entity Property

public protocol MutablePropertyProtocol: PropertyProtocol {
    associatedtype Option: MutablePropertyOptionProtocol
    associatedtype PropertyValue
    
    var wrappedValue: PropertyValue? { get set }
    init(wrappedValue: PropertyValue?)
}

extension MutablePropertyProtocol {
    public var value: Any {
        return wrappedValue
    }
}

public protocol NullablePropertyProtocol: MutablePropertyProtocol {
    associatedtype OptionalType: OptionalTypeProtocol
}
