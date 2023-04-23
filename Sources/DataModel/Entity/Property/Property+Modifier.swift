//
//  Property+Modifier.swift
//  
//
//  Created by ezou on 2021/10/18.
//

import CoreData
import Foundation

open class PropertyModifier<T: WritableProperty, S>: WritableProperty, EntityCachedProtocol {
    public typealias Description = T.Description
    public typealias PropertyValue = T.RuntimeValue
    public typealias PredicateValue = T.PredicateValue
    public typealias PropertyType = T.PropertyType

    public var name: String { property.name }
    public var isAttribute: Bool { property.isAttribute }

    public let property: T
    public let modifier: S

    var cache: EntityCache? {
        get { (property as? EntityCachedProtocol)?.cache }
        set { (property as? EntityCachedProtocol)?.cache = newValue }
    }

    public init(wrappedValue: T, _ modifier: S) {
        self.property = wrappedValue
        self.modifier = modifier
    }

    open func createPropertyDescription() -> Description {
        property.createPropertyDescription()
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

public protocol TransientProperty: Property { }

extension PropertyModifier: TransientProperty where T: TransientProperty { }

extension PropertyModifier: ConcreteAttriuteProcotol where T: ConcreteAttriuteProcotol { }

// MARK: Property modifier

@propertyWrapper
public class Optional<T: WritableProperty>: PropertyModifier<T, Bool> {
    @inlinable public var wrappedValue: T {
        get { property }
        set { /* dummy */ }
    }

    public init(wrappedValue: T) {
        super.init(wrappedValue: wrappedValue, true)
    }

    public override func createPropertyDescription() -> PropertyModifier<T, Bool>.Description {
        let description = super.createPropertyDescription()
        description.isOptional = modifier
        return description
    }
}

@propertyWrapper
public class Required<T: WritableProperty>: PropertyModifier<T, Bool> {
    @inlinable public var wrappedValue: T {
        get { property }
        set { /* dummy */ }
    }

    public init(wrappedValue: T) {
        super.init(wrappedValue: wrappedValue, false)
    }

    public override func createPropertyDescription() -> PropertyModifier<T, Bool>.Description {
        let description = super.createPropertyDescription()
        description.isOptional = modifier
        return description
    }
}

@propertyWrapper
public class Transient<T: WritableProperty & TransientProperty>: PropertyModifier<T, Bool> {
    @inlinable public var wrappedValue: T {
        get { property }
        set { /* dummy */ }
    }

    public init(wrappedValue: T) {
        super.init(wrappedValue: wrappedValue, true)
    }

    public override func createPropertyDescription() -> PropertyModifier<T, Bool>.Description {
        let description = super.createPropertyDescription()
        description.isTransient = modifier
        return description
    }
}

/// This option will be ignored while the property is transient
@propertyWrapper
public class IndexedBySpotlight<T: WritableProperty>: PropertyModifier<T, Bool> {
    @inlinable public var wrappedValue: T {
        get { property }
        set { /* dummy */ }
    }

    public init(wrappedValue: T) {
        super.init(wrappedValue: wrappedValue, true)
    }

    public override func createPropertyDescription() -> Description {
        let description = super.createPropertyDescription()
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
public class Indexed<T: WritableProperty>: PropertyModifier<T, String?>, IndexProtocol {
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

    public override func createPropertyDescription() -> Description {
        let description = super.createPropertyDescription()
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
public class Unique<T: WritableProperty>: PropertyModifier<T, String?> {
    @inlinable public var wrappedValue: T {
        get { property }
        set { /* dummy */ }
    }

    public override init(wrappedValue: T, _ modifier: String? = nil) {
        super.init(wrappedValue: wrappedValue, modifier)
    }

    public override func createPropertyDescription() -> Description {
        let description = super.createPropertyDescription()
        var userInfo = description.userInfo ?? [:]
        userInfo[UserInfoKey.uniquenessConstraintName] = modifier ?? description.name
        description.userInfo = userInfo
        return description
    }
}

// MARK: Attribute modifier

@propertyWrapper
public class Default<T: ConcreteAttriuteProcotol>:
    PropertyModifier<T, T.RuntimeValue>
{
    @inlinable public var wrappedValue: T {
        get { property }
        set { /* dummy */ }
    }

    public override func createPropertyDescription() -> Description {
        let description = super.createPropertyDescription()
        description.defaultValue = T.PropertyType.convert(runtimeValue: modifier)
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

    public override func createPropertyDescription() -> Description {
        let description = super.createPropertyDescription()
        description.allowsExternalBinaryDataStorage = modifier
        return description
    }
}

@propertyWrapper
public class Validation<T: AttributeProtocol>: PropertyModifier<T, PropertyCondition<T.PredicateValue>> {
    @inlinable public var wrappedValue: T {
        get { property }
        set { /* dummy */ }
    }
    public let warning: String

    public init(
        wrappedValue: T, _ modifier: PropertyCondition<T.PredicateValue>, warning: String = "")
    {
        self.warning = warning
        super.init(wrappedValue: wrappedValue, modifier)
    }

    public override func createPropertyDescription() -> Description {
        let description = super.createPropertyDescription()
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

    public override func createPropertyDescription() -> Description {
        let description = super.createPropertyDescription()
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

    public override func createPropertyDescription() -> NSRelationshipDescription {
        let description = super.createPropertyDescription()
        let inverseName = self.modifier.propertyName

        let cache = (wrappedValue as? EntityCachedProtocol)?.cache

        cache?.get(Destination.entityCacheKey) {
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

    public override func createPropertyDescription() -> Description {
        let description = super.createPropertyDescription()
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

    public override func createPropertyDescription() -> Description {
        let description = super.createPropertyDescription()
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

    public override func createPropertyDescription() -> Description {
        let description = super.createPropertyDescription()
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
public class VersionModifier<T: WritableProperty>: PropertyModifier<T, String?> {
    @inlinable public var wrappedValue: T {
        get { property }
        set { /* dummy */ }
    }

    public override func createPropertyDescription() -> Description {
        let description = super.createPropertyDescription()
        description.versionHashModifier = modifier
        return description
    }
}
