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
    var entityInheritance: EntityInheritance { get }
    
    func typeIdentifier() -> ObjectIdentifier
    func createEntityDescription(
        inheritanceData: [ObjectIdentifier: EntityInheritance],
        cache: EntityCache
    ) -> NSEntityDescription?
}

/// This will mark `T` as an abstract entity
@propertyWrapper
public final class Abstract<T: Entity>: Entity, EntityDescriptor {
    var configurations: [String]? {
        get { (wrappedValue as? EntityDescriptor)?.configurations }
        set { (wrappedValue as? EntityDescriptor)?.configurations = newValue }
    }

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
public final class Concrete<T: Entity>: Entity, EntityDescriptor {
    var configurations: [String]? {
        get { (wrappedValue as? EntityDescriptor)?.configurations }
        set { (wrappedValue as? EntityDescriptor)?.configurations = newValue }
    }

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
public final class Embedded<T: Entity>: Entity, EntityDescriptor {
    var configurations: [String]? {
        get { (wrappedValue as? EntityDescriptor)?.configurations }
        set { (wrappedValue as? EntityDescriptor)?.configurations = newValue }
    }

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

    var entityInheritance: EntityInheritance {
        guard let descriptor = wrappedValue as? EntityDescriptor
        else { return .concrete }
        return descriptor.entityInheritance
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

    public required init() {
        self.names = nil
        self.wrappedValue = T()
    }

    override func createEntityDescription(
        inheritanceData: [ObjectIdentifier: EntityInheritance],
        cache: EntityCache
    ) -> NSEntityDescription? {
        return wrappedValue.createEntityDescription(inheritanceData: inheritanceData, cache: cache)
    }
}
