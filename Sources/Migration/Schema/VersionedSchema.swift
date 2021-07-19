//
//  VersionedSchema.swift
//  Crush
//
//  Created by 沈昱佐 on 2020/2/6.
//

import Foundation

public protocol DataSchema: SchemaProtocol {
    var entities: [Entity.Type] { get }
}

extension DataSchema {
    public var model: ObjectModel {
        DataModel(version: self, entities: entities)
    }
}

open class BaseSchema: DataSchema {
    public var previousVersion: SchemaProtocol? {
        fatalError()
    }
    
    open var entities: [Entity.Type] {
        fatalError()
    }
    
    required public init() { }
}

open class Schema<Version: DataSchema>: BaseSchema {
    public typealias PreviousVersion = Version
    
    public override var previousVersion: SchemaProtocol? {
        return PreviousVersion.init()
    }
        
    required public init() { }
}

open class SchemaOrigin: BaseSchema {
    public override var previousVersion: SchemaProtocol? {
        return nil
    }
        
    required public init() { }
}
