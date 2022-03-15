//
//  NSPersistentStoreCoordinator+helper.swift
//  
//
//  Created by ezou on 2021/10/15.
//

import CoreData
import Foundation

let CurrentModelVersionName = "Crush.CurrentModelVersionName"
let CurrentModelVersion = "Crush.CurrentModelVersion"

// MARK: Setup metadata

extension NSPersistentStoreCoordinator {
    /// Get version name of last active data model in metadata of the storage
    static func lastActiveVersionName(in storage: Storage) -> String? {
        guard let url = storage.url else { return nil }
        let metadata = try? metadataForPersistentStore(
            ofType: storage.storeType, at: url, options: nil)
        return metadata?[CurrentModelVersionName] as? String
    }

    /// Get version hash of last active data model in metadata of the storage
    static func lastActiveVersion(in storage: Storage) -> String? {
        guard let url = storage.url else { return nil }
        let metadata = try? metadataForPersistentStore(
            ofType: storage.storeType, at: url, options: nil)
        return metadata?[CurrentModelVersion] as? String
    }

    /// Update version hash and version name of the data model in metadata of the storage
    static func updateLastActiveModel(_ dataModel: DataModel, in storage: Storage) {
        guard let url = storage.url,
                var data = try? metadataForPersistentStore(
                    ofType: storage.storeType, at: url, options: nil) else { return }
        data[CurrentModelVersionName] = dataModel.name
        data[CurrentModelVersion] = dataModel.managedObjectModel.version
        try? setMetadata(data, forPersistentStoreOfType: storage.storeType, at: url, options: nil)
    }

    /// Get version name of last active data model
    /// - Parameter url: Location of the persistent store
    func lastActiveVersionName(at url: URL) -> String? {
        guard let store = persistentStore(for: url) else {
            return nil
        }
        return metadata(for: store)[CurrentModelVersionName] as? String
    }

    /// Get version hash of last active data model
    /// - Parameter url: Location of the persistent store
    func lastActiveVersion(at url: URL) -> String? {
        guard let store = persistentStore(for: url) else {
            return nil
        }
        return metadata(for: store)[CurrentModelVersion] as? String
    }

    /// Update version hash and version name of the data model in metadata of the storage
    /// - Parameter name: Version name
    /// - Parameter managedObjectModel: Target managed object model
    /// - Parameter storage: Target storage
    func updateLastActiveModel(
        name: String,
        managedObjectModel: NSManagedObjectModel,
        in storage: ConcreteStorage)
    {
        guard let store = persistentStore(for: storage.storageUrl) else {
            return
        }
        var data = metadata(for: store)
        data[CurrentModelVersionName] = name
        data[CurrentModelVersion] = managedObjectModel.version
        setMetadata(data, for: store)
    }

    /// Convenience method for finding the persistentStore of the storage
    func persistentStore(of storage: Storage) -> NSPersistentStore? {
        if let url = storage.url {
            return persistentStore(for: url)
        } else {
            return persistentStores.first(where: { $0.type == storage.storeType })
        }
    }
}

// MARK: Validate the configuration
struct CoreDataFeatureRequirement: OptionSet {
    let rawValue: UInt8

    func validate(coordinator: NSPersistentStoreCoordinator) -> Bool {
        let validator = Validator(requirement: self)
        for store in coordinator.persistentStores {
            if validator.validate(store: store) { continue }
            return false
        }
        return true
    }
}

extension CoreDataFeatureRequirement {
    static var sqliteStore: CoreDataFeatureRequirement {
        CoreDataFeatureRequirement(rawValue: 1 << 0)
    }

    static var concreteFile: CoreDataFeatureRequirement {
        CoreDataFeatureRequirement(rawValue: 1 << 1)
    }

    static var persistentHistoryEnabled: CoreDataFeatureRequirement {
        CoreDataFeatureRequirement(rawValue: 1 << 2)
    }

    static var remoteChangeNotificationEnabled: CoreDataFeatureRequirement {
        CoreDataFeatureRequirement(rawValue: 1 << 3)
    }
}

extension CoreDataFeatureRequirement {
    struct Validator {
        typealias Validation = (NSPersistentStore) -> Bool

        private let block: Validation

        init(requirement: CoreDataFeatureRequirement) {
            var validation: Validation = { _ in true }

            func appendValidation(_ val: @escaping Validation) {
                let oldVal = validation
                validation = { oldVal($0) && val($0) }
            }

            if requirement.contains(.sqliteStore) {
                appendValidation { $0.type == NSSQLiteStoreType }
            }
            if requirement.contains(.concreteFile) {
                appendValidation { $0.url?.isDevNull == false }
            }
            if requirement.contains(.persistentHistoryEnabled) {
                appendValidation {
                    let key = "NSPersistentStoreRemoteChangeNotificationOptionKey"
                    let value = $0.options?[key] as? NSNumber
                    return value?.boolValue == true
                }
            }
            if requirement.contains(.persistentHistoryEnabled) {
                appendValidation {
                    let key = NSPersistentHistoryTrackingKey
                    let value = $0.options?[key] as? NSNumber
                    return value?.boolValue == true
                }
            }
            block = validation
        }

        func validate(store: NSPersistentStore) -> Bool {
            block(store)
        }
    }
}

extension NSPersistentStoreCoordinator {
    func checkRequirement(_ requirement: CoreDataFeatureRequirement) -> Bool {
        requirement.validate(coordinator: self)
    }
}
