//
//  VersionedSchema.swift
//  Crush
//
//  Created by 沈昱佐 on 2020/2/6.
//

import Foundation

public protocol DataSchemaProtocol: SchemaProtocol { }

open class _Schema: DataSchemaProtocol {
    public var lastVersion: SchemaProtocol? {
        fatalError()
    }
    
    open var model: ObjectModel {
        DataModel(version: self,
                  entities: allClasses[String(reflecting: Self.self)] ?? [])
    }
    
    required public init() { }
}

open class Schema<Version: SchemaProtocol>: _Schema {
    public typealias LastVersion = Version
    
    public override var lastVersion: SchemaProtocol? {
        return LastVersion.init()
    }
        
    required public init() { }
}

open class SchemaOrigin: _Schema {
    public override var lastVersion: SchemaProtocol? {
        return nil
    }
        
    required public init() { }
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

fileprivate func findEntityVersion(type: Entity.Type) -> SchemaProtocol? {
    let types = findTypeNames(type: type)
    return types.reversed().compactMap{ NSClassFromString($0) as? SchemaProtocol.Type }.first?.init()
}

fileprivate var allClasses: [String: [Entity.Type]] = {
    var count: UInt32 = 0
    let classListPtr = objc_copyClassList(&count)
    defer {
        free(UnsafeMutableRawPointer(classListPtr))
    }
    let classListBuffer = UnsafeBufferPointer(start: classListPtr, count: Int(count))
    var entitiesWithNames: [String: [Entity.Type]] = [:]
    classListBuffer.forEach {
        if ($0 is RuntimeObject.Type && $0 != EntityObject.self && $0 != AbstractEntityObject.self && $0 != NeutralEntityObject.self), let type = $0 as? NeutralEntityObject.Type,
            let version = findEntityVersion(type: type) {
            entitiesWithNames[String(reflecting: version)] = (entitiesWithNames[String(reflecting: version)] ?? []) + [type]
        }
    }
    return entitiesWithNames
}()
