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
public final class Temporary<Property: NullableProperty>: NullableProperty {
        
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
    
    @available(*, unavailable)
    public var wrappedValue: PropertyValue {
      get { fatalError("only works on instance properties of classes") }
      set { fatalError("only works on instance properties of classes") }
    }
    
    public static subscript<EnclosingSelf: HashableEntity>(
        _enclosingInstance observed: EnclosingSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, PropertyValue>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Temporary<Property>>
    ) -> PropertyValue {
        get {
            let property = observed[keyPath: storageKeyPath]
            return FieldConvertor.convert(value: observed.getValue(key: property.name))
        }
        set {
            let property = observed[keyPath: storageKeyPath]
            observed.setValue(
                FieldConvertor.convert(value: newValue, with: observed.getValue(key: property.name)),
                key: property.name
            )
        }
    }
    
    public var projectedValue: Temporary<Property> {
        self
    }
    
    public func emptyPropertyDescription() -> NSPropertyDescription {
        let description = property.emptyPropertyDescription()
        description.isTransient = true
        return description
    }
    
}

extension Temporary where Property: AttributeProtocol {
    public convenience init(wrappedValue: PropertyValue, _ name: String, options: PropertyConfiguration) {
        self.init(name)
        self.property.defaultValue = wrappedValue
        self.property.configuration = options
    }
}

extension Temporary where Property: RelationshipProtocol {
    public convenience init<R: RelationshipProtocol>(_ name: String, inverse: KeyPath<Property.Destination, R>, options: PropertyConfiguration = [])
        where R.Destination == Property.Source, R.Source == Property.Destination,
        R.Mapping == Property.InverseMapping, R.InverseMapping == Property.Mapping {
        self.init(name)
        self.property.inverseKeyPath = inverse
        self.property.configuration = options
    }
}
