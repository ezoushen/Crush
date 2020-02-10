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
    case inverseRelationshipType
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

public protocol MutablePropertyOptionProtocol: Hashable, PropertyOptionProtocol {
    associatedtype Description: NSPropertyDescription
}

extension MutablePropertyOptionProtocol {
    public var hashValue: Int {
        return String(reflecting: self).hashValue
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(String(reflecting: self))
    }
}

extension Equatable where Self: MutablePropertyOptionProtocol {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}

public enum PropertyOption {
    case name(String)
    case mapping(RootTracableKeyPathProtocol)
    case userInfo([AnyHashable: Any])
    case isIndexedBySpotlight(Bool)
    case renamingIdentifier(String)
    case validationPredicatesWithWarnings([(NSPredicate, String)])
}

extension PropertyOption: MutablePropertyOptionProtocol {

    public typealias Description = NSPropertyDescription
    
    public func updatePropertyDescription<D: NSPropertyDescription>(_ description: D) {
        switch self {
        case .userInfo(let userInfo): description.userInfo = userInfo.merging(description.userInfo ?? [:], uniquingKeysWith: { $1 })
        case .isIndexedBySpotlight(let flag): description.isIndexedBySpotlight = flag
        case .renamingIdentifier(let identifier): description.renamingIdentifier = identifier
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
    var name: String? { get set }
    var isOptional: Bool { get }
    var isTransient: Bool { get }
    var userInfo: [AnyHashable: Any]? { get set }
    var isIndexedBySpotlight: Bool { get }
    var renamingIdentifier: String? { get set }
    var versionHashModifier: String? { get set }
    var validationPredicates: [NSPredicate]? { get }
    var validationWarnings: [String]? { get }
    var description: NSPropertyDescription! { get set }
    var valueMappingProxy: ReadOnlyValueMapperProtocol? { get set }
    var value: Any { get }
    
    func createDescription<T: NSPropertyDescription>() -> T!
}

extension PropertyProtocol {
    public var isOptional: Bool { true }
    public var isTransient: Bool { false }
    public var userInfo: [AnyHashable: Any]? { nil }
    public var isIndexedBySpotlight: Bool { false }
    public var validationPredicates: [NSPredicate]? { nil }
    public var validationWarnings: [String]? { nil }
}

// MARK: - Entity Property

public protocol MutablePropertyProtocol: PropertyProtocol {
    associatedtype Option: MutablePropertyOptionProtocol
    associatedtype PropertyValue
    associatedtype EntityType
        
    var wrappedValue: PropertyValue { get set }
    init(wrappedValue: PropertyValue)
    func updateProperty()
}

extension MutablePropertyProtocol {
    public var value: Any {
        return wrappedValue
    }
}

public protocol NullablePropertyProtocol: MutablePropertyProtocol {
    associatedtype OptionalType: OptionalTypeProtocol
}
