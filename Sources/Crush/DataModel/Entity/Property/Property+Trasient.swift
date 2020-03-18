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

    public var defaultName: String {
        get {
            guard case let .transient(attribute) = self else {
                fatalError("Trasient type mismatch")
            }
            return attribute.defaultName
        }
        set {
            guard case var .transient(attribute) = self else {
                fatalError("Trasient type mismatch")
            }
            attribute.defaultName = newValue
        }
    }
    
    public var propertyCacheKey: String {
        get {
            guard case let .transient(attribute) = self else {
                fatalError("Trasient type mismatch")
            }
            return attribute.propertyCacheKey
        }
        set {
            guard case var .transient(attribute) = self else {
                fatalError("Trasient type mismatch")
            }
            attribute.propertyCacheKey = newValue
        }
    }
    
    public var wrappedValue: PropertyValue? {
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
    
    
    public var proxy: PropertyProxy! {
        get {
            guard case let .transient(attribute) = self else { return nil }
            return attribute.proxy
        }
        set {
            guard case var .transient(attribute) = self else { return }
            attribute.proxy = newValue
        }
    }
    
    init(_ some: Property) {
        self = .transient(some)
    }
    
    public init(wrappedValue: PropertyValue?) {
        self = .transient(Property.init(wrappedValue: wrappedValue))
    }
    
    public func emptyPropertyDescription() -> NSPropertyDescription {
        guard case let .transient(attribute) = self else {
            fatalError("Trasient type mismatch")
        }
        let description = attribute.emptyPropertyDescription()
        description.isTransient = true
        return description
    }
    
}

extension Temporary where Property: AttributeProtocol {
    public init(wrappedValue: PropertyValue, options: PropertyOptionProtocol...) {
        self.init(Property.init(wrappedValue: wrappedValue, options: options))
    }
}

extension Temporary where Property: RelationshipProtocol {
    public init<R: RelationshipProtocol>(inverse: KeyPath<Property.DestinationEntity, R>, options: PropertyOptionProtocol...) where R.DestinationEntity == Property.SourceEntity, R.SourceEntity == Property.DestinationEntity, R.RelationshipType == Property.InverseType, R.InverseType == Property.RelationshipType {
        self.init(Property.init(inverse: inverse, options: options))
    }
}
