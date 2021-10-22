//
//  Property+Fetched.swift
//  
//
//  Created by ezou on 2021/10/22.
//

import CoreData

public class FetchedProperty<T: Entity>: ValuedProperty {
    public typealias FieldConvertor = ToMany<T>
    public typealias PredicateValue = FieldConvertor.ManagedObjectValue
    public typealias PropertyValue = FieldConvertor.RuntimeObjectValue
    public typealias Description = NSFetchedPropertyDescription
    public typealias Configuration = (PartialFetchBuilder<T, T.Managed, T.ReadOnly>) -> PartialFetchBuilder<T, T.Managed, T.ReadOnly>

    internal let configuration: Configuration

    public let name: String
    public var isAttribute: Bool { false }

    public init(_ name: String, _ block: @escaping Configuration) {
        self.name = name
        self.configuration = block
    }

    public func createDescription() -> NSFetchedPropertyDescription {
        let builder = configuration(
            PartialFetchBuilder(
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
