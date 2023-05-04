//
//  ThreadLocal.swift
//  
//
//  Created by EZOU on 2023/4/28.
//

import Foundation

/// A property wrapper type that wraps a value that is local to a particular thread. When accessing the wrapped value, if the value is not set, the default value will be returned.
///
///     @ThreadLocal
///     static var foo: Int = 0
///     func test() {
///         DispatchQueue.global().async {
///             Self.withValue(1) {
///                 print(Self.foo) // 1
///             }
///         }
///         print(self.foo) // 0
///     }
///     test()
///
/// - Note: This is a thread version of `TaskLocal` in Swift Concurrency.
@propertyWrapper class ThreadLocal<Value> {
    var wrappedValue: Value {
        __pthread_specific_current_data_node(key)?
            .pointer.assumingMemoryBound(to: Value.self).pointee ?? defaultValue
    }

    let defaultValue: Value

    private lazy var keyPointer: UnsafeMutablePointer<pthread_key_t> = {
        let key = UnsafeMutablePointer<pthread_key_t>.allocate(capacity: 1)
        pthread_key_create(key, nil)
        return key
    }()
    private var key: pthread_key_t {
        keyPointer.pointee
    }

    @inlinable var projectedValue: ThreadLocal<Value> { self }
    
    deinit {
        keyPointer.deinitialize(count: 1)
        keyPointer.deallocate()
    }

    init(wrappedValue: Value) {
        self.defaultValue = wrappedValue
    }

    @available(*, unavailable, message: "property wrappers cannot be instance members")
    public static subscript(
        _enclosingInstance object: Never,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<Never, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<Never, ThreadLocal<Value>>
    ) -> Value {
        /// This line would never be executed, added to suppress compiler warning of "Will never be executed"
        func never() { }
    }

    @discardableResult
    @inlinable final public func withValue<R>(
        _ valueDuringOperation: Value,
        operation: () throws -> R,
        file: String = #fileID,
        line: UInt = #line) rethrows -> R
    {
        let pointer = withUnsafePointer(to: valueDuringOperation) { $0 }
        __pthread_specific_push_data_node(key, pointer)
        defer { __pthread_specific_pop_data_node(key) }
        return try operation()
    }
}

@usableFromInline
struct __pthread_specific_data_node {
    @usableFromInline let pointer: UnsafeRawPointer
    @usableFromInline let next: UnsafeMutablePointer<__pthread_specific_data_node>

    @usableFromInline init(
        _ pointer: UnsafeRawPointer,
        _ next: UnsafeMutablePointer<__pthread_specific_data_node>)
    {
        self.pointer = pointer
        self.next = next
    }
}

@inlinable
@inline(__always)
func __pthread_specific_current_data_node(_ key: pthread_key_t) -> __pthread_specific_data_node? {
    var node = __pthread_specific_get_data_node(key)
    while let next = node?.next.pointee, next.pointer.uintValue != 0 {
        node = next
    }
    return node
}

@inlinable
@inline(__always)
func __pthread_specific_push_data_node(_ key: pthread_key_t, _ object: UnsafeRawPointer) {
    if var node = __pthread_specific_get_data_node(key) {
        while node.next.pointee.pointer.uintValue != 0 {
            node = node.next.pointee
        }
        node.next.initialize(to: __pthread_specific_data_node(object, .allocate(capacity: 1)))
    } else {
        let value = UnsafeMutablePointer<__pthread_specific_data_node>.allocate(capacity: 1)
        value.initialize(to: __pthread_specific_data_node(object, .allocate(capacity: 1)))
        pthread_setspecific(key, value)
    }
}

@inlinable
@inline(__always)
func __pthread_specific_pop_data_node(_ key: pthread_key_t) {
    let head = __pthread_specific_get_data_head_pointer(key)
    if var pointer = head {
        while pointer.pointee.next.pointee.pointer.uintValue != 0 {
            pointer = pointer.pointee.next
        }
        if pointer == head {
            pthread_setspecific(key, nil)
        }
        pointer.pointee.next.deinitialize(count: 1)
        pointer.pointee.next.deallocate()
        pointer.deinitialize(count: 1)
        pointer.deallocate()
    }
}

@inlinable
@inline(__always)
func __pthread_specific_get_data_node(_ key: pthread_key_t) -> __pthread_specific_data_node? {
    __pthread_specific_get_data_head_pointer(key)?.pointee
}

@inlinable
@inline(__always)
func __pthread_specific_get_data_head_pointer(_ key: pthread_key_t) -> UnsafeMutablePointer<__pthread_specific_data_node>? {
    pthread_getspecific(key)?.assumingMemoryBound(to: __pthread_specific_data_node.self)
}

extension _Pointer {
    @inlinable
    @inline(__always)
    var uintValue: UInt { UInt(bitPattern: self) }
}
