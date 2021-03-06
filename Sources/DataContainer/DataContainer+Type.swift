//
//  DataContainerType.swift
//  Crush
//
//  Created by ezou on 2019/9/26.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

public extension DataContainer {
    enum StoreType {
        case sql, binary, inMemory
        
        #if os(macOS)
        case xml
        #endif
        
        var raw: String {
            switch self {
            case .sql: return NSSQLiteStoreType
            case .binary: return NSBinaryStoreType
            case .inMemory: return NSInMemoryStoreType
            #if os(macOS)
            case .xml: return NSXMLStoreType
            #endif
            }
        }
        
        var migrator: DataMigrator.Type? {
            switch self {
            case .sql: return SQLMigrator.self
            default: return nil
            }
        }
        
        func createURL(_ documentDirectory: URL?, with name: String) -> URL? {
            switch self {
            case .sql: return documentDirectory?.appendingPathComponent("\(name).sqlite")
            case .binary: return documentDirectory?.appendingPathComponent(name)
            case .inMemory: return nil
            #if os(macOS)
            case .xml: return documentDirectory?.appendingPathComponent(name)
            #endif
            }
        }
    }
}
