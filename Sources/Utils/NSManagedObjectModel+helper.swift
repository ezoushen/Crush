//
//  NSManagedObjectModel+helper.swift
//  
//
//  Created by ezou on 2021/10/15.
//

import CoreData
import Foundation

// MARK: Model persistence

extension NSManagedObjectModel {
    var version: String {
        let nameHash: UInt64 = versionIdentifiers
            .compactMap { $0.base as? String }
            .map { PersistentHash.fromString($0) }
            .reduce(0) { PersistentHash.unordered($0, $1) }
        let entityHash: UInt64 = entityVersionHashesByName
            .mapValues { $0.withUnsafeBytes { UInt64($0.load(as: UInt32.self))} }
            .sorted { $0.key < $1.key }
            .reduce(0) { PersistentHash.ordered($0, $1.value) }
        return String(PersistentHash.ordered(nameHash, entityHash))
    }

    private static let directoryName: String = "CrushManagedObjectModels"
    private static var managedobjectModelDirectory: URL = {
        let fileManager = FileManager.default
        let directoryURL = CurrentWorkingDirectory()
            .appendingPathComponent(directoryName)
        if !fileManager.fileExists(atPath: directoryURL.path) {
            try! fileManager
                .createDirectory(at: directoryURL,
                                 withIntermediateDirectories: false,
                                 attributes: nil)
        }
        return directoryURL
    }()

    static func load(name: String) -> NSManagedObjectModel? {
        let url = managedobjectModelDirectory.appendingPathComponent(name)
        return load(from: url)
    }

    static func load(from url: URL) -> NSManagedObjectModel? {
        guard FileManager.default.fileExists(atPath: url.path),
              let model = try? NSKeyedUnarchiver
                .unarchivedObject(ofClass: NSManagedObjectModel.self, from: Data(contentsOf: url))
        else { return nil }
        return model
    }

    func save() throws {
        try save(name: version)
    }

    func save(name: String) throws {
        let url = NSManagedObjectModel
            .managedobjectModelDirectory
            .appendingPathComponent(name)
        return try save(to: url)
    }

    func save(to url: URL) throws {
        let copy = copy() as! NSManagedObjectModel
        copy.entities.forEach { $0.managedObjectClassName = nil }
        let data = try NSKeyedArchiver
            .archivedData(withRootObject: copy, requiringSecureCoding: false)
        try data.write(to: url, options: [.noFileProtection])
    }
}

// MARK: Compatibility

extension NSManagedObjectModel {
    func isCompactible(with anotherModel: NSManagedObjectModel) -> Bool {
        entityVersionHashesByName == anotherModel.entityVersionHashesByName &&
        entitiesIndexedByConfiguration() == anotherModel.entitiesIndexedByConfiguration()
    }

    private func entitiesIndexedByConfiguration() -> [String: Set<Data>] {
        configurations
            .filter { $0 != "PF_DEFAULT_CONFIGURATION_NAME" }
            .reduce(into: [String: Set<Data>]()) {
                guard let entities = entities(forConfigurationName: $1) else { return }
                $0[$1] = Set(entities.map(\.versionHash))
            }
    }
}
