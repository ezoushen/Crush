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
    init(rawObject: NSManagedObject)
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
    
    let rawObject: NSManagedObject
    
    init(rawObject: NSManagedObject) {
        self.rawObject = rawObject
    }
}

struct ReadWriteValueMapper: ReadWriteValueMapperProtocol, ValueProviderProtocol {
    let rawObject: NSManagedObject
    
    init(rawObject: NSManagedObject) {
        self.rawObject = rawObject
    }
}
