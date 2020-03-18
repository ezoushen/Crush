//
//  ValueMapper.swift
//  Crush
//
//  Created by 沈昱佐 on 2019/9/26.
//  Copyright © 2019 ezou. All rights reserved.
//

import CoreData

public protocol ValueProviderProtocol {
    var rawObject: NSManagedObject { get }
    init(rawObject: @escaping @autoclosure () -> NSManagedObject)
}

public protocol ReadOnlyValueMapperProtocol {
    func getValue<T>(property: PropertyProtocol) -> T
}

public protocol ReadWriteValueMapperProtocol: ReadOnlyValueMapperProtocol {
    func setValue(_ value: Any?, property: PropertyProtocol)
}

extension ReadOnlyValueMapperProtocol where Self: ValueProviderProtocol {
    @inline(__always)
    func getValue<T>(property: PropertyProtocol) -> T {
        let key = property.description.name
        rawObject.willAccessValue(forKey: key)
        defer {
            rawObject.didAccessValue(forKey: key)
        }
        let value = rawObject.primitiveValue(forKey: key)
        return (value is NSNull ? nil : value) as! T
    }
}

extension ReadWriteValueMapperProtocol where Self: ValueProviderProtocol {
    @inline(__always)
    func setValue(_ value: Any?, property: PropertyProtocol) {
        let key = property.description.name
        rawObject.willChangeValue(forKey: key)
        rawObject.setPrimitiveValue(value, forKey: key)
        rawObject.didChangeValue(forKey: key)
    }
}

struct ReadOnlyValueMapper: ReadOnlyValueMapperProtocol, ValueProviderProtocol {
    var rawObject: NSManagedObject {
        _getter()
    }
    
    private let _getter: () -> NSManagedObject
    
    init(rawObject: @escaping @autoclosure () -> NSManagedObject) {
        self._getter = rawObject
    }
}

struct ReadWriteValueMapper: ReadWriteValueMapperProtocol, ValueProviderProtocol {
    var rawObject: NSManagedObject {
        _getter()
    }
    
    private let _getter: () -> NSManagedObject
    
    init(rawObject: @escaping @autoclosure () -> NSManagedObject) {
        self._getter = rawObject
    }
}

enum PropertyProxyType {
    case readOnly, readWrite, dummy
}

extension PropertyProxyType {
//    var proxy: PropertyProxy 
}

protocol PropertyProxy { }

protocol ReadablePropertyProxy: PropertyProxy {
    func getValue<T>(property: PropertyProtocol) -> T
}

protocol WritablePropertyProxy: PropertyProxy {
    func setValue(_ value: Any?, property: PropertyProtocol)
}

extension ReadablePropertyProxy
where Self: ConcretePropertyProxy {
    @inline(__always)
    func getValue<T>(property: PropertyProtocol) -> T {
        let key = property.description.name
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
    func setValue(_ value: Any?, property: PropertyProtocol) {
        let key = property.description.name
        rawObject.willChangeValue(forKey: key)
        rawObject.setPrimitiveValue(value, forKey: key)
        rawObject.didChangeValue(forKey: key)
    }
}


class ConcretePropertyProxy: PropertyProxy {
    let rawObject: NSManagedObject
    
    init(rawObject: NSManagedObject) {
        self.rawObject = rawObject
    }
}

class ReadOnlyPropertyProxy: ConcretePropertyProxy, ReadablePropertyProxy { }

class ReadWritePropertyProxy: ConcretePropertyProxy, ReadablePropertyProxy, WritablePropertyProxy { }

//class DummyPropertyProxy<T>: PropertyProxy, ReadablePropertyProxy, WritablePropertyProxy {
//
//    func getValue<T>(property: PropertyProtocol) -> T {
//        <#code#>
//    }
//
//    func setValue(_ value: Any?, property: PropertyProtocol) {
//        <#code#>
//    }
//}
