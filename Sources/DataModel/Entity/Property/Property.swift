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
    case mapping(AnyKeyPath)
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
        case .mapping(let keyPath):
            description.userInfo = (description.userInfo ?? [:])
            description.userInfo?[UserInfoKey.propertyMappingKeyPath] = keyPath
        }
    }
}

public protocol PropertyProtocol: AnyObject {
    var name: String { get set }    
    func emptyPropertyDescription() -> NSPropertyDescription
}

extension PropertyProtocol {
    public var isTransient: Bool { false }
}

// MARK: - Entity Property

public protocol MutableProperty: PropertyProtocol {
    associatedtype PropertyOption: MutablePropertyConfigurable
    associatedtype PropertyValue
    associatedtype PredicateValue
    
    init(_ name: String)
}

public protocol NullableProperty: MutableProperty {
    associatedtype Nullability: Crush.Nullability
    associatedtype FieldConvertor: FieldConvertible
    where FieldConvertor.RuntimeObjectValue == PropertyValue
    
    var isAttribute: Bool { get }
}
