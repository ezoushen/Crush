//
//  Schema.swift
//  Crush
//
//  Created by ezou on 2019/10/22.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

public protocol SchemaProtocol {
    init()
    static var model: DataModel { get }
    static var lastVersion: SchemaProtocol.Type? { get }
}

public extension Schema {
    static var model: DataModel {
        return DataModel(version: Self.self,
                         entities: allClasses[String(reflecting: Self.self)] ?? [])
    }
}

public protocol VersionedSchemaProtocol: SchemaProtocol {
    associatedtype LastVersion: SchemaProtocol
}

open class Schema<LastVersion: SchemaProtocol>: VersionedSchemaProtocol {
    public static var lastVersion: SchemaProtocol.Type? {
        return LastVersion.self
    }
    
    required public init() { }
}

public struct FirstVersion: SchemaProtocol {
    public static var model: DataModel {
        fatalError("Should not call model of FirstVersion directly")
    }
    
    public static var lastVersion: SchemaProtocol.Type? {
        return nil
    }
    
    public init() { }
}

fileprivate func findTypeNames(type: RuntimeObject.Type) -> [String] {
    let string = String(reflecting: type)
    let types = string.split(separator: ".")
    let packageName = String(types.first!)
    return types.dropFirst().reduce(["_Tt\(packageName.count)\(packageName)"]){
        let lastName = $0.last!
        
        var newName = lastName.replacingOccurrences(of: "_Tt", with: "_TtC") + "\($1.count)\($1)"
        if NSClassFromString(newName) == nil {
            newName = newName.replacingOccurrences(of: "_TtC", with: "_TtO")
        }
        
        return $0 + [newName]
    }
}

fileprivate func findEntityVersion(type: NeutralEntityObject.Type) -> SchemaProtocol.Type? {
    let types = findTypeNames(type: type)
    return types.reversed().compactMap{ NSClassFromString($0) as? SchemaProtocol.Type }.first
}

fileprivate var allClasses: [String: [NeutralEntityObject.Type]] = {
    var count: UInt32 = 0
    let classListPtr = objc_copyClassList(&count)
    defer {
        free(UnsafeMutableRawPointer(classListPtr))
    }
    let classListBuffer = UnsafeBufferPointer(start: classListPtr, count: Int(count))
    var entitiesWithNames: [String: [NeutralEntityObject.Type]] = [:]
    classListBuffer.forEach {
        if ($0 is RuntimeObject.Type && $0 != EntityObject.self && $0 != AbstractEntityObject.self && $0 != NeutralEntityObject.self), let type = $0 as? NeutralEntityObject.Type,
            let version = findEntityVersion(type: type) {
            entitiesWithNames[String(reflecting: version)] = (entitiesWithNames[String(reflecting: version)] ?? []) + [type]
        }
    }
    return entitiesWithNames
}()
