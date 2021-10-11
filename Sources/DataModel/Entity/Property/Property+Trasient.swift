//
//  Property+Trasient.swift
//  Crush
//
//  Created by ezou on 2019/9/26.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

// MARK: - Transient Property
public final class Temporary<Property: ValuedProperty>: ValuedProperty {
        
    var property: Property!
    
    required public init(_ name: String) {
        property = Property(name)
    }
    
    public typealias PredicateValue = Property.PredicateValue
    public typealias PropertyValue = Property.PropertyValue
    public typealias PropertyOption = Property.PropertyOption
    public typealias Nullability = Property.Nullability
    public typealias FieldConvertor = Property.FieldConvertor
    
    public var isAttribute: Bool {
        property.isAttribute
    }
    
    public var name: String {
        get {
            property.name
        }
        set {
            property.name = newValue
        }
    }
    
    public func createPropertyDescription() -> NSPropertyDescription {
        let description = property.createPropertyDescription()
        description.isTransient = true
        return description
    }
    
}

extension Temporary where Property: AttributeProtocol, PropertyValue: OptionalProtocol {
    public convenience init(_ name: String, defaultValue: PropertyValue = PropertyValue.null, options: PropertyConfiguration = []) {
        self.init(name)
        self.property.defaultValue = defaultValue
        self.property.configuration = options
    }
}

extension Temporary where Property: RelationshipProtocol {
    public convenience init<R: RelationshipProtocol>(_ name: String, inverse: KeyPath<Property.Destination, R>, options: PropertyConfiguration = [])
        where R.Destination == Property.Source, R.Source == Property.Destination {
        self.init(name)
        self.property.inverseName = Property.Destination.init()[keyPath: inverse].name
        self.property.configuration = options
    }
}

extension Temporary
where
    Property: RelationshipProtocol,
    Property.Source == Property.Destination
{
    public convenience init(_ name: String, inverse: String, options: PropertyConfiguration = []) {
        self.init(name)
        self.property.inverseName = inverse
        self.property.configuration = options
    }
}
