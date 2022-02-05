//
//  NSPersistentStoreCoordinator+helper.swift
//  
//
//  Created by ezou on 2021/10/15.
//

import CoreData
import Foundation

let CurrentModelVersionName = "CurrentModelVersionName"
let CurrentModelVersion = "CurrentModelVersion"

extension NSPersistentStoreCoordinator {
    static func lastActiveVersionName(in storage: Storage) -> String? {
        guard let url = storage.url else { return nil }
        let metadata = try? metadataForPersistentStore(
            ofType: storage.storeType, at: url, options: nil)
        return metadata?[CurrentModelVersionName] as? String
    }

    static func lastActiveVersion(in storage: Storage) -> String? {
        guard let url = storage.url else { return nil }
        let metadata = try? metadataForPersistentStore(
            ofType: storage.storeType, at: url, options: nil)
        return metadata?[CurrentModelVersion] as? String
    }

    static func updateLastActiveModel(_ dataModel: DataModel, in storage: Storage) {
        guard let url = storage.url else { return }
        try? setMetadata(
            [
                CurrentModelVersionName: dataModel.name,
                CurrentModelVersion: dataModel.managedObjectModel.version,
            ],
            forPersistentStoreOfType: storage.storeType,
            at: url,
            options: nil)
    }

    func lastActiveVersionName(at url: URL) -> String? {
        guard let store = persistentStore(for: url) else {
            return nil
        }
        return metadata(for: store)[CurrentModelVersionName] as? String
    }

    func lastActiveVersion(at url: URL) -> String? {
        guard let store = persistentStore(for: url) else {
            return nil
        }
        return metadata(for: store)[CurrentModelVersion] as? String
    }

    func updateLastActiveModel(
        name: String,
        managedObjectModel: NSManagedObjectModel,
        in storage: ConcreteStorage)
    {
        guard let store = persistentStore(for: storage.storageUrl) else {
            return
        }
        setMetadata(
            [
                CurrentModelVersionName: name,
                CurrentModelVersion: managedObjectModel.version,
            ],
            for: store)
    }

    func persistentStore(of storage: Storage) -> NSPersistentStore? {
        if let url = storage.url {
            return persistentStore(for: url)
        } else {
            return persistentStores.first(where: { $0.type == storage.storeType })
        }
    }
}
