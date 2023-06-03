//
//  Property+Fetched.swift
//
//
//  Created by ezou on 2021/10/22.
//

import CoreData

public protocol FetchedPropertyProtocol: Property, PropertyType
where
    RuntimeValue == [ReadOnly<Destination>],
    ManagedValue == [NSManagedObject],
    PredicateValue == PropertyType.ManagedValue,
    Description == NSFetchedPropertyDescription
{
    associatedtype Destination: Entity
}

extension FetchedPropertyProtocol {
    public static func convert(managedValue: ManagedValue) -> RuntimeValue {
        managedValue.map { ReadOnly(object: $0) }
    }

    public static func convert(runtimeValue: RuntimeValue) -> ManagedValue {
        runtimeValue.map(\.managedObject)
    }

    @inlinable public static var defaultManagedValue: ManagedValue { [] }
    @inlinable public static var defaultRuntimeValue: RuntimeValue { [] }
}

/// A class that provides a dynamic way to fetch properties from an entity.
@dynamicMemberLookup
public struct FetchSource<T: Entity, P: Property> {

    /// A string expression representing the fetch source.
    public static var expression: String {
        "$FETCH_SOURCE"
    }

    /// The name of the fetched property.
    public let property: String

    public init(_ property: String) {
        self.property = property
    }

    public init(_ keyPath: KeyPath<T, P>) {
        self.property = keyPath.propertyName
    }

    /// A string expression representing the fetched property.
    public var expression: String {
        "$FETCH_SOURCE.\(property)"
    }

    /// Subscript that returns a `FetchSourceProperty` object for a given key path.
    /// - Parameter keyPath: A key path that specifies the property to fetch.
    /// - Returns: A `FetchSourceProperty` object representing the fetched property.
    public static subscript(
        dynamicMember keyPath: KeyPath<T, P>) -> FetchSource<T, P>
    {
        FetchSource(keyPath.propertyName)
    }
}


public final class FetchedProperty<T: Entity>: FetchedPropertyProtocol, EntityCachedProtocol {
    public typealias Destination = T
    public typealias RuntimeValue = [T.ReadOnly]
    public typealias ManagedValue = [NSManagedObject]
    public typealias PropertyType = FetchedProperty<T>
    public typealias PredicateValue = PropertyType.ManagedValue
    public typealias PropertyValue = PropertyType.RuntimeValue
    public typealias Configuration = (FetchBuilder<T>) -> FetchBuilder<T>

    internal let configuration: Configuration

    public let name: String
    public var isAttribute: Bool { false }

    var cache: EntityCache?

    public init(_ name: String, _ block: @escaping Configuration) {
        self.name = name
        self.configuration = block
    }

    public func createPropertyDescription() -> NSFetchedPropertyDescription {
        let builder = configuration(FetchBuilder(config: .init(), context: .dummy()))
        let description = NSFetchedPropertyDescription()
        description.name = name

        cache?.get(T.entityCacheKey) {
            let request = NSFetchRequest<NSFetchRequestResult>()
            builder.config.configureRequest(request)
            request.entity = $0
            request.resultType = .managedObjectResultType
            description.fetchRequest = request
        }
        return description
    }
}
