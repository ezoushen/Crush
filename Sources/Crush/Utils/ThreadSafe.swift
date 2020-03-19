//
//  ThreadSafe.swift
//  Crush
//
//  Created by 沈昱佐 on 2020/3/15.
//

import Foundation

@propertyWrapper
public final class ThreadSafe<Value> {
    
    private var _value: Value
    private var _accessQueue: DispatchQueue!
    
    public var wrappedValue: Value {
        get { _accessQueue.sync { _value } }
        set { _accessQueue.async(flags: .barrier){ self._value = newValue }}
    }
    
    public init(wrappedValue: Value, on queue: DispatchQueue? = nil) {
        self._value = wrappedValue
        
        self._accessQueue = queue ?? DispatchQueue(label: "ThreadSafe Access Queue, \(String(Int(bitPattern: Unmanaged.passUnretained(self).toOpaque())))", attributes: .concurrent)
    }
}
