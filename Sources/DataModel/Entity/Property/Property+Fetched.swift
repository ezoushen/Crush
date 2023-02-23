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
}

public final class FetchedProperty<T: Entity>: FetchedPropertyProtocol {
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

    public init(_ name: String, _ block: @escaping Configuration) {
        self.name = name
        self.configuration = block
    }

    public func createPropertyDescription() -> NSFetchedPropertyDescription {
        let builder = configuration(
            FetchBuilder(
                config: .init(), context: DummyContext())
        )
        let description = NSFetchedPropertyDescription()
        description.name = name
        Caches.entity.getAndWait(T.entityCacheKey) {
            let request = NSFetchRequest<NSFetchRequestResult>()
            request.entity = $0
            builder.config.configureRequest(request)
            description.fetchRequest = request
        }
        return description
    }
}
