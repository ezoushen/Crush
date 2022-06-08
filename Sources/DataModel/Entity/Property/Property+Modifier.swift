//
//  Property+Modifier.swift
//  
//
//  Created by ezou on 2021/10/18.
//

import CoreData
import Foundation

open class PropertyModifier<T: WritableValuedProperty, S>: WritableValuedProperty {
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

    open func createDescription() -> Description {
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
public class Optional<T: WritableValuedProperty>: PropertyModifier<T, Bool> {
    @inlinable public var wrappedValue: T {
        get { property }
        set { /* dummy */ }
    }

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
public class Required<T: WritableValuedProperty>: PropertyModifier<T, Bool> {
    @inlinable public var wrappedValue: T {
        get { property }
        set { /* dummy */ }
    }

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
public class Transient<T: WritableValuedProperty & TransientProperty>: PropertyModifier<T, Bool> {
    @inlinable public var wrappedValue: T {
        get { property }
        set { /* dummy */ }
    }

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
public class IndexedBySpotlight<T: WritableValuedProperty>: PropertyModifier<T, Bool> {
    @inlinable public var wrappedValue: T {
        get { property }
        set { /* dummy */ }
    }

    public init(wrappedValue: T) {
        super.init(wrappedValue: wrappedValue, true)
    }

    public override func createDescription() -> Description {
        let description = super.createDescription()
        description.isIndexedBySpotlight = modifier
        return description
    }
}

public protocol IndexProtocol {
    var predicate: NSPredicate? { get }
    var collationType: NSFetchIndexElementType { get }
    var indexName: String? { get }
    var targetEntityName: String? { get }

    func createFetchIndexElementDescription(
        from description: NSPropertyDescription) -> NSFetchIndexElementDescription
}

@propertyWrapper
public class Indexed<T: WritableValuedProperty>: PropertyModifier<T, String?>, IndexProtocol {
    @inlinable public var wrappedValue: T {
        get { property }
        set { /* dummy */ }
    }
    @inlinable public var indexName: String? { modifier }

    public let collationType: NSFetchIndexElementType
    public let predicate: NSPredicate?
    public let targetEntityName: String?

    public init<Entity: Crush.Entity>(
        wrappedValue: T,
        _ modifier: String? = nil,
        target: Entity.Type? = nil,
        collationType: NSFetchIndexElementType = .binary,
        predicate: NSPredicate? = nil)
    {
        self.collationType = collationType
        self.predicate = predicate
        self.targetEntityName = target?.fetchKey
        super.init(wrappedValue: wrappedValue, modifier)
    }

    public convenience init<Entity: Crush.Entity>(
        wrappedValue: T,
        _ modifier: String? = nil,
        target: Entity.Type? = nil,
        collationType: NSFetchIndexElementType = .binary,
        predicate: String)
    {
        self.init(
            wrappedValue: wrappedValue,
            modifier,
            target: target,
            collationType: collationType,
            predicate: NSPredicate(format: predicate))
    }

    public override func createDescription() -> Description {
        let description = super.createDescription()
        var userInfo = description.userInfo ?? [:]
        var indexes = userInfo[UserInfoKey.indexes] as? [IndexProtocol] ?? []
        indexes.append(self)
        userInfo[UserInfoKey.indexes] = indexes
        description.userInfo = userInfo
        return description
    }

    public func createFetchIndexElementDescription(
        from description: NSPropertyDescription) -> NSFetchIndexElementDescription
    {
        NSFetchIndexElementDescription(
            property: description, collationType: collationType)
    }
}

@propertyWrapper
public class Unique<T: WritableValuedProperty>: PropertyModifier<T, String?> {
    @inlinable public var wrappedValue: T {
        get { property }
        set { /* dummy */ }
    }

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
    @inlinable public var wrappedValue: T {
        get { property }
        set { /* dummy */ }
    }

    public override func createDescription() -> Description {
        let description = super.createDescription()
        description.defaultValue = T.FieldConvertor.convert(value: modifier)
        return description
    }
}

@propertyWrapper
public class ExternalBinaryDataStorage<T: AttributeProtocol>: PropertyModifier<T, Bool> {
    @inlinable public var wrappedValue: T {
        get { property }
        set { /* dummy */ }
    }

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
public class Validation<T: AttributeProtocol>: PropertyModifier<T, PropertyCondition<T.FieldConvertor>> {
    @inlinable public var wrappedValue: T {
        get { property }
        set { /* dummy */ }
    }
    public let warning: String

    public init(
        wrappedValue: T, _ modifier: PropertyCondition<T.FieldConvertor>, warning: String = "")
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

@available(iOS 13.0, watchOS 6.0, macOS 10.15, tvOS 13.0, *)
@propertyWrapper
public class PreservesValueInHistoryOnDeletion<T: AttributeProtocol>: PropertyModifier<T, Bool> {
    @inlinable public var wrappedValue: T {
        get { property }
        set { /* dummy */ }
    }

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
    @inlinable public var wrappedValue: T {
        get { property }
        set { /* dummy */ }
    }

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
    @inlinable public var wrappedValue: T {
        get { property }
        set { /* dummy */ }
    }

    public override func createDescription() -> Description {
        let description = super.createDescription()
        description.maxCount = modifier
        return description
    }
}

@propertyWrapper
public class MinCount<T: RelationshipProtocol>: PropertyModifier<T, Int>
where T.Mapping: ToManyRelationMappingProtocol {
    @inlinable public var wrappedValue: T {
        get { property }
        set { /* dummy */ }
    }

    public override func createDescription() -> Description {
        let description = super.createDescription()
        description.minCount = modifier
        return description
    }
}

@propertyWrapper
public class DeleteRule<T: RelationshipProtocol>: PropertyModifier<T, NSDeleteRule> {
    @inlinable public var wrappedValue: T {
        get { property }
        set { /* dummy */ }
    }

    public override func createDescription() -> Description {
        let description = super.createDescription()
        description.deleteRule = modifier
        return description
    }
}

@propertyWrapper
public class UnidirectionalInverse<T: RelationshipProtocol>: PropertyModifier<T, Bool> {
    @inlinable public var wrappedValue: T {
        get { property }
        set { /* dummy */ }
    }

    public init(wrappedValue: T) {
        super.init(wrappedValue: wrappedValue, true)
        self.isUniDirectional = true
    }
}

@propertyWrapper
public class VersionModifier<T: WritableValuedProperty>: PropertyModifier<T, String?> {
    @inlinable public var wrappedValue: T {
        get { property }
        set { /* dummy */ }
    }

    public override func createDescription() -> Description {
        let description = super.createDescription()
        description.versionHashModifier = modifier
        return description
    }
}
