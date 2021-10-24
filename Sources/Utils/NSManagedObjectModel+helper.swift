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
            .map { Hash.hash(string: $0) }
            .reduce(0) { Hash.unorderedHash(lhs: $0, rhs: $1) }
        let entityHash: UInt64 = entityVersionHashesByName
            .mapValues { $0.withUnsafeBytes { UInt64($0.load(as: UInt32.self))} }
            .sorted { $0.key < $1.key }
            .reduce(0) { Hash.orderedHash(lhs: $0, rhs: $1.value) }
        return String(Hash.orderedHash(lhs: nameHash, rhs: entityHash))
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
              let model = NSKeyedUnarchiver
                .unarchiveObject(withFile: url.path) as? NSManagedObjectModel
        else { return nil }
        return model
    }

    func save(name: String) {
        let url = NSManagedObjectModel
            .managedobjectModelDirectory
            .appendingPathComponent(name)
        return save(to: url)
    }

    func save(to url: URL) {
        let copy = copy() as! NSManagedObjectModel
        copy.entities.forEach { $0.managedObjectClassName = nil }
        let data = NSKeyedArchiver.archivedData(withRootObject: copy)
        try! data.write(to: url)
    }
}

// MARK: Compatibility

extension NSManagedObjectModel {
    func isCompactible(with anotherModel: NSManagedObjectModel) -> Bool {
        entityVersionHashesByName == anotherModel.entityVersionHashesByName
    }
}
