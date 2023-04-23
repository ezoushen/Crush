//
//  CodableAttributeType.swift
//  
//
//  Created by ezou on 2021/10/18.
//

import CoreData
import Foundation

public protocol CodableAttributeType: AttributeType, PredicateEquatable, Codable, Hashable
where
    RuntimeValue == Self?,
    ManagedValue == Data?,
    PredicateValue == Data
{
    var data: Data { get set }

    static var encoder: JSONEncoder { get }
    static var decoder: JSONDecoder { get }
}

extension CodableAttributeType {
    @inlinable public static var defaultRuntimeValue: RuntimeValue { nil }
    @inlinable public static var defaultManagedValue: ManagedValue { nil }

    @inlinable
    public static func convert(managedValue: Data?) -> Self? {
        guard let value = managedValue else { return nil }
        return try! Self.decoder.decode(Self.self, from: value)
    }

    @inlinable
    public static func convert(runtimeValue: Self?) -> Data? {
        guard let value = runtimeValue else { return nil }
        return try! Self.encoder.encode(value)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(data)
    }

    @inlinable public static var encoder: JSONEncoder { JSONEncoder() }
    @inlinable public static var decoder: JSONDecoder { JSONDecoder() }
    @inlinable public static var nativeType: NSAttributeType { .binaryDataAttributeType }

    @inlinable public var predicateValue: NSObject { data as NSData }
    @inlinable public var data: Data {
        get { try! Self.encoder.encode(self) }
        mutating set { self = try! Self.decoder.decode(Self.self, from: newValue) }
    }
}
