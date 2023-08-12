//
//  Property+Modifier.swift
//  
//
//  Created by ezou on 2021/10/18.
//

import CoreData
import Foundation

/// A property modifier that modifies a writable property.
open class PropertyModifier<T: WritableProperty, S>: WritableProperty, EntityCachedProtocol {
    /// The description type of the wrapped property.
    public typealias Description = T.Description
    /// The runtime value type of the wrapped property.
    public typealias PropertyValue = T.RuntimeValue
    /// The predicate value type of the wrapped property.
    public typealias PredicateValue = T.PredicateValue
    /// The property type of the wrapped property.
    public typealias PropertyType = T.PropertyType

    /// The name of the property.
    public var name: String { property.name }
    /// A boolean value indicating whether the property is an attribute.
    public var isAttribute: Bool { property.isAttribute }

    /// The wrapped property.
    public let property: T
    /// The modifier applied to the property.
    public let modifier: S

    /// The cache associated with the property, if it conforms to `EntityCachedProtocol`.
    var cache: EntityCache? {
        get { (property as? EntityCachedProtocol)?.cache }
        set { (property as? EntityCachedProtocol)?.cache = newValue }
    }

    /// Initializes a `PropertyModifier` with the specified wrapped value and modifier.
    ///
    /// - Parameters:
    ///   - wrappedValue: The wrapped value.
    ///   - modifier: The modifier applied to the wrapped value.
    public init(wrappedValue: T, _ modifier: S) {
        self.property = wrappedValue
        self.modifier = modifier
    }

    /// Creates the property description for the wrapped property.
    ///
    /// - Returns: The property description.
    open func createPropertyDescription() -> Description {
        property.createPropertyDescription()
    }
}

extension PropertyModifier: RelationshipProtocol where T: RelationshipProtocol {
    /// The destination type of the wrapped property.
    public typealias Destination = T.Destination
    /// The mapping type of the wrapped property.
    public typealias Mapping = T.Mapping

    /// A boolean value indicating whether the relationship is unidirectional.
    public var isUniDirectional: Bool {
        get { property.isUniDirectional }
        set { property.isUniDirectional = newValue }
    }
}

extension PropertyModifier: AttributeProtocol where T: AttributeProtocol { }

/// A protocol that represents a transient property.
public protocol TransientProperty: Property { }

extension PropertyModifier: TransientProperty where T: TransientProperty { }

extension PropertyModifier: ConcreteAttriuteProcotol where T: ConcreteAttriuteProcotol { }

// MARK: Index

/// A namespace for property modifiers related to indexes.
public enum PropertyModifiers {
    public typealias Optional = Crush.Optional
    public typealias Required = Crush.Required
    public typealias Transient = Crush.Transient
    public typealias Indexed = Crush.Indexed
    public typealias IndexedBySpotlight = Crush.IndexedBySpotlight
    public typealias Unique = Crush.Unique
    public typealias VersionModifier = Crush.VersionModifier
}

/// A namespace for property modifiers related to attributes.
public enum AttributeModifiers {
    public typealias Default = Crush.Default
    public typealias ExternalBinaryDataStorage = Crush.ExternalBinaryDataStorage
    public typealias Validation = Crush.Validation

    @available(iOS 13.0, watchOS 6.0, macOS 10.15, tvOS 13.0, *)
    public typealias PreserveValueInHistoryOnDeletion = Crush.PreservesValueInHistoryOnDeletion
}

/// A namespace for property modifiers related to relationships.
public enum RelationshipModifiers {
    public typealias Inverse = Crush.Inverse
    public typealias MaxCount = Crush.MaxCount
    public typealias MinCount = Crush.MinCount
    public typealias DeleteRule = Crush.DeleteRule
    public typealias UnidirectionalInverse = Crush.UnidirectionalInverse
}

// MARK: Property modifier

/// A property wrapper that makes a property optional.
///
/// Usages:
///
///     @Optional
///     var nickName = Value.String("nickName")
///
@propertyWrapper
public class Optional<T: WritableProperty>: PropertyModifier<T, Bool> {
    /// The wrapped value of the property.
    @inlinable public var wrappedValue: T {
        get { property }
        set { /* dummy */ }
    }

    /// Initializes an `Optional` property modifier with the specified wrapped value.
    ///
    /// - Parameter wrappedValue: The wrapped value.
    public init(wrappedValue: T) {
        super.init(wrappedValue: wrappedValue, true)
    }

    /// Creates the property description for the wrapped property.
    ///
    /// - Returns: The property description.
    public override func createPropertyDescription() -> PropertyModifier<T, Bool>.Description {
        let description = super.createPropertyDescription()
        description.isOptional = modifier
        return description
    }
}


/// A property wrapper that marks a property as required.
///
/// Usage:
///
///     @Required
///     var name = Value.String("name")
///
@propertyWrapper
public class Required<T: WritableProperty>: PropertyModifier<T, Bool> {
    /// The wrapped value of the property.
    @inlinable public var wrappedValue: T {
        get { property }
        set { /* dummy */ }
    }

    /// Initializes a new instance of the `Required` property wrapper.
    ///
    /// - Parameter wrappedValue: The initial value of the property.
    public init(wrappedValue: T) {
        super.init(wrappedValue: wrappedValue, false)
    }

    /// Creates a property description for the `Required` property wrapper.
    ///
    /// - Returns: A property description.
    public override func createPropertyDescription() -> PropertyModifier<T, Bool>.Description {
        let description = super.createPropertyDescription()
        description.isOptional = modifier
        return description
    }
}

/// A property wrapper that marks a property as transient.
///
/// Usage:
///
///     @Transient
///     var accessCount = Value.Int16("accessCount")
///
@propertyWrapper
public class Transient<T: WritableProperty & TransientProperty>: PropertyModifier<T, Bool> {
    /// The wrapped value of the property.
    @inlinable public var wrappedValue: T {
        get { property }
        set { /* dummy */ }
    }

    /// Initializes a new instance of the `Transient` property wrapper.
    ///
    /// - Parameter wrappedValue: The initial value of the property.
    public init(wrappedValue: T) {
        super.init(wrappedValue: wrappedValue, true)
    }

    /// Creates a property description for the `Transient` property wrapper.
    ///
    /// - Returns: A property description.
    public override func createPropertyDescription() -> PropertyModifier<T, Bool>.Description {
        let description = super.createPropertyDescription()
        description.isTransient = modifier
        return description
    }
}

/// A property wrapper that marks a property as indexed by Spotlight.
///
/// Usage:
///
///     @IndexedBySpotlight
///     var title = Value.String("title")
///
///     // Spotlight indexing is enabled for this property
///
@propertyWrapper
public class IndexedBySpotlight<T: WritableProperty>: PropertyModifier<T, Bool> {
    /// The wrapped value of the property.
    @inlinable public var wrappedValue: T {
        get { property }
        set { /* dummy */ }
    }

    /// Initializes a new instance of the `IndexedBySpotlight` property wrapper.
    ///
    /// - Parameter wrappedValue: The initial value of the property.
    public init(wrappedValue: T) {
        super.init(wrappedValue: wrappedValue, true)
    }

    /// Creates a property description for the `IndexedBySpotlight` property wrapper.
    ///
    /// - Returns: A property description.
    public override func createPropertyDescription() -> Description {
        let description = super.createPropertyDescription()
        description.isIndexedBySpotlight = modifier
        return description
    }
}

/// A protocol that defines properties required for indexing.
public protocol IndexProtocol {
    var predicate: NSPredicate? { get }
    var collationType: NSFetchIndexElementType { get }
    var indexName: String? { get }
    var targetEntityName: String? { get }

    func createFetchIndexElementDescription(
        from description: NSPropertyDescription) -> NSFetchIndexElementDescription
}

/// A property wrapper that marks a property as indexed.
///
/// Usage:
///
///     @Indexed
///     var name = Value.String("name")
///
@propertyWrapper
public class Indexed<T: WritableProperty>: PropertyModifier<T, String?>, IndexProtocol {
    /// The wrapped value of the property.
    @inlinable public var wrappedValue: T {
        get { property }
        set { /* dummy */ }
    }

    /// The name of the index.
    @inlinable public var indexName: String? { modifier }

    /// The collation type of the index.
    public let collationType: NSFetchIndexElementType
    /// The predicate of the index.
    public let predicate: NSPredicate?
    /// The target entity name of the index.
    public let targetEntityName: String?

    /// Initializes a new instance of the `Indexed` property wrapper.
    ///
    /// - Parameters:
    ///   - wrappedValue: The initial value of the property.
    ///   - modifier: The name of the index.
    ///   - target: The target entity type.
    ///   - collationType: The collation type of the index.
    ///   - predicate: The predicate of the index.
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

    /// Initializes a new instance of the `Indexed` property wrapper.
    ///
    /// - Parameters:
    ///   - wrappedValue: The initial value of the property.
    ///   - modifier: The name of the index.
    ///   - target: The target entity type.
    ///   - collationType: The collation type of the index.
    ///   - predicate: The predicate of the index.
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

    /// Creates a property description for the `Indexed` property wrapper.
    ///
    /// - Returns: A property description.
    public override func createPropertyDescription() -> Description {
        let description = super.createPropertyDescription()
        var userInfo = description.userInfo ?? [:]
        var indexes = userInfo[UserInfoKey.indexes] as? [IndexProtocol] ?? []
        indexes.append(self)
        userInfo[UserInfoKey.indexes] = indexes
        description.userInfo = userInfo
        return description
    }

    /// Creates a fetch index element description for the `Indexed` property wrapper.
    ///
    /// - Parameter description: The property description.
    /// - Returns: A fetch index element description.
    public func createFetchIndexElementDescription(
        from description: NSPropertyDescription) -> NSFetchIndexElementDescription
    {
        NSFetchIndexElementDescription(
            property: description, collationType: collationType)
    }
}

/// A property wrapper that marks a property as unique.
///
/// Usage:
///
///     @Unique
///     var email = Value.String("email")
///
@propertyWrapper
public class Unique<T: WritableProperty>: PropertyModifier<T, String?> {
    /// The wrapped value of the property.
    @inlinable public var wrappedValue: T {
        get { property }
        set { /* dummy */ }
    }

    /// Initializes a new instance of the `Unique` property wrapper.
    ///
    /// - Parameters:
    ///   - wrappedValue: The initial value of the property.
    ///   - modifier: The name of the uniqueness constraint.
    public override init(wrappedValue: T, _ modifier: String? = nil) {
        super.init(wrappedValue: wrappedValue, modifier)
    }

    /// Creates a property description for the `Unique` property wrapper.
    ///
    /// - Returns: A property description.
    public override func createPropertyDescription() -> Description {
        let description = super.createPropertyDescription()
        var userInfo = description.userInfo ?? [:]
        userInfo[UserInfoKey.uniquenessConstraintName] = modifier ?? description.name
        description.userInfo = userInfo
        return description
    }
}

/// A property wrapper that modifies the version hash of a property.
///
/// This is useful while migration needs to be performed while version hash of the property is not changed between versions
///
/// Usage:
///
///     @VersionModifier("V8")
///     var name: String
///
@propertyWrapper
public class VersionModifier<T: WritableProperty>: PropertyModifier<T, String?> {
    /// The wrapped value of the property.
    @inlinable public var wrappedValue: T {
        get { property }
        set { /* dummy */ }
    }

    /// Creates a property description for the `VersionModifier` property wrapper.
    ///
    /// - Returns: A property description.
    public override func createPropertyDescription() -> Description {
        let description = super.createPropertyDescription()
        description.versionHashModifier = modifier
        return description
    }
}

/// A property wrapper that provides a default value for a property.
///
/// Example usage:
///
///     @Default(0)
///     var count = Value.Int16("count")
///
@propertyWrapper
public class Default<T: ConcreteAttriuteProcotol>:
    PropertyModifier<T, T.RuntimeValue>
{
    /// The wrapped value of the property.
    @inlinable public var wrappedValue: T {
        get { property }
        set { /* dummy */ }
    }

    /// Creates a property description with the default value.
    ///
    /// - Returns: The created property description.
    public override func createPropertyDescription() -> Description {
        let description = super.createPropertyDescription()
        description.defaultValue = T.PropertyType.convert(runtimeValue: modifier)
        return description
    }
}

/// A property wrapper that enables external binary data storage for a property.
///
/// Example usage:
///
///     @ExternalBinaryDataStorage
///     var largeImageData = Value.Data("largeImageData")
///
@propertyWrapper
public class ExternalBinaryDataStorage<T: AttributeProtocol>: PropertyModifier<T, Bool> {
    /// The wrapped value of the property.
    @inlinable public var wrappedValue: T {
        get { property }
        set { /* dummy */ }
    }

    /// Initializes the property wrapper with the wrapped value.
    ///
    /// - Parameter wrappedValue: The wrapped value.
    public init(wrappedValue: T) {
        super.init(wrappedValue: wrappedValue, true)
    }

    /// Creates a property description with the external binary data storage flag.
    ///
    /// - Returns: The created property description.
    public override func createPropertyDescription() -> Description {
        let description = super.createPropertyDescription()
        description.allowsExternalBinaryDataStorage = modifier
        return description
    }
}

/// A property wrapper that applies validation to a property.
///
/// Example usage:
///
///     @Validation(.length(greaterThan: 0), warning: "Name should not be empty")
///     var name = Value.String("name")
///
@propertyWrapper
public class Validation<T: AttributeProtocol>: PropertyModifier<T, PropertyCondition<T.PredicateValue>> {
    /// The wrapped value of the property.
    @inlinable public var wrappedValue: T {
        get { property }
        set { /* dummy */ }
    }

    /// The warning message for the validation.
    public let warning: String

    /// Initializes the property wrapper with the wrapped value, modifier, and warning message.
    ///
    /// - Parameters:
    ///   - wrappedValue: The wrapped value.
    ///   - modifier: The validation modifier.
    ///   - warning: The warning message.
    public init(
        wrappedValue: T, _ modifier: PropertyCondition<T.PredicateValue>, warning: String = "")
    {
        self.warning = warning
        super.init(wrappedValue: wrappedValue, modifier)
    }

    /// Creates a property description with the validation predicates and warnings.
    ///
    /// - Returns: The created property description.
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

/// A property wrapper that preserves the value in history on deletion for a property.
///
/// Example usage:
///
///     @PreservesValueInHistoryOnDeletion
///     var uuid = Value.UUID("uuid")
///
@available(iOS 13.0, watchOS 6.0, macOS 10.15, tvOS 13.0, *)
@propertyWrapper
public class PreservesValueInHistoryOnDeletion<T: AttributeProtocol>: PropertyModifier<T, Bool> {
    /// The wrapped value of the property.
    @inlinable public var wrappedValue: T {
        get { property }
        set { /* dummy */ }
    }

    /// Initializes the property wrapper with the wrapped value.
    ///
    /// - Parameter wrappedValue: The wrapped value.
    public init(wrappedValue: T) {
        super.init(wrappedValue: wrappedValue, true)
    }

    /// Creates a property description with the preserves value in history on deletion flag.
    ///
    /// - Returns: The created property description.
    public override func createPropertyDescription() -> Description {
        let description = super.createPropertyDescription()
        description.preservesValueInHistoryOnDeletion = modifier
        return description
    }
}

/// A property wrapper that specifies the inverse relationship for a relationship property.
///
/// Example usage:
///
///     @Inverse(\Person.pets)
///     var owner = Raltion.ToOne<Person>("owner")
///
@propertyWrapper
public class Inverse<T: RelationshipProtocol, S: RelationshipProtocol>:
    PropertyModifier<T, KeyPath<T.Destination, S>>
{
    /// The wrapped value of the property.
    @inlinable public var wrappedValue: T {
        get { property }
        set { /* dummy */ }
    }

    /// Creates a relationship description with the inverse relationship.
    ///
    /// - Returns: The created relationship description.
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

/// A property wrapper that specifies the maximum count for a to-many relationship property.
///
/// Example usage:
///
///     @MaxCount(5)
///     var employees = Relation.ToMany<Employee>("employees")
///
@propertyWrapper
public final class MaxCount<T: RelationshipProtocol>: PropertyModifier<T, Int>
where T.Mapping: ToManyRelationMappingProtocol {
    /// The wrapped value of the property.
    @inlinable public var wrappedValue: T {
        get { property }
        set { /* dummy */ }
    }

    /// Creates a property description with the maximum count.
    ///
    /// - Returns: The created property description.
    public override func createPropertyDescription() -> Description {
        let description = super.createPropertyDescription()
        description.maxCount = modifier
        return description
    }
}

/// A property wrapper that specifies the minimum count for a to-many relationship property.
///
/// Example usage:
///
///     @MinCount(1)
///     var employees = Relation.ToMany<Employee>("employees")
///
@propertyWrapper
public class MinCount<T: RelationshipProtocol>: PropertyModifier<T, Int>
where T.Mapping: ToManyRelationMappingProtocol {
    /// The wrapped value of the property.
    @inlinable public var wrappedValue: T {
        get { property }
        set { /* dummy */ }
    }

    /// Creates a property description with the minimum count.
    ///
    /// - Returns: The created property description.
    public override func createPropertyDescription() -> Description {
        let description = super.createPropertyDescription()
        description.minCount = modifier
        return description
    }
}

/// A property wrapper that specifies the delete rule for a relationship property.
///
/// Example usage:
///
///     @DeleteRule(.cascade)
///     var employee = Relation.ToOne<Employee>("empployee")
///
@propertyWrapper
public class DeleteRule<T: RelationshipProtocol>: PropertyModifier<T, NSDeleteRule> {
    /// The wrapped value of the property.
    @inlinable public var wrappedValue: T {
        get { property }
        set { /* dummy */ }
    }

    /// Creates a property description with the delete rule.
    ///
    /// - Returns: The created property description.
    public override func createPropertyDescription() -> Description {
        let description = super.createPropertyDescription()
        description.deleteRule = modifier
        return description
    }
}

/// A property wrapper that specifies a unidirectional inverse relationship for a relationship property.
///
/// Example usage:
///
///     @UnidirectionalInverse
///     var employee = Relation.ToOne<Employee>("employee")
///
@propertyWrapper
public class UnidirectionalInverse<T: RelationshipProtocol>: PropertyModifier<T, Bool> {
    /// The wrapped value of the property.
    @inlinable public var wrappedValue: T {
        get { property }
        set { /* dummy */ }
    }

    /// Initializes the property wrapper with the wrapped value and sets the unidirectional flag.
    ///
    /// - Parameter wrappedValue: The wrapped value.
    public init(wrappedValue: T) {
        super.init(wrappedValue: wrappedValue, true)
        self.isUniDirectional = true
    }
}
