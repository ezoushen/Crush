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

public protocol PropertyConfigurable {
    func updatePropertyDescription<D: NSPropertyDescription>(_ description: D)
}

public protocol MutablePropertyConfigurable: PropertyConfigurable {
    associatedtype Description: NSPropertyDescription
}

public enum PropertyOption {
    case name(String)
    case mapping(RootTracableKeyPathProtocol)
    case isIndexedBySpotlight(Bool)
    case validationPredicatesWithWarnings([(NSPredicate, String)])
}

public struct PropertyConfiguration {
    let options: [PropertyConfigurable]
}

extension PropertyConfiguration: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: PropertyConfigurable...) {
        options = elements
    }
    
    func configure(description: NSPropertyDescription) {
        options.forEach{ $0.updatePropertyDescription(description) }
    }
}

extension PropertyOption: MutablePropertyConfigurable {

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

public protocol PropertyProtocol: AnyObject {
    var defaultName: String { get set }
    var proxy: PropertyProxy! { get set }
    var propertyCacheKey: String { get set }
    var anyHashable: AnyHashable { get }
    var entityObject: NeutralEntityObject? { get set }
    var value: Any { get }
    
    func emptyPropertyDescription() -> NSPropertyDescription
}

extension PropertyProtocol {
    public var isTransient: Bool { false }
    
    var description: NSPropertyDescription {
        CacheCoordinator.shared.get(propertyCacheKey, in: CacheType.property)!
    }
}

// MARK: - Entity Property

public protocol MutableProperty: PropertyProtocol {
    associatedtype PropertyOption: MutablePropertyConfigurable
    associatedtype PropertyValue: Hashable
    associatedtype PredicateValue
    
    var wrappedValue: PropertyValue { get set }
    init()
}

extension MutableProperty {
    public var value: Any {
        return wrappedValue
    }
    
    public var anyHashable: AnyHashable {
        AnyHashable(wrappedValue)
    }
}

public protocol NullableProperty: MutableProperty {
    associatedtype Nullability: Crush.Nullability
}