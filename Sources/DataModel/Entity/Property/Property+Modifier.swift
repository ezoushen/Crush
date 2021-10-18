//
//  Property+Modifier.swift
//  
//
//  Created by ezou on 2021/10/18.
//

import CoreData
import Foundation

public class PropertyModifier<T: ValuedProperty, S>: ValuedProperty {
    public typealias Description = T.Description
    public typealias PropertyValue = T.PropertyValue
    public typealias PredicateValue = T.PredicateValue
    public typealias FieldConvertor = T.FieldConvertor

    public var name: String { property.name }
    public var isAttribute: Bool { property.isAttribute }

    let property: T
    let modifier: S

    public init(wrappedValue: T, _ modifier: S) {
        self.property = wrappedValue
        self.modifier = modifier
    }

    public func createDescription() -> Description {
        property.createDescription()
    }
}

extension PropertyModifier: RelationshipProtocol where T: RelationshipProtocol {
    public typealias Destination = T.Destination
    public typealias Mapping = T.Mapping

    public var isUniDirectional: Bool {
        get { property.isUniDirectional }
        set { property.isUniDirectional = newValue }
    }
}

extension PropertyModifier: AttributeProtocol where T: AttributeProtocol {
    public var defaultValue: T.PropertyValue {
        property.defaultValue
    }
}

public protocol TransientProperty: ValuedProperty { }

// MARK: Property modifier

@propertyWrapper
public class Optional<T: ValuedProperty>: PropertyModifier<T, Bool> {
    public var wrappedValue: T { property }

    public init(wrappedValue: T) {
        super.init(wrappedValue: wrappedValue, true)
    }

    public override func createDescription() -> PropertyModifier<T, Bool>.Description {
        let description = super.createDescription()
        description.isOptional = modifier
        return description
    }
}

@propertyWrapper
public class Required<T: ValuedProperty>: PropertyModifier<T, Bool> {
    public var wrappedValue: T { property }

    public init(wrappedValue: T) {
        super.init(wrappedValue: wrappedValue, false)
    }

    public override func createDescription() -> PropertyModifier<T, Bool>.Description {
        let description = super.createDescription()
        description.isOptional = modifier
        return description
    }
}

@propertyWrapper
public class Transient<T: ValuedProperty & TransientProperty>: PropertyModifier<T, Bool> {
    public var wrappedValue: T { property }

    public init(wrappedValue: T) {
        super.init(wrappedValue: wrappedValue, true)
    }

    public override func createDescription() -> PropertyModifier<T, Bool>.Description {
        let description = super.createDescription()
        description.isTransient = modifier
        return description
    }
}

/// This option will be ignored while the property is transient
@propertyWrapper
public class IndexedBySpotlight<T: ValuedProperty>: PropertyModifier<T, Bool> {
    public var wrappedValue: T { property }

    public init(wrappedValue: T) {
        super.init(wrappedValue: wrappedValue, true)
    }

    public override func createDescription() -> Description {
        let description = super.createDescription()
        description.isIndexedBySpotlight = modifier
        return description
    }
}

// MARK: Attribute modifier

@propertyWrapper
public class ExternalBinaryDataStorage<T: AttributeProtocol>: PropertyModifier<T, Bool> {
    public var wrappedValue: T { property }

    public init(wrappedValue: T) {
        super.init(wrappedValue: wrappedValue, true)
    }

    public override func createDescription() -> Description {
        let description = super.createDescription()
        description.allowsExternalBinaryDataStorage = modifier
        return description
    }
}

@available(iOS 13.0, watchOS 6.0, macOS 10.15, *)
@propertyWrapper
public class PreservesValueInHistoryOnDeletion<T: AttributeProtocol>: PropertyModifier<T, Bool> {
    public var wrappedValue: T { property }

    public init(wrappedValue: T) {
        super.init(wrappedValue: wrappedValue, true)
    }

    public override func createDescription() -> Description {
        let description = super.createDescription()
        description.preservesValueInHistoryOnDeletion = modifier
        return description
    }
}

// MARK: Relationship modifier

@propertyWrapper
public final class MaxCount<T: RelationshipProtocol>: PropertyModifier<T, Int>
where T.Mapping: ToManyRelationMappingProtocol {
    public var wrappedValue: T { property }

    public override func createDescription() -> Description {
        let description = super.createDescription()
        description.maxCount = modifier
        return description
    }
}

@propertyWrapper
public class MinCount<T: RelationshipProtocol>: PropertyModifier<T, Int>
where T.Mapping: ToManyRelationMappingProtocol {
    public var wrappedValue: T { property }

    public override func createDescription() -> Description {
        let description = super.createDescription()
        description.minCount = modifier
        return description
    }
}

@propertyWrapper
public class DeleteRule<T: RelationshipProtocol>: PropertyModifier<T, NSDeleteRule> {
    public var wrappedValue: T { property }

    public override func createDescription() -> Description {
        let description = super.createDescription()
        description.deleteRule = modifier
        return description
    }
}

@propertyWrapper
public class UnidirectionalInverse<T: RelationshipProtocol>: PropertyModifier<T, Bool> {
    public var wrappedValue: T { property }

    public init(wrappedValue: T) {
        super.init(wrappedValue: wrappedValue, true)
        self.isUniDirectional = true
    }
}
