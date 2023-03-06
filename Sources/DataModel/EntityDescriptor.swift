//
//  EntityDescriptor.swift
//  
//
//  Created by EZOU on 2023/2/28.
//

import CoreData
import Foundation

// MARK: Descriptior

protocol EntityDescriptor: Entity {
    var configurations: [String]? { get set }
    var entityAbstraction: EntityAbstraction { get }
    
    func typeIdentifier() -> ObjectIdentifier
    func createEntityDescription(
        abstractionData: [ObjectIdentifier: EntityAbstraction],
        cache: EntityCache
    ) -> NSEntityDescription?
}

public class EntityTypeDescriptor<T: Entity>: Entity, EntityDescriptor {
    var configurations: [String]? {
        get { (entity as? EntityDescriptor)?.configurations }
        set { (entity as? EntityDescriptor)?.configurations = newValue }
    }

    var entityAbstraction: EntityAbstraction {
        fatalError("Unimplemented")
    }

    override func typeIdentifier() -> ObjectIdentifier {
        entity.typeIdentifier()
    }

    let entity: T

    public init(_ wrappedValue: T) {
        self.entity = wrappedValue
    }

    public required init() {
        self.entity = T()
    }
}

/// This will mark `T` as an abstract entity
@propertyWrapper
public final class Abstract<T: Entity>: EntityTypeDescriptor<T> {

    public var wrappedValue: T { entity }

    public convenience init(wrappedValue: T) {
        self.init(wrappedValue)
    }

    override var entityAbstraction: EntityAbstraction { .abstract }

    override func createEntityDescription(
        abstractionData: [ObjectIdentifier: EntityAbstraction],
        cache: EntityCache
    ) -> NSEntityDescription? {
        let description = wrappedValue.createEntityDescription(abstractionData: abstractionData, cache: cache)
        description?.isAbstract = true
        return description
    }
}

/// This will mark `T` as an concrete entity which is the default behaviour
@propertyWrapper
public final class Concrete<T: Entity>: EntityTypeDescriptor<T> {

    override var entityAbstraction: EntityAbstraction { .concrete }

    public var wrappedValue: T { entity }

    public convenience init(wrappedValue: T) {
        self.init(wrappedValue)
    }

    override func createEntityDescription(
        abstractionData: [ObjectIdentifier: EntityAbstraction],
        cache: EntityCache
    ) -> NSEntityDescription? {
        let description = wrappedValue.createEntityDescription(abstractionData: abstractionData, cache: cache)
        description?.isAbstract = false
        return description
    }
}

/// This will mark `T` as an embedded entity
@propertyWrapper
public final class Embedded<T: Entity>: EntityTypeDescriptor<T> {

    override var entityAbstraction: EntityAbstraction { .embedded }

    public var wrappedValue: T { entity }

    public convenience init(wrappedValue: T) {
        self.init(wrappedValue)
    }

    override func createEntityDescription(
        abstractionData: [ObjectIdentifier: EntityAbstraction],
        cache: EntityCache
    ) -> NSEntityDescription? {
        nil
    }
}

// MARK: Configuration

protocol ConfigurationEntityDescriptior: EntityDescriptor {
    var names: [String]? { get }
}

/// Assign `T` entity to specified configuration group
@propertyWrapper
public final class Configuration<T: Entity>: Entity, ConfigurationEntityDescriptior {
    var configurations: [String]? {
        get { names }
        set { names = newValue }
    }

    var entityAbstraction: EntityAbstraction {
        guard let descriptor = wrappedValue as? EntityDescriptor
        else { return .concrete }
        return descriptor.entityAbstraction
    }

    override func typeIdentifier() -> ObjectIdentifier {
        wrappedValue.typeIdentifier()
    }

    public var wrappedValue: T
    public var names: [String]?

    /// Assign the entity to multiple configuration groups at the same time
    public init(wrappedValue value: T, names: [String]?) {
        self.wrappedValue = value
        if let names = names {
            self.names = names + ((value as? ConfigurationEntityDescriptior)?.names ?? [])
        } else {
            self.names = (value as? ConfigurationEntityDescriptior)?.names
        }
    }

    /// Assign the entity to a configuration group
    public init(wrappedValue value: T, _ name: String?) {
        self.wrappedValue = value
        if let name = name {
            self.names = [name] + ((value as? ConfigurationEntityDescriptior)?.names ?? [])
        } else {
            self.names = (value as? ConfigurationEntityDescriptior)?.names
        }
    }

    public init(_ value: T, _ configurations: String...) {
        self.wrappedValue = value
        self.names = configurations.isEmpty ? nil : configurations
    }

    public required init() {
        self.names = nil
        self.wrappedValue = T()
    }

    override func createEntityDescription(
        abstractionData: [ObjectIdentifier: EntityAbstraction],
        cache: EntityCache
    ) -> NSEntityDescription? {
        wrappedValue.createEntityDescription(abstractionData: abstractionData, cache: cache)
    }
}
