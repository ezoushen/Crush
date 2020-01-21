//
//  Property+Trasient.swift
//  Crush
//
//  Created by ezou on 2019/9/26.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

// MARK: - Transient Property
@propertyWrapper
public enum Temporary<Property: NullablePropertyProtocol>: NullablePropertyProtocol {
    
    
    case transient(Property)
    
    public typealias PropertyValue = Property.PropertyValue
    public typealias Option = Property.Option
    public typealias OptionalType = Property.OptionalType
    public typealias EntityType = Property.EntityType

    public var wrappedValue: PropertyValue {
        get {
            guard case let .transient(attribute) = self else {
                fatalError("Trasient type mismatch")
            }
            return attribute.wrappedValue
        }
        set {
            guard case var .transient(attribute) = self else {
                fatalError("Trasient type mismatch")
            }
            attribute.wrappedValue = newValue
        }
    }
    
    public var projectedValue: Self {
        self
    }
    
    
    public var valueMappingProxy: ReadOnlyValueMapperProtocol? {
        get {
            guard case let .transient(attribute) = self else { return nil }
            return attribute.valueMappingProxy
        }
        set {
            guard case var .transient(attribute) = self else { return }
            attribute.valueMappingProxy = newValue
        }
    }

    public var name: String? {
        get {
            guard case let .transient(attribute) = self else { return nil }
            return attribute.name
        }
        set {
            preconditionFailure("do not set the name directly")
        }
    }
    
    public var renamingIdentifier: String? {
        get {
            guard case let .transient(attribute) = self else { return nil }
            return attribute.renamingIdentifier
        }
        set {
            preconditionFailure("do not set the name directly")
        }
    }
    
    public var versionHashModifier: String? {
        get {
            guard case let .transient(attribute) = self else { return nil }
            return attribute.versionHashModifier
        }
        set {
            preconditionFailure("do not set the name directly")
        }
    }
    
    public var description: NSPropertyDescription! {
        get {
            guard case let .transient(attribute) = self else { return nil }
            return attribute.description
        }
        set {
            guard case var .transient(attribute) = self else { return }
            attribute.description = newValue
        }
    }
    
    public var userInfo: [AnyHashable : Any]? {
        get {
            guard case let .transient(attribute) = self else { return nil }
            return attribute.userInfo
        }
        set {
            guard case var .transient(attribute) = self else { return }
            attribute.userInfo = newValue
        }
    }

    
    public func createDescription<T: NSPropertyDescription>() -> T! {
        guard case let .transient(attribute) = self else { return nil }
        return attribute.createDescription()
    }
    
    init(_ some: Property) {
        self = .transient(some)
    }
    
    public init(wrappedValue: PropertyValue) {
        self = .transient(Property.init(wrappedValue: wrappedValue))
    }
    
    public func updateProperty() {
        guard case let .transient(attribute) = self else { return }
        attribute.updateProperty()
    }
}

extension Temporary where Property: AttributeProtocol {
    public init(wrappedValue: PropertyValue, options: PropertyOptionProtocol...) {
        self.init(Property.init(wrappedValue: wrappedValue, options: options))
    }
}

extension Temporary where Property: RelationshipProtocol {
    public init<R: RelationshipProtocol>(_ name: String? = nil, inverse: KeyPath<Property.DestinationEntity, R>, options: PropertyOptionProtocol...) where R.DestinationEntity == Property.SourceEntity, R.SourceEntity == Property.DestinationEntity, R.RelationshipType == Property.InverseType, R.InverseType == Property.RelationshipType {
        self.init(Property.init(name, inverse: inverse, options: options))
    }
}
