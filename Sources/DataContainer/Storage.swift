//
//  Storage.swift
//  
//
//  Created by ezou on 2021/10/14.
//

import CoreData
import Foundation

public class Storage: CustomStringConvertible {
    let storeType: String
    let url: URL?
    let configuration: String?
    let options: [Option]

    public var description: String {
        "\(String(reflecting: Self.self))(storeType:\"\(storeType)\",url:\"\(url == nil ? "nil" : "\(url!)")\")"
    }

    init(storeType: String, url: URL?, configuration: String?, options: [Option]) {
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

    internal init(storeType: String, url: URL, configuration: String?, options: [Storage.Option]) {
        self.storageUrl = url
        super.init(storeType: storeType, url: url, configuration: configuration, options: options)
    }

    @available(*, unavailable)
    private override init(storeType: String, url: URL?, configuration: String?, options: [Storage.Option]) {
        fatalError("this initializer in unavailable")
    }
    
    public func destroy() throws {
        try FileManager.default.removeItem(at: storageUrl)
    }
}

public class SQLiteStorage: ConcreteStorage {
    public override func destroy() throws {
        try super.destroy()
        try FileManager.default.removeItemIfExists(atPath: storageUrl.path + "-shm")
        try FileManager.default.removeItemIfExists(atPath: storageUrl.path + "-wal")
    }
}

extension Storage {
    public static func binary(url: URL, configuration: String? = nil, options: Option...) -> Storage {
        ConcreteStorage(storeType: NSBinaryStoreType, url: url, configuration: configuration, options: options)
    }

    public static func binary(name: String, configuration: String? = nil, options: Option...) -> Storage {
        ConcreteStorage(
            storeType: NSBinaryStoreType,
            url: CurrentWorkingDirectory().appendingPathComponent(name),
            configuration: configuration,
            options: options)
    }

    public static func inMemory(configuration: String? = nil, options: Option...) -> Storage {
        Storage(storeType: NSInMemoryStoreType, url: nil, configuration: configuration, options: options)
    }
}

extension Storage {
    public static func sqlite(url: URL, configuration: String? = nil, options: Option...) -> Storage {
        sqlite(
            url: url,
            configuration: configuration,
            options: options)
    }
    
    public static func sqlite(name: String, configuration: String? = nil, options: Option...) -> Storage {
        sqlite(
            url: CurrentWorkingDirectory()
                .appendingPathComponent(name)
                .appendingPathExtension("sqlite"),
            configuration: configuration,
            options: options)
    }
    
    private static func sqlite(url: URL, configuration: String? = nil, options: [Option]) -> Storage {
        SQLiteStorage(
            storeType: NSSQLiteStoreType,
            url: url,
            configuration: configuration,
            options: defaultSQLiteOptions() + options)
    }

    internal static func defaultSQLiteOptions() -> [Option] {
        [
            .persistentHistoryTracking(true),
            .remoteChangeNotification(true),
        ]
    }
}

#if !os(iOS)
extension Storage {
    public static func xml(url: URL, configuration: String? = nil, options: Option...) -> Storage {
        Storage(storeType: NSXMLStoreType, url: url, configuration: configuration, options: options)
    }
}
#endif

extension Storage {
    public enum Option {
        case readOnly
        case timeout(TimeInterval)
        case remoteChangeNotification(Bool)
        case persistentHistoryTracking(Bool)
        case persistentStoreForceDestroy(Bool)

        // Override advanced features
        case custom(key: String, value: NSObject)

        // Only effects on sqlite storage
        case sqlitePragma(key: String, value: NSObject)
        case sqliteAnalyze
        case sqliteManualVacuum

#if !os(iOS)
        // Only effects on xml storage
        case validateXMLStore
#endif

#if !os(macOS)
        case persistentStoreFileProtection(FileProtectionType)
#endif

        func apply(on description: NSPersistentStoreDescription) {
            switch self {
            case .readOnly:
                description.isReadOnly = true
            case .timeout(let timeInterval):
                description.timeout = timeInterval
            case .persistentHistoryTracking(let enabled):
                description.setOption(
                    NSNumber(booleanLiteral: enabled),
                    forKey: NSPersistentHistoryTrackingKey)
            case .persistentStoreForceDestroy(let enabled):
                description.setOption(
                    NSNumber(booleanLiteral: enabled),
                    forKey: NSPersistentStoreForceDestroyOption)
            case .remoteChangeNotification(let enabled):
                // Use string key for preventing os version check
                description.setOption(
                    NSNumber(booleanLiteral: enabled),
                    forKey: "NSPersistentStoreRemoteChangeNotificationOptionKey")
            case .sqlitePragma(let key, let value):
                description.setValue(value, forPragmaNamed: key)
            case .sqliteAnalyze:
                description.setOption(
                    NSNumber(booleanLiteral: true),
                    forKey: NSSQLiteAnalyzeOption)
            case .sqliteManualVacuum:
                description.setOption(
                    NSNumber(booleanLiteral: true),
                    forKey: NSSQLiteManualVacuumOption)
#if !os(iOS)
            case .validateXMLStore:
                description.setOption(
                    NSNumber(booleanLiteral: true),
                    forKey: NSValidateXMLStoreOption)
#endif
#if !os(macOS)
            case .persistentStoreFileProtection(let type):
                description.setOption(
                    type as NSObject,
                    forKey: NSPersistentStoreFileProtectionKey)
#endif
            case .custom(let key, let value):
                description.setOption(value, forKey: key)
            }
        }
    }
}
