//
//  Property+Modifier.swift
//  
//
//  Created by ezou on 2021/10/18.
//

import CoreData
import Foundation

public enum UserInfoKey {
    static let index = "Index"
    static let indexName = "IndexName"
    static let indexPredicate = "IndexPredicate"
    static let uniquenessConstraintName = "UniquenessConstraintName"
}

public class PropertyModifier<T: ValuedProperty, S>: ValuedProperty {
    public typealias Description = T.Description
    public typealias PropertyValue = T.PropertyValue
    public typealias PredicateValue = T.PredicateValue
    public typealias FieldConvertor = T.FieldConvertor

    public var name: String { property.name }
    public var isAttribute: Bool { property.isAttribute }

    public let property: T
    public let modifier: S

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

extension PropertyModifier: AttributeProtocol where T: AttributeProtocol { }

public protocol TransientProperty: ValuedProperty { }

extension PropertyModifier: TransientProperty where T: TransientProperty { }

extension PropertyModifier: ConcreteAttriuteProcotol where T: ConcreteAttriuteProcotol { }

// MARK: Property modifier

@propertyWrapper
public class Optional<T: ValuedProperty>: PropertyModifier<T, Bool> {
    @inlinable public var wrappedValue: T { property }

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
    @inlinable public var wrappedValue: T { property }

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
    @inlinable public var wrappedValue: T { property }

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
    @inlinable public var wrappedValue: T { property }

    public init(wrappedValue: T) {
        super.init(wrappedValue: wrappedValue, true)
    }

    public override func createDescription() -> Description {
        let description = super.createDescription()
        description.isIndexedBySpotlight = modifier
        return description
    }
}

@propertyWrapper
public class Indexed<T: ValuedProperty>: PropertyModifier<T, String> {
    @inlinable public var wrappedValue: T { property }

    public let collationType: NSFetchIndexElementType
    public let predicate: NSPredicate?

    public init(
        wrappedValue: T,
        _ modifier: String,
        collationType: NSFetchIndexElementType = .binary,
        predicate: NSPredicate? = nil)
    {
        self.collationType = collationType
        self.predicate = predicate
        super.init(wrappedValue: wrappedValue, modifier)
    }

    public override func createDescription() -> Description {
        let description = super.createDescription()
        var userInfo = description.userInfo ?? [:]
        userInfo[UserInfoKey.indexName] = modifier
        userInfo[UserInfoKey.index] = NSFetchIndexElementDescription(
            property: description, collationType: collationType)
        description.userInfo = userInfo
        return description
    }
}

@propertyWrapper
public class Unique<T: ValuedProperty>: PropertyModifier<T, String?> {
    @inlinable public var wrappedValue: T { property }

    public override init(wrappedValue: T, _ modifier: String? = nil) {
        super.init(wrappedValue: wrappedValue, modifier)
    }

    public override func createDescription() -> Description {
        let description = super.createDescription()
        var userInfo = description.userInfo ?? [:]
        userInfo[UserInfoKey.uniquenessConstraintName] = modifier ?? description.name
        description.userInfo = userInfo
        return description
    }
}

// MARK: Attribute modifier

@propertyWrapper
public class Default<T: ConcreteAttriuteProcotol>:
    PropertyModifier<T, T.PropertyValue>
{
    @inlinable public var wrappedValue: T { property }

    public override func createDescription() -> Description {
        let description = super.createDescription()
        description.defaultValue = T.FieldConvertor.convert(value: modifier)
        return description
    }
}

@propertyWrapper
public class ExternalBinaryDataStorage<T: AttributeProtocol>: PropertyModifier<T, Bool> {
    @inlinable public var wrappedValue: T { property }

    public init(wrappedValue: T) {
        super.init(wrappedValue: wrappedValue, true)
    }

    public override func createDescription() -> Description {
        let description = super.createDescription()
        description.allowsExternalBinaryDataStorage = modifier
        return description
    }
}

@propertyWrapper
public class Validation<T: AttributeProtocol>: PropertyModifier<T, PropertyCondition> {
    @inlinable public var wrappedValue: T { property }
    public let warning: String

    public init(
        wrappedValue: T, _ modifier: PropertyCondition, warning: String = "")
    {
        self.warning = warning
        super.init(wrappedValue: wrappedValue, modifier)
    }

    public override func createDescription() -> Description {
        let description = super.createDescription()
        var warnings = description.validationWarnings as? [String] ?? []
        var predicates = description.validationPredicates
        warnings.append(warning)
        predicates.append(modifier)
        description.setValidationPredicates(predicates, withValidationWarnings: warnings)
        return description
    }
}

@available(iOS 13.0, watchOS 6.0, macOS 10.15, *)
@propertyWrapper
public class PreservesValueInHistoryOnDeletion<T: AttributeProtocol>: PropertyModifier<T, Bool> {
    @inlinable public var wrappedValue: T { property }

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
public class Inverse<T: RelationshipProtocol, S: RelationshipProtocol>:
    PropertyModifier<T, KeyPath<T.Destination, S>>
{
    @inlinable public var wrappedValue: T { property }

    public override func createDescription() -> NSRelationshipDescription {
        let description = super.createDescription()
        let inverseName = self.modifier.propertyName

        Caches.entity.getAndWait(Destination.entityCacheKey) {
            guard let inverseRelationship = $0.relationshipsByName[inverseName] else {
                return assertionFailure("inverse relationship not found")
            }
            description.inverseRelationship = inverseRelationship
            guard self.isUniDirectional == false else { return }
            inverseRelationship.inverseRelationship = description
        }

        return description
    }
}

@propertyWrapper
public final class MaxCount<T: RelationshipProtocol>: PropertyModifier<T, Int>
where T.Mapping: ToManyRelationMappingProtocol {
    @inlinable public var wrappedValue: T { property }

    public override func createDescription() -> Description {
        let description = super.createDescription()
        description.maxCount = modifier
        return description
    }
}

@propertyWrapper
public class MinCount<T: RelationshipProtocol>: PropertyModifier<T, Int>
where T.Mapping: ToManyRelationMappingProtocol {
    @inlinable public var wrappedValue: T { property }

    public override func createDescription() -> Description {
        let description = super.createDescription()
        description.minCount = modifier
        return description
    }
}

@propertyWrapper
public class DeleteRule<T: RelationshipProtocol>: PropertyModifier<T, NSDeleteRule> {
    @inlinable public var wrappedValue: T { property }

    public override func createDescription() -> Description {
        let description = super.createDescription()
        description.deleteRule = modifier
        return description
    }
}

@propertyWrapper
public class UnidirectionalInverse<T: RelationshipProtocol>: PropertyModifier<T, Bool> {
    @inlinable public var wrappedValue: T { property }

    public init(wrappedValue: T) {
        super.init(wrappedValue: wrappedValue, true)
        self.isUniDirectional = true
    }
}
