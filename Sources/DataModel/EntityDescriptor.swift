//
//  EntityDescriptor.swift
//  
//
//  Created by EZOU on 2023/2/28.
//

import CoreData
import Foundation

// MARK: Descriptior

protocol EntityDescriptior: Entity {
    var entityInheritance: EntityInheritance { get }

    func createEntityDescription(
        inheritanceData: [ObjectIdentifier: EntityInheritance],
        cache: EntityCache
    ) -> NSEntityDescription?
}

/// This will mark `T` as an abstract entity
@propertyWrapper
public final class Abstract<T: Entity>: Entity, EntityDescriptior {
    var entityInheritance: EntityInheritance {
        .abstract
    }

    override func typeIdentifier() -> ObjectIdentifier {
        wrappedValue.typeIdentifier()
    }

    public var wrappedValue: T

    public init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }

    public required init() {
        self.wrappedValue = T()
    }

    override func createEntityDescription(
        inheritanceData: [ObjectIdentifier: EntityInheritance],
        cache: EntityCache
    ) -> NSEntityDescription? {
        let description = wrappedValue.createEntityDescription(inheritanceData: inheritanceData, cache: cache)
        description?.isAbstract = true
        return description
    }
}

/// This will mark `T` as an concrete entity which is the default behaviour
@propertyWrapper
public final class Concrete<T: Entity>: Entity, EntityDescriptior {
    var entityInheritance: EntityInheritance {
        .concrete
    }

    override func typeIdentifier() -> ObjectIdentifier {
        wrappedValue.typeIdentifier()
    }

    public var wrappedValue: T

    public init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }

    public required init() {
        self.wrappedValue = T()
    }

    override func createEntityDescription(
        inheritanceData: [ObjectIdentifier: EntityInheritance],
        cache: EntityCache
    ) -> NSEntityDescription? {
        let description = wrappedValue.createEntityDescription(inheritanceData: inheritanceData, cache: cache)
        description?.isAbstract = false
        return description
    }
}

/// This will mark `T` as an embedded entity
@propertyWrapper
public final class Embedded<T: Entity>: Entity, EntityDescriptior {
    var entityInheritance: EntityInheritance {
        .embedded
    }

    override func typeIdentifier() -> ObjectIdentifier {
        wrappedValue.typeIdentifier()
    }

    public var wrappedValue: T

    public init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }

    public required init() {
        self.wrappedValue = T()
    }

    override func createEntityDescription(
        inheritanceData: [ObjectIdentifier: EntityInheritance],
        cache: EntityCache
    ) -> NSEntityDescription? {
        nil
    }
}

// MARK: Configuration

protocol ConfigurationEntityDescriptior: EntityDescriptior {
    var names: [String]? { get }
}

/// Assign `T` entity to specified configuration group
@propertyWrapper
public final class Configuration<T: Entity>: Entity, ConfigurationEntityDescriptior {
    var entityInheritance: EntityInheritance {
        guard let descriptor = wrappedValue as? EntityDescriptior
        else { return .concrete }
        return descriptor.entityInheritance
    }

    override func typeIdentifier() -> ObjectIdentifier {
        wrappedValue.typeIdentifier()
    }

    public var wrappedValue: T
    public let names: [String]?

    public init(wrappedValue value: T, names: [String]?) {
        self.wrappedValue = value
        if let names = names {
            self.names = names + ((value as? ConfigurationEntityDescriptior)?.names ?? [])
        } else {
            self.names = (value as? ConfigurationEntityDescriptior)?.names
        }
    }

    public init(wrappedValue value: T, name: String?) {
        self.wrappedValue = value
        if let name = name {
            self.names = [name] + ((value as? ConfigurationEntityDescriptior)?.names ?? [])
        } else {
            self.names = (value as? ConfigurationEntityDescriptior)?.names
        }
    }

    public required init() {
        self.names = nil
        self.wrappedValue = T()
    }

    override func createEntityDescription(
        inheritanceData: [ObjectIdentifier: EntityInheritance],
        cache: EntityCache
    ) -> NSEntityDescription? {
        wrappedValue.createEntityDescription(inheritanceData: inheritanceData, cache: cache)
    }
}
