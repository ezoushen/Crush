//
//  PropertyProxy.swift
//  Crush
//
//  Created by 沈昱佐 on 2019/9/26.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

public enum PropertyProxyType {
    case readOnly, readWrite, dummy
}

extension PropertyProxyType {
    func proxy(object: NSManagedObject) -> PropertyProxy {
        switch self {
        case .readOnly: return ReadOnlyPropertyProxy(rawObject: object)
        case .readWrite: return ReadWritePropertyProxy(rawObject: object)
        case .dummy: return ConcretePropertyProxy(rawObject: object, type: .dummy)
        }
    }
    
    func proxy(proxy: ConcretePropertyProxy) -> PropertyProxy {
        switch self {
        case .readOnly: return ReadOnlyPropertyProxy(rawObject: proxy.rawObject)
        case .readWrite: return ReadWritePropertyProxy(rawObject: proxy.rawObject)
        case .dummy: return ConcretePropertyProxy(rawObject: proxy.rawObject, type: .dummy)
        }
    }
}

public protocol PropertyProxy: AnyObject {
    var proxyType: PropertyProxyType { get }
    func getValue<T>(key: String) -> T
    func setValue(_ value: Any?, key: String)
}

protocol ReadablePropertyProxy: PropertyProxy { }

protocol WritablePropertyProxy: PropertyProxy { }

extension ReadablePropertyProxy
where Self: ConcretePropertyProxy {
    @inline(__always)
    fileprivate func get<T>(key: String) -> T {
        rawObject.willAccessValue(forKey: key)
        defer {
            rawObject.didAccessValue(forKey: key)
        }
        let value = rawObject.primitiveValue(forKey: key)
        return (value is NSNull ? nil : value) as! T
    }
}

extension WritablePropertyProxy
where Self: ConcretePropertyProxy {
    @inline(__always)
    func set(_ value: Any?, key: String) {
        rawObject.willChangeValue(forKey: key)
        rawObject.setPrimitiveValue(value, forKey: key)
        rawObject.didChangeValue(forKey: key)
    }
}

class ConcretePropertyProxy: PropertyProxy {
    
    let proxyType: PropertyProxyType
    
    func getValue<T>(key: String) -> T {
        fatalError()
    }
    
    func setValue(_ value: Any?, key: String) {
        fatalError()
    }
    
    let rawObject: NSManagedObject
    
    init(rawObject: NSManagedObject, type: PropertyProxyType) {
        self.rawObject = rawObject
        self.proxyType = type
    }
}

final class ReadOnlyPropertyProxy: ConcretePropertyProxy, ReadablePropertyProxy {
    init(rawObject: NSManagedObject) {
        super.init(rawObject: rawObject, type: .readOnly)
    }
    
    @inline(__always)
    override func getValue<T>(key: String) -> T {
        get(key: key)
    }
}

final class ReadWritePropertyProxy: ConcretePropertyProxy, ReadablePropertyProxy, WritablePropertyProxy {
    init(rawObject: NSManagedObject) {
        super.init(rawObject: rawObject, type: .readWrite)
    }
    
    @inline(__always)
    override func getValue<T>(key: String) -> T {
        get(key: key)
    }
    
    @inline(__always)
    override func setValue(_ value: Any?, key: String) {
        set(value, key: key)
    }
}

final class DummyPropertyProxy: ConcretePropertyProxy {
    static var dummyObject: NSManagedObject = {
        let description = NSEntityDescription()
        description.name = "Dummy"
        return NSManagedObject(entity: description, insertInto: nil)
    }()
    
    init() {
        super.init(rawObject: Self.dummyObject, type: .readWrite)
    }
}
