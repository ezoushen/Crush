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
    
    private static var modelCache = NSCache<NSURL, NSManagedObjectModel>()

    static func load(name: String) -> NSManagedObjectModel? {
        let url = managedobjectModelDirectory.appendingPathComponent(name)
        return load(from: url)
    }

    static func load(from url: URL) -> NSManagedObjectModel? {
        if let cachedModel = modelCache.object(forKey: url as NSURL) {
            return cachedModel
        }
        guard FileManager.default.fileExists(atPath: url.path),
              let model = NSKeyedUnarchiver
                .unarchiveObject(withFile: url.path) as? NSManagedObjectModel
        else { return nil }
        modelCache.setObject(model, forKey: url as NSURL)
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
