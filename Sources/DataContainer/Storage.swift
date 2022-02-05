//
//  Storage.swift
//  
//
//  Created by ezou on 2021/10/14.
//

import CoreData
import Foundation

public class Storage: CustomStringConvertible, Hashable {
    public static func == (lhs: Storage, rhs: Storage) -> Bool {
        lhs.hashValue == rhs.hashValue
    }

    let storeType: String
    let url: URL?
    let configuration: String?
    let options: [StorageOption]

    public func hash(into hasher: inout Hasher) {
        hasher.combine(storeType)
        hasher.combine(url)
        hasher.combine(configuration)
        hasher.combine(options)
    }

    public var description: String {
        "\(String(reflecting: Self.self))(storeType:\"\(storeType)\",url:\"\(url == nil ? "nil" : "\(url!)")\")"
    }

    init(storeType: String, url: URL?, configuration: String?, options: [StorageOption]) {
        self.storeType = storeType
        self.url = url
        self.configuration = configuration
        self.options = options
    }

    func createDescription() -> NSPersistentStoreDescription {
        let description = NSPersistentStoreDescription()
        options.forEach { $0.apply(on: description) }
        description.type = storeType
        description.url = url
        description.configuration = configuration
        return description
    }
}

public class ConcreteStorage: Storage {
    public let storageUrl: URL

    internal init(storeType: String, url: URL, configuration: String?, options: [StorageOption]) {
        self.storageUrl = url
        super.init(storeType: storeType, url: url, configuration: configuration, options: options)
    }

    @available(*, unavailable)
    private override init(storeType: String, url: URL?, configuration: String?, options: [StorageOption]) {
        fatalError("this initializer in unavailable")
    }
    
    public func destroy() throws {
        if storageUrl == URL(fileURLWithPath: "/dev/null") {
            return
        }
        try FileManager.default.removeItem(at: storageUrl)
    }
}

public class SQLiteStorage: ConcreteStorage {
    public override func destroy() throws {
        try super.destroy()
        try? FileManager.default.removeItemIfExists(atPath: storageUrl.path + "-shm")
        try? FileManager.default.removeItemIfExists(atPath: storageUrl.path + "-wal")
    }
}

extension Storage {
    public static func binary(
        url: URL,
        configuration: String? = nil,
        options: PersistentStorageOption...) -> Storage
    {
        ConcreteStorage(storeType: NSBinaryStoreType, url: url, configuration: configuration, options: options)
    }

    public static func binary(
        name: String,
        configuration: String? = nil,
        options: PersistentStorageOption...) -> Storage
    {
        ConcreteStorage(
            storeType: NSBinaryStoreType,
            url: CurrentWorkingDirectory().appendingPathComponent(name),
            configuration: configuration,
            options: options)
    }

    public static func inMemory(
        configuration: String? = nil,
        options: StorageOption...) -> Storage
    {
        Storage(
            storeType: NSInMemoryStoreType,
            url: nil,
            configuration: configuration,
            options: options)
    }
}

extension Storage {
    public static func sqliteInMemory(
        configuration: String? = nil,
        options: SQLiteStorageOption...) -> Storage
    {
        sqlite(
            url: URL(fileURLWithPath: "/dev/null"),
            configuration: configuration,
            options: options)
    }

    public static func sqlite(
        url: URL,
        configuration: String? = nil,
        options: SQLiteStorageOption...) -> Storage
    {
        sqlite(
            url: url,
            configuration: configuration,
            options: options)
    }
    
    public static func sqlite(
        name: String,
        configuration: String? = nil,
        options: SQLiteStorageOption...) -> Storage
    {
        sqlite(
            url: CurrentWorkingDirectory()
                .appendingPathComponent(name)
                .appendingPathExtension("sqlite"),
            configuration: configuration,
            options: options)
    }
    
    private static func sqlite(
        url: URL,
        configuration: String? = nil,
        options: [SQLiteStorageOption]) -> Storage
    {
        SQLiteStorage(
            storeType: NSSQLiteStoreType,
            url: url,
            configuration: configuration,
            options: options)
    }
}

public class StorageOption: Hashable {
    public static func == (lhs: StorageOption, rhs: StorageOption) -> Bool {
        lhs.name == rhs.name
    }

    internal let block: (NSPersistentStoreDescription) -> Void
    internal let name: String

    public required init(_ name: String, _ block: @escaping (NSPersistentStoreDescription) -> Void) {
        self.block = block
        self.name = name
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }

    func apply(on description: NSPersistentStoreDescription) {
        block(description)
    }
}

extension StorageOption {
    public static var readOnly: Self {
        self.init("readOnly") { $0.isReadOnly = true }
    }

    public static func timeout(_ interval: TimeInterval) -> Self {
        self.init("timeout") { $0.timeout = interval }
    }

    public static func setOption(key: String, value: NSObject?) -> Self {
        self.init("setOption") { $0.setOption(value, forKey: key) }
    }
}

public class PersistentStorageOption: StorageOption {
    public static func persistentStoreForceDestory(_ flag: Bool) -> Self {
        self.init("persistentStoreForceDestory") { $0.setOption(
            flag as NSNumber,
            forKey: NSPersistentStoreForceDestroyOption)}
    }

#if !os(macOS)
    public static func persistentStoreFileProtection(type: FileProtectionType) -> Self {
        self.init("persistentStoreFileProtection") { $0.setOption(
            type as NSObject,
            forKey: NSPersistentStoreFileProtectionKey)}
    }
#endif
}

public class SQLiteStorageOption: PersistentStorageOption {
    public static func remoteChangeNotification(_ flag: Bool) -> Self {
        self.init("remoteChangeNotification") { $0.setOption(
            flag as NSNumber,
            forKey: "NSPersistentStoreRemoteChangeNotificationOptionKey") }
    }

    public static func persistentHistoryTracking(_ flag: Bool) -> Self {
        self.init("persistentHistoryTracking") { $0.setOption(
            flag as NSNumber,
            forKey: NSPersistentHistoryTrackingKey)}
    }

    public static func sqlitePragma(key: String, value: NSObject?) -> Self {
        self.init("sqlitePragma") { $0.setValue(value, forPragmaNamed: key) }
    }

    public static var sqliteAnalyze: Self {
        self.init("sqliteAnalyze") { $0.setOption(true as NSNumber, forKey: NSSQLiteAnalyzeOption) }
    }

    public static var sqliteManualVacuum: Self {
        self.init("sqliteManualVacuum") { $0.setOption(true as NSNumber, forKey: NSSQLiteManualVacuumOption) }
    }
}

#if !os(iOS) && !os(tvOS) && !os(watchOS)
public class XMLStorageOption: PersistentStorageOption {
    public static var validateXMLStore: Self {
        self.init("validateXMLStore") { $0.setOption(true as NSNumber, forKey: NSValidateXMLStoreOption) }
    }
}

extension Storage {
    public static func xml(
        url: URL,
        configuration: String? = nil,
        options: XMLStorageOption...) -> Storage
    {
        Storage(
            storeType: NSXMLStoreType,
            url: url,
            configuration: configuration,
            options: options)
    }
}
#endif
