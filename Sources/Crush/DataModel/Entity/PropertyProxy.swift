//
//  PropertyProxy.swift
//  Crush
//
//  Created by 沈昱佐 on 2019/9/26.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

public protocol PropertyProxy {
    var rawObject: NSManagedObject { get }
    
    func getValue<T>(key: String) -> T
    func setValue(_ value: Any?, key: String)
}

extension PropertyProxy {
    var managedObject: ManagedObject? {
        rawObject as? ManagedObject
    }
    
    func setManagedObjectDelegate(_ delegate: ManagedObjectDelegate) {
        let proxy = ManagedObjectDelegateProxy(delegate: delegate, parent: managedObject?.delegate)
        managedObject?.delegate = proxy
        
        if managedObject?.isInserted == true {
            managedObject?.awakeFromInsert()
        }
    }
}

struct ReadWritePropertyProxy: PropertyProxy {
    private static var dummyObject: NSManagedObject = {
        let description = NSEntityDescription()
        description.name = "Dummy"
        return NSManagedObject(entity: description, insertInto: nil)
    }()
    
    static func dummy() -> Self {
        .init(rawObject: dummyObject)
    }
    
    let rawObject: NSManagedObject
    
    @inline(__always)
    func getValue<T>(key: String) -> T {
        rawObject.willAccessValue(forKey: key)
        defer {
            rawObject.didAccessValue(forKey: key)
        }
        return rawObject.primitiveValue(forKey: key) as! T
    }
    
    @inline(__always)
    func setValue(_ value: Any?, key: String) {
        let value = value.isNil ? nil : value
        rawObject.willChangeValue(forKey: key)
        defer {
            rawObject.didChangeValue(forKey: key)
        }
        rawObject.setPrimitiveValue(value, forKey: key)
    }
}
