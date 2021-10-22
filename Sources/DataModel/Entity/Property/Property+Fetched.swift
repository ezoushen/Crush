//
//  Property+Fetched.swift
//  
//
//  Created by ezou on 2021/10/22.
//

import CoreData

public final class FetchedProperty<T: Entity>: ValuedProperty, FieldConvertible {
    public static func convert(value: [T.Managed]) -> [T.ReadOnly] {
        value.map { ReadOnly($0) }
    }
    
    public static func convert(value: [T.ReadOnly]) -> [T.Managed] {
        value.map { $0.value }
    }
    
    public typealias RuntimeObjectValue = [T.ReadOnly]
    public typealias ManagedObjectValue = [T.Managed]
    public typealias FieldConvertor = FetchedProperty<T>
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
