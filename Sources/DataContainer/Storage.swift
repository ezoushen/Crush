//
//  Storage.swift
//  
//
//  Created by ezou on 2021/10/14.
//

import CoreData
import Foundation

public class Storage {
    let storeType: String
    let url: URL?
    let configuration: String?
    let options: [Option]

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
        try FileManager.default.removeItem(atPath: storageUrl.path + "-shm")
        try FileManager.default.removeItem(atPath: storageUrl.path + "-wal")
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
            url: CurrentWorkingDirectory().appendingPathComponent(name),
            configuration: configuration,
            options: options)
    }
    
    private static func sqlite(url: URL, configuration: String? = nil, options: [Option]) -> Storage {
        SQLiteStorage(
            storeType: NSSQLiteStoreType,
            url: url,
            configuration: configuration,
            options: [
                .options([
                    NSPersistentHistoryTrackingKey: NSNumber(booleanLiteral: true),
                    // Use string key for preventing os version check
                    "NSPersistentStoreRemoteChangeNotificationOptionKey": NSNumber(booleanLiteral: true),
                ])
            ] + options)
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
    public enum Option: Equatable {
        case readOnly
        case timeout(TimeInterval)
        // Only effects on sqlite storage
        case sqlitePragmas([String: NSObject])
        // Override advanced features
        case options([String: NSObject])

        func apply(on description: NSPersistentStoreDescription) {
            switch self {
            case .readOnly:
                description.isReadOnly = true
            case .timeout(let timeInterval):
                description.timeout = timeInterval
            case .sqlitePragmas(let dictionary):
                for (key, value) in dictionary {
                    description.setValue(value, forPragmaNamed: key)
                }
            case .options(let dictionary):
                for (key, value) in dictionary {
                    description.setOption(value, forKey: key)
                }
            }
        }

        public static func == (lhs: Option, rhs: Option) -> Bool {
            return lhs.index == rhs.index
        }

        private var index: Int {
            switch self {
            case .readOnly:
                return 0
            case .timeout:
                return 1
            case .sqlitePragmas:
                return 2
            case .options:
                return 3
            }
        }
    }
}
