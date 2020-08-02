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
public class Temporary<Property: NullableProperty>: NullableProperty {
        
    var property: Property!
    
    required public init() {
        property = Property()
    }
    
    public typealias PredicateValue = Property.PredicateValue
    public typealias PropertyValue = Property.PropertyValue
    public typealias PropertyOption = Property.PropertyOption
    public typealias Nullability = Property.Nullability

    public var entityObject: NeutralEntityObject? {
        get {
            property.entityObject
        }
        set {
            property.entityObject = newValue
        }
    }
    
    public var defaultName: String {
        get {
            property.defaultName
        }
        set {
            property.defaultName = newValue
        }
    }
    
    public var propertyCacheKey: String {
        get {
            property.propertyCacheKey
        }
        set {
            property.propertyCacheKey = newValue
        }
    }
    
    public var wrappedValue: PropertyValue {
        get {
            property.wrappedValue
        }
        set {
            property.wrappedValue = newValue
        }
    }
    
    public var projectedValue: Self {
        self
    }
    
    
    public var proxy: PropertyProxy! {
        get {
            property.proxy
        }
        set {
            property.proxy = newValue
        }
    }
    
    public func emptyPropertyDescription() -> NSPropertyDescription {
        let description = property.emptyPropertyDescription()
        description.isTransient = true
        return description
    }
    
}

extension Temporary where Property: AttributeProtocol {
    public convenience init(wrappedValue: PropertyValue, options: PropertyConfiguration) {
        self.init()
        self.property.defaultValue = wrappedValue
        self.property.configuration = options
    }
}

extension Temporary where Property: RelationshipProtocol {
    public convenience init<R: RelationshipProtocol>(inverse: KeyPath<Property.Destination, R>, options: PropertyConfiguration = [])
        where R.Destination == Property.Source, R.Source == Property.Destination,
        R.Mapping == Property.InverseMapping, R.InverseMapping == Property.Mapping {
        self.init()
        self.property.inverseKeyPath = inverse
        self.property.configuration = options
    }
}
