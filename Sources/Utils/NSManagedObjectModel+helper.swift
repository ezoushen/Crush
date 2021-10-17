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
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return NSKeyedUnarchiver.unarchiveObject(withFile: url.path) as? NSManagedObjectModel
    }

    func save(name: String) {
        let url = NSManagedObjectModel
            .managedobjectModelDirectory
            .appendingPathComponent(name)
        return save(to: url)
    }

    func save(to url: URL) {
        let data = NSKeyedArchiver.archivedData(withRootObject: self)
        if FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(atPath: url.path)
        }
        FileManager.default.createFile(atPath: url.path, contents: data, attributes: nil)
    }
}

// MARK: Compatibility

extension NSManagedObjectModel {
    func isCompactible(with anotherModel: NSManagedObjectModel) -> Bool {
        entityVersionHashesByName == anotherModel.entityVersionHashesByName
    }
}
