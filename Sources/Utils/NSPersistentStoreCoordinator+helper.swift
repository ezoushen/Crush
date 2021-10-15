//
//  NSPersistentStoreCoordinator+helper.swift
//  
//
//  Created by ezou on 2021/10/15.
//

import CoreData
import Foundation

let CCurrentModelVersion = "CCurrentModelVersion"

extension NSPersistentStoreCoordinator {
    static func lastActiveVersionName(in storage: Storage) -> String? {
        guard let url = storage.url else { return nil }
        return lastActiveVersionName(storeType: storage.storeType, at: url)
    }

    static func lastActiveVersionName(
        storeType: String, at url: URL) -> String?
    {
        let metadata = try? metadataForPersistentStore(
            ofType: storeType, at: url, options: nil)
        return metadata?[CCurrentModelVersion] as? String
    }

    static func updateLastActiveVersionName(
        _ name: String, in storage: Storage)
    {
        guard let url = storage.url else { return }
        updateLastActiveVersionName(
            name, storeType: storage.storeType, at: url)
    }

    static func updateLastActiveVersionName(
        _ name: String, storeType: String, at url: URL)
    {
        try? setMetadata(
            [CCurrentModelVersion: name],
            forPersistentStoreOfType: storeType,
            at: url,
            options: nil)
    }

    func lastActiveVersionName(at url: URL) -> String? {
        guard let store = persistentStore(for: url) else {
            return nil
        }
        return lastActiveVersionName(in: store)
    }

    func updateLastActiveVersionName(_ name: String, at url: URL) {
        guard let store = persistentStore(for: url) else {
            return
        }
        updateLastActiveVersionName(name, in: store)
    }

    func lastActiveVersionName(in store: NSPersistentStore) -> String? {
        metadata(for: store)[CCurrentModelVersion] as? String
    }

    func updateLastActiveVersionName(_ name: String, in store: NSPersistentStore) {
        setMetadata([CCurrentModelVersion: name], for: store)
    }
}
