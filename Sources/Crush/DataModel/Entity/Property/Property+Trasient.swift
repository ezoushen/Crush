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
public enum Temporary<Property: NullableProperty>: NullableProperty {
    
    case transient(Property)
    
    public typealias PredicateValue = Property.PredicateValue
    public typealias PropertyValue = Property.PropertyValue
    public typealias PropertyOption = Property.PropertyOption
    public typealias Nullability = Property.Nullability

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
    
    public init(wrappedValue: PropertyValue) {
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
    public init(wrappedValue: PropertyValue, options: PropertyConfiguration) {
        self.init(Property.init(wrappedValue: wrappedValue, options: options))
    }
}

extension Temporary where Property: RelationshipProtocol {
    public init<R: RelationshipProtocol>(inverse: KeyPath<Property.Destination, R>, options: PropertyConfiguration)
        where R.Destination == Property.Source, R.Source == Property.Destination,
        R.Mapping == Property.InverseMapping, R.InverseMapping == Property.Mapping {
        self.init(Property.init(wrappedValue: nil, inverse: inverse, options: options))
    }
}
